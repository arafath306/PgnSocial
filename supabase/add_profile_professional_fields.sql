-- Migration: Add Education, Blood Group, Occupation, and Website to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS education TEXT,
ADD COLUMN IF NOT EXISTS blood_group TEXT,
ADD COLUMN IF NOT EXISTS occupation TEXT,
ADD COLUMN IF NOT EXISTS website TEXT;
