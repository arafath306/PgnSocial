-- Migration: Update user_sessions table for Realtime and device metadata
-- Run this in Supabase SQL Editor:

-- 1. Ensure columns exist
ALTER TABLE public.user_sessions ADD COLUMN IF NOT EXISTS device_type TEXT DEFAULT 'phone';
ALTER TABLE public.user_sessions ADD COLUMN IF NOT EXISTS os_version TEXT;
ALTER TABLE public.user_sessions ADD COLUMN IF NOT EXISTS ip_address TEXT;

-- 2. Enable REPLICA IDENTITY FULL so Realtime DELETE events receive full record data
ALTER TABLE public.user_sessions REPLICA IDENTITY FULL;

-- 3. Add to supabase_realtime publication
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_sessions'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_sessions;
    END IF;
  END IF;
END $$;
