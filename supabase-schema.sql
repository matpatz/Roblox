-- Voltex API - Supabase Schema
-- Run this in the Supabase SQL Editor to create all required tables.

-- ============================================
-- EXISTING TABLES (keep as-is)
-- ============================================

-- Totals table (execution counter)
CREATE TABLE IF NOT EXISTS totals (
  id INT PRIMARY KEY DEFAULT 1,
  total_executions BIGINT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Identifiers table (execution log)
CREATE TABLE IF NOT EXISTS identifiers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  identifier TEXT NOT NULL,
  added_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-cleanup old identifiers (7 days)
SELECT cron.schedule(
  'cleanup-identifiers',
  '0 3 * * *',
  $$DELETE FROM identifiers WHERE added_at < NOW() - INTERVAL '7 days'$$
);

-- ============================================
-- NEW TABLES (for dynamic API)
-- ============================================

-- Scripts table
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

-- Games table
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

-- Misc table
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

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_identifiers_added_at ON identifiers(added_at);
CREATE INDEX IF NOT EXISTS idx_identifiers_identifier ON identifiers(identifier);
CREATE INDEX IF NOT EXISTS idx_scripts_created_at ON scripts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scripts_tags ON scripts USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_games_created_at ON games(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_games_tags ON games USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_misc_created_at ON misc(created_at DESC);

-- ============================================
-- SEED DATA (optional - migrate from static JSONs)
-- ============================================

-- Uncomment and run to seed scripts from the old scripts.json:
/*
INSERT INTO scripts (title, description, loadstring, raw_url, tags, button_text, updated) VALUES
  ('ASCII to Text', 'Turns simple text into ASCII using an API.', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/ascii/main.lua"))()', 'https://roblox-alpha-murex.vercel.app/src/scripts/ascii/main.lua', ARRAY['Open Source'], 'Copy Loadstring', 'last month'),
  ('ESP', 'ESP', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/esp/main.lua"))()', 'https://roblox-alpha-murex.vercel.app/src/scripts/esp/main.lua', ARRAY['Open Source', 'Key System'], 'Copy Loadstring', '6 months ago'),
  ('Powerball', 'Play Powerball in Roblox with a simple GUI, no money required.', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/powerball/main.lua"))()', 'https://roblox-alpha-murex.vercel.app/src/scripts/powerball/main.lua', ARRAY[]::TEXT[], 'Copy Loadstring', '4 months ago'),
  ('MoreUnc v4', 'Replicates Sunc functions, and more, for better script compatibility.', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/unc/main.lua"))()', 'https://roblox-alpha-murex.vercel.app/src/scripts/unc/main.lua', ARRAY['Open Source'], 'Copy Loadstring', '3 weeks ago');
*/

-- Uncomment and run to seed games from the old games.json:
/*
INSERT INTO games (title, description, loadstring, play_url, tags, button_text, play_button_text, updated) VALUES
  ('Answer or Die', 'Autofarm', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Answer-Or-Die/main.lua"))()', 'https://www.roblox.com/games/11966456877/Answer-or-Die', ARRAY['Functional', 'Undetected'], 'Get Script', 'Play on Roblox', '10 months ago'),
  ('Block Puzzle', 'Auto Farm', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Block-Puzzle/main.lua"))()', 'https://www.roblox.com/games/15564827526/Block-Puzzle', ARRAY['Functional', 'Undetected'], 'Get Script', 'Play on Roblox', '2 days ago'),
  ('Catch And Tame!', 'Get Best Animal', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Catch-And-Tame/main.lua"))()', 'https://www.roblox.com/games/96645548064314/Catch-And-Tame', ARRAY['Functional', 'Undetected'], 'Get Script', 'Play on Roblox', '4 months ago'),
  ('Catastrophia', 'Basic Aimbot and Esp', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Catastrophia/main.lua"))()', 'https://www.roblox.com/games/1087852616/CATASTROPHIA-Survive', ARRAY['Functional', 'Undetected', 'First Script for a game'], 'Get Script', 'Play on Roblox', '2 weeks ago'),
  ('Escape Tsunami For Brainrots!', 'Misc', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Escape-Tsunami-for-Brainrots/main.lua"))()', 'https://www.roblox.com/games/131623223084840/Escape-Tsunami-For-Brainrots', ARRAY['Functional', 'Undetected'], 'Get Script', 'Play on Roblox', '5 months ago'),
  ('Guess the Country Flag or Die!', 'Autofarm', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Guess-The-Flag-Or-Die/main.lua"))()', 'https://www.roblox.com/games/88817068170433/Guess-the-Country-Flag-or-Die', ARRAY['Functional', 'Undetected'], 'Get Script', 'Play on Roblox', '2 weeks ago'),
  ('Heavy Rust', 'Silent Aim', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Heavy-Metal/main.lua"))()', 'https://www.roblox.com/games/74669489500088/Heavy-Rust', ARRAY['Functional', 'Undetected'], 'Get Script', 'Play on Roblox', '5 months ago'),
  ('Idle Blocks', 'Auto Farm', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Idle-Blocks/main.lua"))()', 'https://www.roblox.com/games/101759436219635/Idle-Blocks', ARRAY['Functional', 'Undetected'], 'Get Script', 'Play on Roblox', '2 months ago'),
  ('Kick a Lucky Block', 'Best Kick', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Kick-a-Lucky-Block-for-Brainrots/main.lua"))()', 'https://www.roblox.com/games/89469502395769/Kick-a-Lucky-Block', ARRAY['Functional', 'Undetected'], 'Get Script', 'Play on Roblox', '2 months ago'),
  ('LUCKY BLOCKS Battlegrounds', 'Get Blocks Instantly', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Lucky-Blocks-Battleground/main.lua"))()', 'https://www.roblox.com/games/662417684/LUCKY-BLOCKS-Battlegrounds', ARRAY['Functional', 'Undetected', 'Open Source'], 'Get Script', 'Play on Roblox', '2 weeks ago'),
  ('Operation One', 'Basic Aimbot and Esp', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Operation-One/main.lua"))()', 'https://www.roblox.com/games/72920620366355/Operation-One', ARRAY['Functional', 'Undetected', 'Key System'], 'Get Script', 'Play on Roblox', 'last month'),
  ('Prospecting', 'Autofarm', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/prospecting/main.lua"))()', 'https://www.roblox.com/games/129827112113663/Prospecting', ARRAY['Functional', 'Undetected', 'Open Source'], 'Get Script', 'Play on Roblox', '2 hours ago'),
  ('T-Titans Battlegrounds', 'Autofarm, Esp, Aimbot, Triggerbot', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Teen-Titan-Battleground/main.lua"))()', 'https://www.roblox.com/games/3082002798/T-Titans-Battlegrounds', ARRAY['Functional', 'Undetected', 'Open Source'], 'Get Script', 'Play on Roblox', 'last month'),
  ('Titan Warfare', 'Kill Aura for Titans and People', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Titan-Warfare/main.lua"))()', 'https://www.roblox.com/games/6297822481/Titan-Warfare', ARRAY['Functional', 'Undetected', 'Open Source'], 'Get Script', 'Play on Roblox', '3 months ago'),
  ('Trident Survival', 'Basic Aimbot, Esp, Silent aim, amany of features.', 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Trident/main.lua"))()', 'https://www.roblox.com/games/13253735473/Trident-Survival', ARRAY['In Development'], 'Get Script', 'Play on Roblox', '2 weeks ago');
*/

-- Uncomment and run to seed misc from the old misc.json:
/*
INSERT INTO misc (title, description, snippet, raw_url, button_text) VALUES
  ('Rayfield UI Module', 'Standalone customized Rayfield UI module for embedding sleek modern interfaces into any Luau script.', 'local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/Roblox/main/libraries/Rayfield.luau"))()', 'https://raw.githubusercontent.com/matpatz/Roblox/main/libraries/Rayfield.luau', 'Copy Snippet'),
  ('Voltex API Bridge', 'API connector module handling authentication, analytics reporting, and version checking.', 'fetch("https://raw.githubusercontent.com/matpatz/Roblox/main/api/alpha.js")', 'https://raw.githubusercontent.com/matpatz/Roblox/main/api/alpha.js', 'Copy URL'),
  ('Discord Webhook Logger', 'Send execution logs, errors, and status reports directly to your Discord webhook.', 'loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/Roblox/main/init.luau"))()', 'https://raw.githubusercontent.com/matpatz/Roblox/main/init.luau', 'Copy Snippet');
*/

-- ============================================
-- ROW LEVEL SECURITY (optional)
-- ============================================

-- Enable RLS on new tables (API uses service role key, so RLS won't block server-side access)
ALTER TABLE scripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE misc ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Public read access" ON scripts FOR SELECT USING (true);
CREATE POLICY "Public read access" ON games FOR SELECT USING (true);
CREATE POLICY "Public read access" ON misc FOR SELECT USING (true);

-- Service role can do everything (used by API)
CREATE POLICY "Service role full access" ON scripts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON games FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON misc FOR ALL USING (true) WITH CHECK (true);
