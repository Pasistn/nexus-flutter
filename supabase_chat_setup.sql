-- ============================================================
-- Nexus Chat Feature – Supabase SQL Setup
-- Run this in the Supabase SQL Editor
-- ============================================================

-- 1. Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT,
  type            TEXT NOT NULL DEFAULT 'direct',  -- 'direct' | 'group'
  skill_id        UUID,
  created_by      UUID NOT NULL REFERENCES auth.users(id),
  last_message    TEXT,
  last_message_at TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Conversation members
CREATE TABLE IF NOT EXISTS conversation_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  user_name       TEXT,
  avatar_url      TEXT,
  joined_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

-- 3. Messages
CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES auth.users(id),
  sender_name     TEXT NOT NULL DEFAULT '',
  content         TEXT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Skill requests
CREATE TABLE IF NOT EXISTS skill_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  skill_id        UUID NOT NULL,
  skill_title     TEXT,
  requester_id    UUID NOT NULL REFERENCES auth.users(id),
  requester_name  TEXT,
  requester_avatar TEXT,
  skill_owner_id  UUID NOT NULL REFERENCES auth.users(id),
  status          TEXT NOT NULL DEFAULT 'pending',  -- 'pending' | 'accepted' | 'rejected'
  message         TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_requests ENABLE ROW LEVEL SECURITY;

-- conversations: only members can view
CREATE POLICY "Members can view their conversations"
  ON conversations FOR SELECT
  USING (
    id IN (
      SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create conversations"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Members can update last_message"
  ON conversations FOR UPDATE
  USING (
    id IN (
      SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
    )
  );

-- conversation_members: members of a conversation can see all members
CREATE POLICY "Members can view conversation members"
  ON conversation_members FOR SELECT
  USING (
    conversation_id IN (
      SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can add members"
  ON conversation_members FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- messages: members can read and write
CREATE POLICY "Members can view messages"
  ON messages FOR SELECT
  USING (
    conversation_id IN (
      SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Members can send messages"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND conversation_id IN (
      SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
    )
  );

-- skill_requests: requester and owner can view
CREATE POLICY "Parties can view skill requests"
  ON skill_requests FOR SELECT
  USING (requester_id = auth.uid() OR skill_owner_id = auth.uid());

CREATE POLICY "Authenticated users can create requests"
  ON skill_requests FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Skill owner can update request status"
  ON skill_requests FOR UPDATE
  USING (skill_owner_id = auth.uid());

-- profiles: allow authenticated users to search other profiles (for group creation)
-- NOTE: Only add this if you don't already have a public SELECT policy on profiles
CREATE POLICY "Authenticated users can view all profiles"
  ON profiles FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ============================================================
-- Realtime
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE skill_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
