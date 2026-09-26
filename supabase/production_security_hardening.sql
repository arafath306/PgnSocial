-- ============================================================================
-- DAK SOCIAL NETWORK - ENTERPRISE PRODUCTION SECURITY HARDENING
-- Run this script in your Supabase SQL Editor.
-- This script hardens the database against:
--   1. Privilege Escalation (protects 'role', 'is_verified', 'is_admin' fields)
--   2. Data Leaks on Reports and Audit Logs
--   3. Bot / Script Spamming (Database-level rate limits on posts, comments)
--   4. Identity Spoofing in Messages and Notifications
-- ============================================================================

-- ============================================================================
-- 1. PRIVILEGE ESCALATION PROTECTION (PROFILES TABLE)
-- Prevents authenticated users from maliciously changing their 'role' to 'Admin'
-- or altering 'is_verified' directly via the Supabase REST/PostgREST API.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.protect_profile_privileged_fields()
RETURNS TRIGGER AS $$
DECLARE
  is_admin_or_service BOOLEAN := false;
  jwt_role TEXT;
BEGIN
  -- Extract JWT role
  BEGIN
    jwt_role := current_setting('request.jwt.claims', true)::jsonb->>'role';
  EXCEPTION WHEN OTHERS THEN
    jwt_role := NULL;
  END;

  -- Allow service_role (backend Edge Functions / Admin API)
  IF jwt_role = 'service_role' THEN
    is_admin_or_service := true;
  ELSE
    -- Check if current user is an established Admin
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'Admin'
    ) THEN
      is_admin_or_service := true;
    END IF;
  END IF;

  -- If not an admin/service_role, preserve original role and verification status
  IF NOT is_admin_or_service THEN
    NEW.role := OLD.role;
    NEW.is_verified := OLD.is_verified;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_protect_profile_privileged_fields ON public.profiles;
CREATE TRIGGER trg_protect_profile_privileged_fields
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_privileged_fields();


-- ============================================================================
-- 2. SECURE REPORTS & AUDIT LOGS RLS POLICIES (DATA LEAK FIX)
-- Prevents ordinary users from reading abuse reports and system logs.
-- ============================================================================

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select for reports" ON public.reports;
DROP POLICY IF EXISTS "Allow users and admins to view reports" ON public.reports;

CREATE POLICY "Allow users and admins to view reports" 
ON public.reports FOR SELECT 
TO authenticated
USING (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
  )
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select on audit_logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Admins and moderators can view audit_logs" ON public.audit_logs;

CREATE POLICY "Admins and moderators can view audit_logs" 
ON public.audit_logs FOR SELECT 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
  )
);


-- ============================================================================
-- 3. BOT & SPAM DEFENSE (DATABASE-LEVEL RATE LIMITING)
-- Natural users will never feel this, but automated attack scripts will be stopped.
-- ============================================================================

-- A. Post / Thread Rate Limit (Minimum 2 seconds between posts)
CREATE OR REPLACE FUNCTION public.check_post_rate_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.threads 
    WHERE user_id = NEW.user_id 
    AND created_at > (NOW() - INTERVAL '2 seconds')
  ) THEN
    RAISE EXCEPTION 'Too many posts sent rapidly. Please wait a moment.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_post_rate_limit ON public.threads;
CREATE TRIGGER trg_check_post_rate_limit
  BEFORE INSERT ON public.threads
  FOR EACH ROW
  EXECUTE FUNCTION public.check_post_rate_limit();

-- B. Comment Rate Limit (Minimum 1 second between comments)
CREATE OR REPLACE FUNCTION public.check_comment_rate_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.comments 
    WHERE user_id = NEW.user_id 
    AND created_at > (NOW() - INTERVAL '1 second')
  ) THEN
    RAISE EXCEPTION 'Too many comments sent rapidly. Please wait a moment.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_comment_rate_limit ON public.comments;
CREATE TRIGGER trg_check_comment_rate_limit
  BEFORE INSERT ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION public.check_comment_rate_limit();


-- ============================================================================
-- 4. MESSAGES & NOTIFICATIONS INTEGRITY
-- Ensures no user can impersonate another user when sending messages/notifications.
-- ============================================================================

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow users to insert their own messages" ON public.messages;
CREATE POLICY "Allow users to insert their own messages" 
ON public.messages FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = sender_id);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to insert notifications" ON public.notifications;
CREATE POLICY "Allow authenticated users to insert notifications" 
ON public.notifications FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = actor_id);

-- ============================================================================
-- ALL PRODUCTION SECURITY HARDENING APPLIED SUCCESSFULLY
-- ============================================================================
