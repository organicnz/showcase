-- Migration: close RLS gaps left by the Disk IO fix
-- Date: 2026-10-02
--
-- 1. The pre-existing "Users can update own settings" policy has USING but no
--    WITH CHECK, so an authenticated user can reassign a row's user_id to
--    someone else (permissive policies are OR'ed, so the FOR ALL owner policy
--    added in 20261002000000 does NOT close this). Replace it with a
--    USING + WITH CHECK pair.
-- 2. Drop the duplicate photos SELECT policy added in 20261002000000 —
--    it is byte-identical (USING (active = true)) to the pre-existing
--    "Allow public read access for photos". Keep the original name.

DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'user_settings'
          AND policyname = 'Users can update own settings'
    ) THEN
        CREATE POLICY "Users can update own settings"
            ON public.user_settings FOR UPDATE
            TO authenticated
            USING ((SELECT auth.uid()) = user_id)
            WITH CHECK ((SELECT auth.uid()) = user_id);
    END IF;

    DROP POLICY IF EXISTS "photos_select_active_public" ON public.photos;
END $$;
