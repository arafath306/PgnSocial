-- ============================================================================
-- SQL TO RESOLVE SUPABASE SECURITY ADVISOR CRITICAL ISSUES
-- Execute this script in your Supabase SQL Editor to secure the database.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FIX: Enable Row Level Security (RLS) on verification_requests table
-- ----------------------------------------------------------------------------
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing conflicting policies
DROP POLICY IF EXISTS "Users can insert their own verification request" ON public.verification_requests;
DROP POLICY IF EXISTS "Users can select their own verification request" ON public.verification_requests;
DROP POLICY IF EXISTS "Admins can update verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Allow public insert on verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Allow public select on verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Allow public update on verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Admins can select all verification requests" ON public.verification_requests;

-- Create secure policies:
-- (A) Users can submit their own verification requests
CREATE POLICY "Users can insert their own verification request"
ON public.verification_requests FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- (B) Users can view only their own requests
CREATE POLICY "Users can select their own verification request"
ON public.verification_requests FOR SELECT
USING (auth.uid() = user_id);

-- (C) Admins/Moderators can view all verification requests
CREATE POLICY "Admins can select all verification requests"
ON public.verification_requests FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
  )
);

-- (D) Admins/Moderators can update all verification requests (approve/reject)
CREATE POLICY "Admins can update verification requests"
ON public.verification_requests FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
  )
);


-- ----------------------------------------------------------------------------
-- 2. FIX: Enable Row Level Security (RLS) on saved_comments table
-- ----------------------------------------------------------------------------
ALTER TABLE public.saved_comments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can select their own saved comments" ON public.saved_comments;
DROP POLICY IF EXISTS "Users can insert their own saved comments" ON public.saved_comments;
DROP POLICY IF EXISTS "Users can delete their own saved comments" ON public.saved_comments;

-- Create secure policies:
-- (A) Users can select only their own saved comments
CREATE POLICY "Users can select their own saved comments"
ON public.saved_comments FOR SELECT
USING (auth.uid() = user_id);

-- (B) Users can insert their own saved comments
CREATE POLICY "Users can insert their own saved comments"
ON public.saved_comments FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- (C) Users can delete their own saved comments
CREATE POLICY "Users can delete their own saved comments"
ON public.saved_comments FOR DELETE
USING (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 3. FIX: Redefine views with security_invoker = true
-- ----------------------------------------------------------------------------

-- Friends View (Ensures RLS policies of "follows" table are respected)
DROP VIEW IF EXISTS public.friends_view CASCADE;
CREATE OR REPLACE VIEW public.friends_view 
WITH (security_invoker = true) AS
SELECT f1.follower_id AS user_id, f1.following_id AS friend_id
FROM public.follows f1
JOIN public.follows f2 ON f1.follower_id = f2.following_id AND f1.following_id = f2.follower_id;

-- Frequent Chats View (Ensures RLS policies of "messages" table are respected)
DROP VIEW IF EXISTS public.frequent_chats_view CASCADE;
CREATE OR REPLACE VIEW public.frequent_chats_view 
WITH (security_invoker = true) AS
SELECT 
    sender_id AS user_id, 
    receiver_id AS contact_id, 
    COUNT(*) AS message_count
FROM public.messages
WHERE created_at > now() - INTERVAL '30 days'
GROUP BY sender_id, receiver_id;
