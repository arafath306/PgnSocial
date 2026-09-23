-- ============================================================================
-- DAK SOCIAL NETWORK & DAK-ADMIN-NEXT SECURITY HARDENING SCRIPT
-- Safe for dak-admin-next: Fully preserves service_role and Admin functionality.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PROTECT PRIVILEGED PROFILE FIELDS AGAINST REGULAR USER TAMPERING
-- Regular users cannot make themselves Admin, Verified, or remove bans/suspensions.
-- service_role (used by dak-admin-next) and Admins retain FULL UNRESTRICTED ACCESS.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profile_privileged_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- If invoked by service_role (dak-admin-next) or postgres superuser, allow everything
  IF (auth.jwt() ->> 'role') = 'service_role' OR current_user = 'postgres' THEN
    RETURN NEW;
  END IF;

  -- If caller is a confirmed Admin in profiles, allow everything
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'Admin') THEN
    RETURN NEW;
  END IF;

  -- For regular users, silently neutralize any unauthorized tampering of privileged fields:
  NEW.role := OLD.role;
  NEW.is_verified := OLD.is_verified;
  NEW.verified_plan_id := OLD.verified_plan_id;
  NEW.verified_expires_at := OLD.verified_expires_at;
  NEW.badge_type := OLD.badge_type;
  NEW.is_banned := OLD.is_banned;
  NEW.is_suspended := OLD.is_suspended;
  NEW.is_shadowbanned := OLD.is_shadowbanned;
  NEW.can_monetize := OLD.can_monetize;
  NEW.reach_multiplier := OLD.reach_multiplier;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_privileged_fields ON public.profiles;
CREATE TRIGGER trg_protect_profile_privileged_fields
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_privileged_fields();


-- ----------------------------------------------------------------------------
-- 2. PROTECT MESSAGE INTEGRITY (PREVENT RECEIVER TAMPERING)
-- Receivers can update read status or reactions, but CANNOT alter sender's content.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_message_integrity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- service_role (dak-admin-next) has full access
  IF (auth.jwt() ->> 'role') = 'service_role' OR current_user = 'postgres' THEN
    RETURN NEW;
  END IF;

  -- Sender updating message: cannot reassign sender, receiver, or creation timestamp
  IF auth.uid() = OLD.sender_id THEN
    NEW.sender_id := OLD.sender_id;
    NEW.receiver_id := OLD.receiver_id;
    NEW.created_at := OLD.created_at;
    RETURN NEW;
  END IF;

  -- Receiver updating message (read receipts / reactions): CANNOT change content or parties
  IF auth.uid() = OLD.receiver_id THEN
    NEW.sender_id := OLD.sender_id;
    NEW.receiver_id := OLD.receiver_id;
    NEW.content := OLD.content;
    NEW.created_at := OLD.created_at;
    RETURN NEW;
  END IF;

  -- Any other user is completely unauthorized
  RAISE EXCEPTION 'Unauthorized message update';
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_message_integrity ON public.messages;
CREATE TRIGGER trg_protect_message_integrity
  BEFORE UPDATE ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_message_integrity();


-- ----------------------------------------------------------------------------
-- 3. SECURE ADMIN BADGE GRANT & REVOKE FUNCTIONS
-- Prevents ordinary users or anonymous bots from calling grant_verified_badge RPC.
-- Only service_role (dak-admin-next) or confirmed Admins can call them.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.grant_verified_badge(
  target_user_id UUID,
  plan_id TEXT,
  expires_at TIMESTAMP WITH TIME ZONE
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF (auth.jwt() ->> 'role') != 'service_role' AND current_user != 'postgres' AND NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'Admin'
  ) THEN
    RAISE EXCEPTION 'Access Denied: Only administrators or system processes can grant badges.';
  END IF;

  UPDATE public.profiles
  SET
    is_verified = true,
    verified_plan_id = plan_id,
    verified_expires_at = expires_at
  WHERE id = target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found: %', target_user_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_verified_badge(
  target_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF (auth.jwt() ->> 'role') != 'service_role' AND current_user != 'postgres' AND NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'Admin'
  ) THEN
    RAISE EXCEPTION 'Access Denied: Only administrators or system processes can revoke badges.';
  END IF;

  UPDATE public.profiles
  SET
    is_verified = false,
    verified_plan_id = NULL,
    verified_expires_at = NULL
  WHERE id = target_user_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.grant_verified_badge(UUID, TEXT, TIMESTAMP WITH TIME ZONE) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.revoke_verified_badge(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.grant_verified_badge(UUID, TEXT, TIMESTAMP WITH TIME ZONE) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.revoke_verified_badge(UUID) TO authenticated, service_role;


-- ----------------------------------------------------------------------------
-- 4. SECURE DELETE_USER RPC
-- Prevent anon role from executing delete_user()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_user() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated, service_role;


-- ----------------------------------------------------------------------------
-- 5. RESOLVE MUTABLE SEARCH_PATH WARNINGS ON REMAINING FUNCTIONS
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'notify_fcm_edge_function') THEN
    ALTER FUNCTION public.notify_fcm_edge_function() SET search_path = public, auth;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_verification_request_update') THEN
    ALTER FUNCTION public.handle_verification_request_update() SET search_path = public, auth;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_personalized_feed' AND pronargs = 3) THEN
    ALTER FUNCTION public.get_personalized_feed(uuid, integer, integer) SET search_path = public, auth;
  END IF;
END $$;


-- ----------------------------------------------------------------------------
-- 6. SECURE STORAGE OBJECTS (PREVENT MALICIOUS DELETIONS / OVERWRITES)
-- Users can only delete or update their own uploaded assets.
-- service_role (dak-admin-next) and Admins retain full management rights.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Allow authenticated deletes from avatars" ON storage.objects;
CREATE POLICY "Allow authenticated deletes from avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND (
    (auth.jwt() ->> 'role') = 'service_role'
    OR (storage.foldername(name))[1] = auth.uid()::text
    OR (storage.foldername(name))[2] = auth.uid()::text
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'Admin')
  )
);

DROP POLICY IF EXISTS "Allow authenticated updates in avatars" ON storage.objects;
CREATE POLICY "Allow authenticated updates in avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND (
    (auth.jwt() ->> 'role') = 'service_role'
    OR (storage.foldername(name))[1] = auth.uid()::text
    OR (storage.foldername(name))[2] = auth.uid()::text
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'Admin')
  )
)
WITH CHECK (
  bucket_id = 'avatars' AND (
    (auth.jwt() ->> 'role') = 'service_role'
    OR (storage.foldername(name))[1] = auth.uid()::text
    OR (storage.foldername(name))[2] = auth.uid()::text
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'Admin')
  )
);
