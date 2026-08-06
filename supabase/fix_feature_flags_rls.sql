-- ============================================================
-- FIX: Feature Flags not working even when enabled from admin
-- Run this in Supabase SQL Editor
-- ============================================================

-- STEP 1: Check current data in system_settings
SELECT key, value FROM public.system_settings
WHERE key IN (
  'enable_voice_posts',
  'enable_anonymous_posting',
  'enable_tiered_badges',
  'enable_algorithmic_priority',
  'enable_monetization'
);

-- STEP 2: Ensure RLS is enabled but allows public read
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Drop all existing conflicting policies
DROP POLICY IF EXISTS "Allow public read on system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Allow authenticated users to modify system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Allow service_role to modify system_settings" ON public.system_settings;

-- Re-create: All users (including anon) can SELECT
CREATE POLICY "Allow public read on system_settings"
ON public.system_settings FOR SELECT
USING (true);

-- Service role can do everything (for admin panel writes)
CREATE POLICY "Allow service_role to modify system_settings"
ON public.system_settings FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- STEP 3: Ensure enable_anonymous_posting row exists
-- (If it's missing, the app will always treat it as disabled)
INSERT INTO public.system_settings (key, value)
VALUES ('enable_anonymous_posting', '{"access":"disabled","users":[]}')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.system_settings (key, value)
VALUES ('enable_voice_posts', '{"access":"disabled","users":[]}')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.system_settings (key, value)
VALUES ('enable_tiered_badges', '{"access":"disabled","users":[]}')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.system_settings (key, value)
VALUES ('enable_algorithmic_priority', '{"access":"disabled","users":[]}')
ON CONFLICT (key) DO NOTHING;

-- STEP 4: Verify data after fix
SELECT key, value FROM public.system_settings
WHERE key IN (
  'enable_voice_posts',
  'enable_anonymous_posting',
  'enable_tiered_badges',
  'enable_algorithmic_priority',
  'enable_monetization'
);
