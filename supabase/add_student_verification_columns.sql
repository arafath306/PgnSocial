-- Add student verification support columns to verification_requests table
ALTER TABLE public.verification_requests 
ADD COLUMN IF NOT EXISTS is_student BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS id_type TEXT DEFAULT 'nid';
