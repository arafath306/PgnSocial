-- ============================================================================
-- SQL TO CREATE BETA CENTER TABLES & POLICIES
-- Run this in your Supabase SQL Editor.
-- ============================================================================

-- 1. Beta Bugs Table
CREATE TABLE IF NOT EXISTS public.beta_bugs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('Low', 'Medium', 'High', 'Critical')),
    screen_name TEXT NOT NULL,
    screenshot_url TEXT,
    status TEXT NOT NULL DEFAULT 'Received' CHECK (status IN ('Received', 'Under Review', 'In Progress', 'Fixed', 'Closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Beta Bugs
ALTER TABLE public.beta_bugs ENABLE ROW LEVEL SECURITY;

-- 2. Beta Features Table
CREATE TABLE IF NOT EXISTS public.beta_features (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    expected_benefit TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Received' CHECK (status IN ('Received', 'Under Review', 'In Progress', 'Fixed', 'Closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Beta Features
ALTER TABLE public.beta_features ENABLE ROW LEVEL SECURITY;

-- 3. Beta Feedback Table
CREATE TABLE IF NOT EXISTS public.beta_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    liked TEXT NOT NULL,
    improved TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Beta Feedback
ALTER TABLE public.beta_feedback ENABLE ROW LEVEL SECURITY;

-- 4. Beta Known Issues Table
CREATE TABLE IF NOT EXISTS public.beta_known_issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Investigating' CHECK (status IN ('Investigating', 'Fixing', 'Resolved')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Beta Known Issues
ALTER TABLE public.beta_known_issues ENABLE ROW LEVEL SECURITY;

-- 5. Beta Changelogs Table
CREATE TABLE IF NOT EXISTS public.beta_changelogs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL UNIQUE,
    new_features TEXT NOT NULL,
    improvements TEXT NOT NULL,
    bug_fixes TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Beta Changelogs
ALTER TABLE public.beta_changelogs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES FOR SECURE CLIENT ACCESS
-- ============================================================================

-- Policies for public.beta_bugs
CREATE POLICY "Users can insert their own bugs" 
ON public.beta_bugs FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can select their own bugs" 
ON public.beta_bugs FOR SELECT 
USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
));

CREATE POLICY "Admins can update bugs" 
ON public.beta_bugs FOR UPDATE 
USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
));

-- Policies for public.beta_features
CREATE POLICY "Users can insert their own features" 
ON public.beta_features FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can select their own features" 
ON public.beta_features FOR SELECT 
USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
));

CREATE POLICY "Admins can update features" 
ON public.beta_features FOR UPDATE 
USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
));

-- Policies for public.beta_feedback
CREATE POLICY "Users can insert their own feedback" 
ON public.beta_feedback FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can select feedback" 
ON public.beta_feedback FOR SELECT 
USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
));

-- Policies for public.beta_known_issues
CREATE POLICY "Anyone can select known issues" 
ON public.beta_known_issues FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage known issues" 
ON public.beta_known_issues FOR ALL 
USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
));

-- Policies for public.beta_changelogs
CREATE POLICY "Anyone can select changelogs" 
ON public.beta_changelogs FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage changelogs" 
ON public.beta_changelogs FOR ALL 
USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
));
