-- Migration: Ensure Community Feature Requests can be posted and viewed by all users
-- Run this in Supabase SQL Editor:

-- 1. Ensure beta_features table exists
CREATE TABLE IF NOT EXISTS public.beta_features (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    expected_benefit TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Received',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Relax status check constraint so both 'Received' and 'Pending' are accepted
ALTER TABLE public.beta_features DROP CONSTRAINT IF EXISTS beta_features_status_check;
ALTER TABLE public.beta_features ADD CONSTRAINT beta_features_status_check 
    CHECK (status IN ('Received', 'Pending', 'Under Review', 'In Progress', 'Fixed', 'Closed'));

-- 3. Enable RLS
ALTER TABLE public.beta_features ENABLE ROW LEVEL SECURITY;

-- 4. Policies: Authenticated users can insert their own feature requests
DROP POLICY IF EXISTS "Users can insert their own features" ON public.beta_features;
CREATE POLICY "Users can insert their own features" 
ON public.beta_features FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 5. Policies: Anyone authenticated can view community feature requests to vote on them
DROP POLICY IF EXISTS "Users can select their own features" ON public.beta_features;
DROP POLICY IF EXISTS "Anyone can select beta_features" ON public.beta_features;
CREATE POLICY "Anyone can select beta_features" 
ON public.beta_features FOR SELECT 
TO authenticated
USING (true);

-- 6. Add to realtime
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'beta_features'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.beta_features;
    END IF;
  END IF;
END $$;
