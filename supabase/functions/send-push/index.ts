import { createClient } from "jsr:@supabase/supabase-js@2";

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!;
const PUSH_TRIGGER_SECRET = Deno.env.get("PUSH_TRIGGER_SECRET")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const MAX_RECIPIENTS = 100;
const MAX_TITLE = 100;
const MAX_BODY = 500;
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface PushPayload {
  user_ids: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

function base64url(input: Uint8Array | string): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : input;
  const str = btoa(String.fromCharCode(...bytes));
  return str.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  let diff = ab.length ^ bb.length;
  for (let i = 0; i < Math.max(ab.length, bb.length); i++) {
    diff |= (ab[i] ?? 0) ^ (bb[i] ?? 0);
  }
  return diff === 0;
}

function isStringRecord(v: unknown): v is Record<string, string> {
  return typeof v === "object" && v !== null && !Array.isArray(v) &&
    Object.values(v).every((x) => typeof x === "string");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binaryDer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const signingInput =
    `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claimSet))}`;
  const key = await importPrivateKey(sa.private_key);
  const sig = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64url(new Uint8Array(sig))}`;

  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!resp.ok) {
    throw new Error(`token exchange failed: ${resp.status} ${await resp.text()}`);
  }
  const json = await resp.json();
  return json.access_token as string;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("method not allowed", { status: 405 });
  }
  if (!PUSH_TRIGGER_SECRET) {
    console.error("PUSH_TRIGGER_SECRET is not configured");
    return new Response("server misconfigured", { status: 500 });
  }
  if (!safeEqual(req.headers.get("x-push-secret") ?? "", PUSH_TRIGGER_SECRET)) {
    return new Response("unauthorized", { status: 401 });
  }

  let payload: PushPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }

  const { user_ids, data } = payload;
  if (!Array.isArray(user_ids) || user_ids.length === 0) {
    return new Response(JSON.stringify({ skipped: true }), { status: 200 });
  }
  if (
    user_ids.length > MAX_RECIPIENTS ||
    !user_ids.every((id) => typeof id === "string" && UUID_RE.test(id)) ||
    typeof payload.title !== "string" ||
    typeof payload.body !== "string" ||
    (data !== undefined && data !== null && !isStringRecord(data))
  ) {
    return new Response("bad request", { status: 400 });
  }
  const title = payload.title.slice(0, MAX_TITLE);
  const body = payload.body.slice(0, MAX_BODY);

  const { data: tokens, error } = await supabase
    .from("device_tokens")
    .select("id, fcm_token")
    .in("user_id", user_ids);

  if (error) {
    console.error("device_tokens lookup failed", error);
    return new Response("db error", { status: 500 });
  }
  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
  }

  let accessToken: string;
  try {
    const serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON) as ServiceAccount;
    accessToken = await getGoogleAccessToken(serviceAccount);
  } catch (e) {
    console.error("google auth failed", e);
    return new Response("auth error", { status: 500 });
  }
  const results = await Promise.all(tokens.map(async (row) => {
    const message = {
      message: {
        token: row.fcm_token,
        notification: { title, body },
        ...(data ? { data } : {}),
      },
    };
    const resp = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(message),
      },
    );
    if (resp.ok) return { id: row.id, ok: true, stale: false };

    const errBody = await resp.json().catch(() => null);
    const status = errBody?.error?.status;
    console.error("fcm send failed", resp.status, status);
    const stale = status === "UNREGISTERED" || status === "SENDER_ID_MISMATCH";
    return { id: row.id, ok: false, stale };
  }));

  const sent = results.filter((r) => r.ok).length;
  const staleIds = results.filter((r) => r.stale).map((r) => r.id);

  if (staleIds.length > 0) {
    await supabase.from("device_tokens").delete().in("id", staleIds);
  }

  return new Response(JSON.stringify({ sent, cleaned: staleIds.length }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
