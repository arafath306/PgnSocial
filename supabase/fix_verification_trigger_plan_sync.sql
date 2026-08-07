-- ============================================================================
-- FIX VERIFICATION TRIGGER TO SYNC PLAN ID & MONETIZATION TO PROFILES TABLE
-- Run this in your Supabase SQL Editor.
-- ============================================================================

-- 1. Ensure columns exist on profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS verified_plan_id TEXT,
ADD COLUMN IF NOT EXISTS verified_tier TEXT,
ADD COLUMN IF NOT EXISTS can_monetize BOOLEAN DEFAULT FALSE;

-- 2. Update trigger function to sync plan_id & monetization when approved
CREATE OR REPLACE FUNCTION public.handle_verification_request_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'approved' THEN
        UPDATE public.profiles
        SET 
            is_verified = true, 
            verification_requested = false,
            can_monetize = true,
            verified_plan_id = NEW.plan_id,
            verified_tier = CASE WHEN NEW.plan_id LIKE '%premium%' THEN 'premium' ELSE 'basic' END
        WHERE id = NEW.user_id;
    ELSIF NEW.status = 'rejected' THEN
        UPDATE public.profiles
        SET 
            is_verified = false, 
            verification_requested = false,
            can_monetize = false,
            verified_plan_id = NULL,
            verified_tier = NULL
        WHERE id = NEW.user_id;
    ELSIF NEW.status = 'pending' THEN
        UPDATE public.profiles
        SET 
            is_verified = false, 
            verification_requested = true
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Sync existing approved requests to profiles table
UPDATE public.profiles p
SET 
    is_verified = true,
    can_monetize = true,
    verified_plan_id = vr.plan_id,
    verified_tier = CASE WHEN vr.plan_id LIKE '%premium%' THEN 'premium' ELSE 'basic' END
FROM public.verification_requests vr
WHERE p.id = vr.user_id 
  AND vr.status = 'approved';
