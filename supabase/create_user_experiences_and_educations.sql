-- Migration: Create user_experiences and user_educations tables with Realtime and RLS
-- Allows detailed LinkedIn-style work and education tracking

-- 1. USER EXPERIENCES
CREATE TABLE IF NOT EXISTS public.user_experiences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    company TEXT NOT NULL,
    employment_type TEXT DEFAULT 'Full-time', -- 'Full-time', 'Part-time', 'Self-employed', 'Freelance', 'Contract', 'Internship', 'Apprenticeship'
    location TEXT,
    location_type TEXT DEFAULT 'On-site', -- 'On-site', 'Hybrid', 'Remote'
    is_current BOOLEAN DEFAULT true NOT NULL,
    start_date TEXT NOT NULL, -- e.g. 'Jan 2023' or '2023-01'
    end_date TEXT, -- e.g. 'Present' or 'May 2024', NULL if is_current
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. USER EDUCATIONS
CREATE TABLE IF NOT EXISTS public.user_educations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    school TEXT NOT NULL,
    degree TEXT,
    field_of_study TEXT,
    start_date TEXT NOT NULL, -- e.g. '2019'
    end_date TEXT, -- e.g. '2023', NULL if is_current
    is_current BOOLEAN DEFAULT false NOT NULL,
    grade TEXT,
    activities TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexes for lightning fast queries
CREATE INDEX IF NOT EXISTS idx_user_experiences_user_id ON public.user_experiences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_educations_user_id ON public.user_educations(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_educations ENABLE ROW LEVEL SECURITY;

-- Drop any previous policies
DROP POLICY IF EXISTS "Public read user experiences" ON public.user_experiences;
DROP POLICY IF EXISTS "Users can insert their own experiences" ON public.user_experiences;
DROP POLICY IF EXISTS "Users can update their own experiences" ON public.user_experiences;
DROP POLICY IF EXISTS "Users can delete their own experiences" ON public.user_experiences;

DROP POLICY IF EXISTS "Public read user educations" ON public.user_educations;
DROP POLICY IF EXISTS "Users can insert their own educations" ON public.user_educations;
DROP POLICY IF EXISTS "Users can update their own educations" ON public.user_educations;
DROP POLICY IF EXISTS "Users can delete their own educations" ON public.user_educations;

-- Experiences Policies
CREATE POLICY "Public read user experiences" 
    ON public.user_experiences FOR SELECT 
    USING (true);

CREATE POLICY "Users can insert their own experiences" 
    ON public.user_experiences FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own experiences" 
    ON public.user_experiences FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own experiences" 
    ON public.user_experiences FOR DELETE 
    USING (auth.uid() = user_id);

-- Educations Policies
CREATE POLICY "Public read user educations" 
    ON public.user_educations FOR SELECT 
    USING (true);

CREATE POLICY "Users can insert their own educations" 
    ON public.user_educations FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own educations" 
    ON public.user_educations FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own educations" 
    ON public.user_educations FOR DELETE 
    USING (auth.uid() = user_id);

-- Enable Realtime for both tables so clients receive live updates
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'user_experiences'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_experiences;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'user_educations'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_educations;
    END IF;
END $$;
