-- Purge old rows from the `identifiers` table (site execution log).
-- ---------------------------------------------------------------------------
-- Run this in the SQL editor of the CONTENT project -- the one Vercel's
-- SUPABASE_URL points at. That is the project holding `identifiers`/`games`/
-- `scripts`/`totals`.
--
-- There are at least three Supabase projects in play, and they are easy to mix
-- up. Known refs:
--   foovjgdiodouiqipjiqc   - what .vscode/mcp.json connects to (most likely the
--                            content DB, i.e. the right one for this script)
--   dtfnhmehvzqcgwwdkmzh   - webhook Edge Function + key-system tables only
--                            (supabase/.temp/linked-project.json, webhook.lua)
--   <pollinations project> - chat_messages/conversations only, see
--                            supabase-pollinations-schema.sql
-- STEP 1a below tells you for certain whether the DB you are pointed at is the
-- right one, so do not trust the list above over its output.
--
-- Why the original statement could look like it "did nothing":
--   0. THE ACTUAL CAUSE, hit on 2026-09-22: Supabase caps rows. The SQL editor's
--      "Max rows" setting (and PostgREST's db-max-rows) defaults to 1000, so the
--      DELETE runs fine but the result grid only shows 1000 rows and the table
--      looks unchanged / the count looks wrong. Bump "Max rows" in the editor
--      (or use the RETURNING count in STEP 2) before concluding anything.
--      Same cap that silently truncated api/v1/stats history in 2026-08.
--   1. RLS is ENABLED on `identifiers` with a SELECT-only policy
--      (see supabase-schema.sql). A DELETE from any role that is not the table
--      owner and not service_role affects ZERO rows and raises NO error -- it
--      just silently succeeds. Use the SQL editor (postgres role) / CLI / MCP,
--      not the anon key. If RLS is the blocker, STEP 2 reports deleted_rows = 0
--      while STEP 1b showed will_delete > 0.
--   2. The dashboard reports "Success. 0 rows" for a DELETE whether it removed
--      0 rows or 500k, so the original gave you no feedback. The RETURNING count
--      in STEP 2 reports the real number, and it is not subject to the row cap.
--   3. Wrong project: if `identifiers` does not exist you get
--      relation "identifiers" does not exist -- that means stop, you are in the
--      wrong project, nothing else here matters.
--   4. `totals.total_executions` is a monotonic counter that nothing decrements,
--      and /api/v1/stats is KV-cached for 60s, so the site's headline number
--      will NOT drop just because old identifiers were purged. That is expected;
--      it does not mean the delete failed.
--
-- Idempotent -- safe to re-run. Not wrapped in a transaction, so a single
-- statement is fine to re-execute if it ever times out.
-- ---------------------------------------------------------------------------


-- STEP 1a -- which database / role am I on? Never errors, so it is safe to run
-- even in the wrong project.
SELECT
  current_database()                AS database,
  current_user                      AS role,
  to_regclass('public.identifiers') AS identifiers_table;

-- identifiers_table = NULL above means the table is not here -> WRONG PROJECT,
-- stop and switch to the content project. Nothing below will help.


-- STEP 1b -- what would be deleted?
-- `months => 0` is the knob: 0 = keep the current month only (the original
-- intent), 1 = keep this month + last month, 3 = keep a full quarter, etc.
WITH params AS (
  SELECT date_trunc('month', now()) - make_interval(months => 0) AS cutoff
)
SELECT
  (SELECT count(*) FROM identifiers)                                 AS total_rows,
  (SELECT count(*) FROM identifiers, params WHERE added_at < cutoff) AS will_delete,
  (SELECT min(added_at) FROM identifiers)                            AS oldest_row,
  (SELECT max(added_at) FROM identifiers)                            AS newest_row,
  (SELECT cutoff FROM params)                                        AS cutoff;


-- STEP 2 -- delete, and report how many rows actually went.
-- If will_delete > 0 (step 1) but deleted_rows = 0 here, RLS is blocking you:
-- re-run from the SQL editor / a postgres-or-service-role connection.
WITH params AS (
  SELECT date_trunc('month', now()) - make_interval(months => 0) AS cutoff
),
deleted AS (
  DELETE FROM identifiers
  USING params
  WHERE identifiers.added_at < params.cutoff
  RETURNING 1
)
SELECT count(*) AS deleted_rows FROM deleted;


-- STEP 3 -- confirm.
SELECT
  count(*)       AS remaining_rows,
  min(added_at)  AS oldest_row,
  max(added_at)  AS newest_row
FROM identifiers;

-- Optional: `VACUUM (ANALYZE) identifiers;` reclaims the disk the delete freed.
-- It refuses to run inside the SQL editor's transaction block, so only bother if
-- you have a direct psql connection -- autovacuum gets there on its own.
