-- Migration: Fix Disk IO budget exhaustion
-- Date: 2026-10-02
-- Reason: Supabase "running out of Disk IO Budget" alert on project smyfjmdjzfwdehynwfep.
--
-- Root causes found in this repo:
--   1. AWE.Runner persisted workflow state to `workflow_states` on EVERY app
--      launch (1 SELECT + ~4 UPSERTs per launch, plus a new row per launch
--      because the workflow id is random). Pure write IO / WAL bloat.
--      (Fixed in app code: persistence is now opt-in, default off.)
--   2. Catalogue load issued 2*N queries (per-scenario videos + photos).
--      (Fixed in app code: 2 batched queries total.)
--   3. `fetchWorkflowState` filters by workflow_name + orders by updated_at
--      with NO index -> sequential scan on a table that only grows.
--   4. `photos` has only a bare (scenario_id) index, missing the composite
--      (scenario_id, active, order_index) that per-scenario loads need.
--   5. `scenarios` / `videos` / `photos` are in the `supabase_realtime`
--      publication with REPLICA IDENTITY FULL (scenarios/videos), but the app
--      never subscribes to realtime channels (no channel/subscribe anywhere
--      in Sources/). FULL identity roughly doubles WAL bytes per
--      UPDATE/DELETE for zero benefit.
--
-- This migration:
--   a) adds the missing indexes,
--   b) removes the unused realtime publication + reverts to DEFAULT identity,
--   c) purges accumulated `workflow_states` junk rows,
--   d) modernises `workflow_states` RLS (auth.role() is deprecated),
--   e) hardens the public CDN view with security_invoker.

-- ============================================================
-- 1. Missing indexes (the actual Disk IO fix for reads)
-- ============================================================

-- workflow_states: supports fetchWorkflowState(name) -> WHERE workflow_name = $1 ORDER BY updated_at DESC LIMIT 1
CREATE INDEX IF NOT EXISTS idx_workflow_states_name_updated
    ON public.workflow_states (workflow_name, updated_at DESC);

-- photos: mirrors the videos indexes (per-scenario + active-only queries)
DO $$
BEGIN
    IF to_regclass('public.photos') IS NOT NULL THEN
        CREATE INDEX IF NOT EXISTS idx_photos_scenario_active_order
            ON public.photos (scenario_id, active, order_index);
        CREATE INDEX IF NOT EXISTS idx_photos_active
            ON public.photos (active);
    END IF;
END $$;

-- NOTE: no extra index for user_settings(user_id) — the live DB already has
-- PRIMARY KEY (user_id), which backs fetchUserSettings() lookups. A second
-- index would be a pure duplicate (extra write IO on every upsert).

-- ============================================================
-- 2. Drop unused realtime (WAL / IO fix for writes)
-- ============================================================
-- The app performs plain PostgREST reads; nothing subscribes to realtime.
-- Keeping tables in the publication forces WAL decoding + FULL row images.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'scenarios'
    ) THEN
        ALTER PUBLICATION supabase_realtime DROP TABLE public.scenarios;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'videos'
    ) THEN
        ALTER PUBLICATION supabase_realtime DROP TABLE public.videos;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'photos'
    ) THEN
        ALTER PUBLICATION supabase_realtime DROP TABLE public.photos;
    END IF;
END $$;

-- REPLICA IDENTITY FULL -> DEFAULT (FULL keeps whole old row in WAL).
ALTER TABLE public.scenarios REPLICA IDENTITY DEFAULT;
ALTER TABLE public.videos REPLICA IDENTITY DEFAULT;

-- ============================================================
-- 3. Purge workflow_states bloat from per-launch persistence
-- ============================================================
-- Each historical app launch inserted a row; keep only the 50 most recent.
-- (Wrapped so it never fails on an empty table.)
DO $$
BEGIN
    DELETE FROM public.workflow_states
    WHERE id NOT IN (
        SELECT id FROM public.workflow_states
        ORDER BY updated_at DESC NULLS LAST
        LIMIT 50
    );
END $$;

-- Refresh planner stats after the purge.
-- NOTE: plain ANALYZE (not VACUUM) because `supabase db push` applies each
-- migration file inside a transaction block, and VACUUM cannot run in one.
-- Autovacuum reclaims the dead tuples afterwards on its own.
ANALYZE public.workflow_states;

-- ============================================================
-- 4. Modernise workflow_states RLS (auth.role() is deprecated)
-- ============================================================

ALTER TABLE public.workflow_states ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.workflow_states;
DROP POLICY IF EXISTS "Enable select for anon users" ON public.workflow_states;

-- Anon: read-only (matches previous behaviour, explicit roles).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'workflow_states'
          AND policyname = 'workflow_states_select_anon'
    ) THEN
        CREATE POLICY "workflow_states_select_anon"
            ON public.workflow_states FOR SELECT
            TO anon
            USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'workflow_states'
          AND policyname = 'workflow_states_all_authenticated'
    ) THEN
        CREATE POLICY "workflow_states_all_authenticated"
            ON public.workflow_states FOR ALL
            TO authenticated
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- ============================================================
-- 5. Defensive RLS for Dashboard-created tables (if they exist)
-- ============================================================

DO $$
BEGIN
    IF to_regclass('public.photos') IS NOT NULL THEN
        -- Enable RLS if not already enabled
        BEGIN
            ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        IF NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE schemaname = 'public' AND tablename = 'photos'
              AND policyname = 'photos_select_active_public'
        ) THEN
            CREATE POLICY "photos_select_active_public"
                ON public.photos FOR SELECT
                TO anon, authenticated
                USING (active = true);
        END IF;
    END IF;

    IF to_regclass('public.user_settings') IS NOT NULL THEN
        BEGIN
            ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        IF NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE schemaname = 'public' AND tablename = 'user_settings'
              AND policyname = 'user_settings_owner_access'
        ) THEN
            CREATE POLICY "user_settings_owner_access"
                ON public.user_settings FOR ALL
                TO authenticated
                USING ((SELECT auth.uid()) = user_id)
                WITH CHECK ((SELECT auth.uid()) = user_id);
        END IF;
    END IF;
END $$;

-- ============================================================
-- 6. Harden public CDN view (views bypass RLS by default on PG15+;
--    security_invoker makes it respect the caller's RLS)
-- ============================================================

CREATE OR REPLACE VIEW public.videos_with_cdn_urls
WITH (security_invoker = true) AS
SELECT
  v.id,
  v.scenario_id,
  s.slug AS scenario_slug,
  v.title,
  v.storage_path,
  CASE
    WHEN v.storage_path LIKE 'http%' THEN v.storage_path
    ELSE 'https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/' || v.storage_path
  END AS cdn_url,
  v.duration_sec,
  v.order_index,
  v.active,
  v.created_at
FROM public.videos v
JOIN public.scenarios s ON v.scenario_id = s.id
ORDER BY s.order_index, v.order_index;
