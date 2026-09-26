-- Fix `totals.total_executions` / the "Total Executions" stat on /stats.
-- ---------------------------------------------------------------------------
-- Run this in the SQL editor of the CONTENT project -- the one Vercel's
-- SUPABASE_URL points at. Same project as supabase-identifiers-cleanup.sql.
--
-- THE BUG
--   /stats read 1512 while the 7-day history in the same payload summed to
--   ~21,900 and the last hour alone was 163 -- executions were being logged to
--   `identifiers` the whole time (201 + id from POST /api/v1/executions), only
--   the counter was dead.
--
--   Cause: d79f79e (2026-07-28) replaced the read-modify-write upsert with
--       await supabase.rpc('increment_executions');
--   and nothing ever looked at the result. `supabase.rpc()` resolves with
--   `{ error }` instead of throwing, so a failing call is a no-op that still
--   returns 201 to the client. The counter has been frozen ever since -- 1512 is
--   the Jul 25-28 total, from back when ~500 executions/day went through.
--
--   WHY IT FAILED (confirmed 2026-09-25 by 42703 in the Postgres logs): the live
--   `totals` table has no `updated_at` column. The function ends with
--   `DO UPDATE SET ... updated_at = NOW()`, so EVERY call died with
--   42703: column "updated_at" does not exist. The live DB predates that column
--   in the tracked schema (more drift: identifiers.id is bigint here, not the
--   UUID supabase-schema.sql declares), so this file repairs the schema instead
--   of tiptoeing around it.
--
-- THE FIX
--   Counting moves into the database: an AFTER INSERT trigger on `identifiers`
--   bumps `totals`. Nothing in the app counts anymore, so a caller cannot
--   forget to, and a stale deployment cannot double count (the old function is
--   dropped). Then backfill the executions that were logged but never counted.
--
-- ORDER MATTERS:
--   STEP 1c (add the missing column) MUST run before STEP 2 (the trigger). The
--   trigger's ON CONFLICT touches `updated_at`; without the column every single
--   POST /api/v1/executions 500s, because a trigger error aborts the INSERT it
--   fired on. Add the column first and that cannot happen.
--   STEP 3 (backfill) must also run BEFORE re-running
--   supabase-identifiers-cleanup.sql, because it counts the rows still present.
--
-- Idempotent -- safe to re-run. Single statements throughout, so a timeout is
-- safe to just re-execute.
-- ---------------------------------------------------------------------------


-- STEP 1 -- confirm you are on the right DB. `identifiers_table` NULL = wrong
-- project, stop. Deliberately does NOT select `updated_at`: if that column is
-- missing (it is) a query naming it just dies with 42703 and tells you nothing.
SELECT
  current_database()                AS database,u
  current_user                      AS role,
  to_regclass('public.identifiers') AS identifiers_table,
  (SELECT total_executions FROM totals WHERE id = 1) AS counter,
  (SELECT count(*) FROM identifiers)                 AS rows_kept_locally,
  (SELECT min(added_at) FROM identifiers)            AS oldest_identifier,
  (SELECT max(added_at) FROM identifiers)            AS newest_identifier;


-- STEP 1a -- what columns do these tables actually have? This is the query that
-- would have caught the whole thing: `totals` has no updated_at.
SELECT table_name, column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('totals', 'identifiers')
ORDER BY table_name, ordinal_position;


-- STEP 1b -- does the function the API was calling even exist? No rows back =
-- no such function in this project. The API never checked, so nobody found out.
SELECT p.oid::regprocedure AS function,
       p.prosecdef          AS security_definer,
       p.proconfig          AS config
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname = 'increment_executions'
  AND n.nspname = 'public';


-- STEP 1c -- put back the column the live table never had. This is the actual
-- root cause: the RPC was written for the tracked schema's totals (id,
-- total_executions, updated_at) but the live table only has the first two, so
-- `DO UPDATE SET ... updated_at = NOW()` raised 42703 on every call.
-- MUST run before STEP 2: the trigger below also sets updated_at, and a trigger
-- error aborts the INSERT that fired it -- i.e. it would 500 every
-- POST /api/v1/executions instead of just logging the failure.
-- Rewriting a 1-row table is instant, so the volatile DEFAULT is irrelevant.
ALTER TABLE totals ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();


-- STEP 2 -- the counter, as a trigger on the table being logged.
-- This is the actual fix: every insert into identifiers bumps totals, in the
-- same transaction, regardless of what the deployed API code does or which
-- schema PostgREST has cached. A trigger cannot be forgotten by a caller the way
-- an unchecked rpc() call can.
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


-- STEP 2b -- drop the old RPC. It is dead weight now, and leaving it in place
-- means any deployment still calling it double counts against the trigger.
-- (Deploy api/v1/executions.js with the rpc call removed _first_ if you would
-- rather never see the "function does not exist" error in the log.)
DROP FUNCTION IF EXISTS increment_executions();


-- STEP 3 -- backfill what was logged but never counted.
-- Counts identifiers newer than the freeze. The cutoff is the commit that
-- switched the API to the broken RPC (d79f79e, 2026-07-28); everything at or
-- before it is already inside the 1512 that IS counted, everything after it was
-- logged and never counted.
-- If STEP 1's oldest_identifier is already after the cutoff, this adds the
-- whole table (count(*) == missing) and the result is exact. If rows older than
-- the cutoff are still around, only the newer ones are added -- the purge keeps
-- the current month, so in practice there are none.
-- Only exact for rows still in the table: if the purge already deleted rows
-- from the frozen window, the number is a floor, not the truth. Run this BEFORE
-- the next purge. If you know the real figure, use STEP 3b instead.
UPDATE totals t
SET total_executions = t.total_executions + d.missing,
    updated_at       = NOW()
FROM (
  SELECT count(*) AS missing
  FROM identifiers
  WHERE added_at > TIMESTAMPTZ '2026-07-28 00:00:00+00'
) d
WHERE t.id = 1
RETURNING t.total_executions AS total_after_backfill, d.missing AS added;


-- STEP 3b -- only if you want to set the number by hand instead (e.g. you know
-- executions predating the purge, or step 3 added something silly). Put the
-- real figure in place of 0.
-- UPDATE totals SET total_executions = 0, updated_at = NOW() WHERE id = 1
-- RETURNING total_executions;


-- STEP 4 -- verify the trigger works, without leaving a row behind.
-- The rollback also rolls back the increment, so the counter is unchanged at
-- the end. An error about a NOT NULL column just means this table has extra
-- columns the insert above does not know about -- check STEP 1/2 output instead.
BEGIN;
  INSERT INTO identifiers (identifier) VALUES ('counter-trigger-test');
  SELECT total_executions AS counter_inside_transaction FROM totals WHERE id = 1;
ROLLBACK;

-- STEP 4b -- after a few real executions, the counter should move by exactly
-- one per logged execution and stale_for should collapse to seconds.
-- /api/v1/stats is KV-cached for 60s, so give it a minute before believing the
-- site.
SELECT total_executions, now() - updated_at AS stale_for
FROM totals WHERE id = 1;
