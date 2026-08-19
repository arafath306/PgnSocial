-- ============================================================================
-- DAK SOCIAL NETWORK - HIGH PERFORMANCE INDEXING FOR 10M+ USERS
-- Execute this script in your Supabase project's SQL Editor (https://supabase.com).
--
-- These indexes optimize the query performance of both the Mobile App and the
-- Admin Panel, ensuring sub-second response times on massive tables.
-- ============================================================================

-- 1. PROFILES TABLE INDEXES (Admin Panel & Search)
-- Optimizes searching by username
CREATE INDEX IF NOT EXISTS idx_profiles_username 
ON public.profiles(username);

-- Optimizes sorting by follower counts (Admin Monetization Dashboard)
CREATE INDEX IF NOT EXISTS idx_profiles_followers_count_desc 
ON public.profiles(followers_count DESC);

-- Optimizes sorting users by registration date (Admin Dashboard Users list)
CREATE INDEX IF NOT EXISTS idx_profiles_created_at_desc 
ON public.profiles(created_at DESC);

-- Optimizes filtering active creators (Users who can monetize)
CREATE INDEX IF NOT EXISTS idx_profiles_can_monetize 
ON public.profiles(can_monetize) 
WHERE can_monetize = true;

-- Optimizes filtering banned or suspended accounts
CREATE INDEX IF NOT EXISTS idx_profiles_is_banned_suspended 
ON public.profiles(is_banned, is_suspended);


-- 2. VERIFICATION REQUESTS INDEXES (Admin Verification flow)
-- Optimizes filtering verification requests by status (pending, approved, rejected)
CREATE INDEX IF NOT EXISTS idx_verification_requests_status 
ON public.verification_requests(status);

-- Optimizes fetching a user's verification request history
CREATE INDEX IF NOT EXISTS idx_verification_requests_user_id 
ON public.verification_requests(user_id);


-- 3. CREATOR SUBSCRIPTIONS INDEXES (Admin Monetization panel)
-- Optimizes checking user active subscription status
CREATE INDEX IF NOT EXISTS idx_creator_subscriptions_status 
ON public.creator_subscriptions(status);

-- Optimizes loading a creator's subscriber list
CREATE INDEX IF NOT EXISTS idx_creator_subscriptions_creator_id 
ON public.creator_subscriptions(creator_id);

-- Optimizes loading a user's active creator subscriptions
CREATE INDEX IF NOT EXISTS idx_creator_subscriptions_subscriber_id 
ON public.creator_subscriptions(subscriber_id);


-- 4. THREADS (POSTS) TABLE INDEXES (High Performance Feed & Profile)
-- Optimizes loading a user's own profile posts
CREATE INDEX IF NOT EXISTS idx_threads_user_id 
ON public.threads(user_id);

-- Optimizes loading and sorting feeds chronologically (Feed Screen)
CREATE INDEX IF NOT EXISTS idx_threads_created_at_desc 
ON public.threads(created_at DESC);

-- Optimizes community-specific posts feed loading
CREATE INDEX IF NOT EXISTS idx_threads_community_id 
ON public.threads(community_id) 
WHERE community_id IS NOT NULL;
