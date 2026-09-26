-- Add audio_url column to comments table for voice comments
ALTER TABLE public.comments
ADD COLUMN IF NOT EXISTS audio_url TEXT;
