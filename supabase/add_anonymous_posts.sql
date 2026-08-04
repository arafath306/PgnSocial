-- Add is_anonymous column to threads table
ALTER TABLE public.threads 
ADD COLUMN IF NOT EXISTS is_anonymous BOOLEAN DEFAULT false;

-- Comment: When is_anonymous = true, the client should mask
-- the author's profile (show 'Anonymous User' instead of real name/avatar).
-- The actual user_id is still stored for admin/moderation purposes.
