-- ============================================================================
-- MIGRATION: ADD PINNED MESSAGES SUPPORT TO MESSAGES TABLE
-- Run this in the Supabase SQL Editor.
-- ============================================================================

-- 1. Add is_pinned and pinned_at columns to public.messages
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS pinned_at TIMESTAMP WITH TIME ZONE;

-- 2. Create partial index for ultra-fast pinned message queries
CREATE INDEX IF NOT EXISTS idx_messages_is_pinned ON public.messages(is_pinned) WHERE is_pinned = TRUE;
