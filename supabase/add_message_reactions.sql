-- ============================================================================
-- MIGRATION: ADD EMOJI REACTIONS TO MESSAGES TABLE
-- Run this in the Supabase SQL Editor.
-- ============================================================================

-- 1. Add reactions column to public.messages
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb;

-- 2. Create GIN index for fast reaction lookups if queried
CREATE INDEX IF NOT EXISTS idx_messages_reactions ON public.messages USING GIN (reactions);
