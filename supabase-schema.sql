-- nobody knows SQL

-- Totals
CREATE TABLE IF NOT EXISTS totals (
  id INT PRIMARY KEY DEFAULT 1,
  total_executions BIGINT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Identifiers
CREATE TABLE IF NOT EXISTS identifiers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  identifier TEXT NOT NULL,
  added_at TIMESTAMPTZ DEFAULT NOW()
);

-- Scripts
CREATE TABLE IF NOT EXISTS scripts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  loadstring TEXT NOT NULL,
  raw_url TEXT,
  tags TEXT[] DEFAULT '{}',
  button_text TEXT DEFAULT 'Copy Loadstring',
  updated TEXT DEFAULT 'just now',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Games
CREATE TABLE IF NOT EXISTS games (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  loadstring TEXT NOT NULL,
  play_url TEXT,
  tags TEXT[] DEFAULT '{}',
  button_text TEXT DEFAULT 'Get Script',
  play_button_text TEXT DEFAULT 'Play on Roblox',
  updated TEXT DEFAULT 'just now',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Misc
CREATE TABLE IF NOT EXISTS misc (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  snippet TEXT,
  raw_url TEXT,
  button_text TEXT DEFAULT 'Copy Snippet',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Key System
CREATE TABLE IF NOT EXISTS keys (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT false,
  created_ip TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Atomic counter, maintained by the table instead of by the API.
-- Counting from the app is what broke the site stat: the RPC call was
-- fire-and-forget, so a missing/mis-scoped function silently froze
-- totals.total_executions while identifiers kept growing. A trigger cannot be
-- forgotten by a caller, and does not depend on PostgREST finding the function.
CREATE OR REPLACE FUNCTION bump_total_executions()
RETURNS trigger AS $$
BEGIN
  INSERT INTO totals (id, total_executions) VALUES (1, 1)
  ON CONFLICT (id) DO UPDATE SET
    total_executions = totals.total_executions + 1,
    updated_at = NOW();
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS identifiers_bump_totals ON identifiers;
CREATE TRIGGER identifiers_bump_totals
  AFTER INSERT ON identifiers
  FOR EACH ROW EXECUTE FUNCTION bump_total_executions();

-- Superseded by the trigger above. Dropped rather than kept around: as long as
-- it exists, any stale deployment still calling it would double count.
DROP FUNCTION IF EXISTS increment_executions();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_identifiers_added_at ON identifiers(added_at);
CREATE INDEX IF NOT EXISTS idx_identifiers_identifier ON identifiers(identifier);
CREATE INDEX IF NOT EXISTS idx_scripts_created_at ON scripts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scripts_tags ON scripts USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_games_created_at ON games(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_games_tags ON games USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_misc_created_at ON misc(created_at DESC);

-- RLS
ALTER TABLE totals ENABLE ROW LEVEL SECURITY;
ALTER TABLE identifiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE scripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE misc ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Public read" ON totals FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Public read" ON identifiers FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Public read" ON scripts FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Public read" ON games FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Public read" ON misc FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DROP POLICY IF EXISTS "Insert" ON scripts;
DROP POLICY IF EXISTS "Insert" ON games;
DROP POLICY IF EXISTS "Insert" ON misc;

-- Inserts are handled server-side via service role key (bypasses RLS)
--
-- SELECT-only policies are deliberate: every write goes through the service
-- role. Consequence worth remembering: a DELETE issued with the anon /
-- authenticated key affects ZERO rows and raises NO error, so it looks like it
-- worked. Purge `identifiers` with the SQL editor / service role instead --
-- see supabase-identifiers-cleanup.sql.
