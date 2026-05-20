-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Anyone can read categories
CREATE POLICY "categories_read" ON categories
  FOR SELECT USING (true);

-- Insert initial categories
INSERT INTO categories (name, icon) VALUES
  ('Garten',                '🌿'),
  ('IT & Technologie',      '💻'),
  ('Haushalt',              '🏠'),
  ('Handwerk',              '🔨'),
  ('Kochen & Backen',       '🍳'),
  ('Nachhilfe & Bildung',   '📚'),
  ('Fahrzeuge & Transport', '🚗'),
  ('Fitness & Gesundheit',  '💪')
ON CONFLICT DO NOTHING;

-- Add category_id column to skills (nullable so existing skills still work)
ALTER TABLE skills ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES categories(id);
