-- ============================================================================
-- DAK SOCIAL NETWORK DATABASE SCHEMA
-- Execute this script in your Supabase SQL Editor to set up all tables, 
-- triggers for automatic counters, and automated notifications.
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY, -- Maps to auth user ID (Firebase/Supabase auth)
    username TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    cover_url TEXT,
    followers_count INTEGER DEFAULT 0 NOT NULL,
    following_count INTEGER DEFAULT 0 NOT NULL,
    phone TEXT,
    country TEXT,
    division TEXT,
    city TEXT,
    village TEXT,
    zip TEXT,
    gender TEXT,
    birthdate TEXT,
    is_private BOOLEAN DEFAULT false NOT NULL,
    allow_mentions TEXT DEFAULT 'everyone' NOT NULL,
    filter_adult BOOLEAN DEFAULT true NOT NULL,
    autoplay_videos BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. THREADS (POSTS) TABLE
CREATE TABLE IF NOT EXISTS public.threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    image_urls TEXT[], -- Array of image URLs
    video_url TEXT,
    likes_count INTEGER DEFAULT 0 NOT NULL,
    replies_count INTEGER DEFAULT 0 NOT NULL,
    reposts_count INTEGER DEFAULT 0 NOT NULL,
    is_pinned BOOLEAN DEFAULT false NOT NULL,
    mute_notifications BOOLEAN DEFAULT false NOT NULL,
    hide_from_profile BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. LIKES (REACTIONS) TABLE
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    reaction_type TEXT DEFAULT '❤️' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_thread_like UNIQUE (user_id, thread_id)
);

-- 4. COMMENTS TABLE
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE, -- Supports nested comment replies
    likes_count INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. COMMENT LIKES TABLE
CREATE TABLE IF NOT EXISTS public.comment_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_comment_like UNIQUE (user_id, comment_id)
);

-- 6. REPOSTS TABLE
CREATE TABLE IF NOT EXISTS public.reposts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_repost UNIQUE (user_id, thread_id)
);

-- 7. FOLLOWS RELATIONSHIP TABLE
CREATE TABLE IF NOT EXISTS public.follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    following_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_follower_following UNIQUE (follower_id, following_id)
);

-- 8. MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- Target user
    actor_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- Performer
    type TEXT NOT NULL, -- 'like', 'comment', 'follow', 'message'
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT notifications_type_check CHECK (LOWER(type) IN ('like', 'comment', 'reply', 'follow', 'mention', 'message'))
);

-- 10. REPORTS TABLE
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- Reporter
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE,
    reply_id UUID, -- Backwards compatibility for comment report
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' NOT NULL, -- 'pending', 'resolved'
    action_taken TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 11. SYSTEM SETTINGS & AUDIT LOGS (For Admin Panel integration)
CREATE TABLE IF NOT EXISTS public.system_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id TEXT NOT NULL,
    action TEXT NOT NULL,
    details TEXT,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Initialize default settings
INSERT INTO public.system_settings (key, value) VALUES 
('maintenance_mode', 'false'),
('disable_signups', 'false'),
('api_rate_limit', '100')
ON CONFLICT (key) DO NOTHING;

-- 12. BLOCKS TABLE
CREATE TABLE IF NOT EXISTS public.blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    blocked_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_blocker_blocked UNIQUE (blocker_id, blocked_id)
);

-- 13. MUTES TABLE
CREATE TABLE IF NOT EXISTS public.mutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    muter_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    muted_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_muter_muted UNIQUE (muter_id, muted_id)
);

-- 14. THREAD HIDES TABLE
CREATE TABLE IF NOT EXISTS public.thread_hides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_thread_hide_user UNIQUE (thread_id, user_id)
);


-- ============================================================================
-- TRIGGERS & FUNCTIONS FOR COUNTERS
-- ============================================================================

-- Function: Handle follower & following count updates
CREATE OR REPLACE FUNCTION public.handle_follow_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    UPDATE public.profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.profiles SET following_count = GREATEST(0, following_count - 1) WHERE id = OLD.follower_id;
    UPDATE public.profiles SET followers_count = GREATEST(0, followers_count - 1) WHERE id = OLD.following_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_follow_change
AFTER INSERT OR DELETE ON public.follows
FOR EACH ROW EXECUTE FUNCTION public.handle_follow_change();


-- Function: Handle thread likes count updates
CREATE OR REPLACE FUNCTION public.handle_like_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.threads SET likes_count = likes_count + 1 WHERE id = NEW.thread_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.threads SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.thread_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_like_change
AFTER INSERT OR DELETE ON public.likes
FOR EACH ROW EXECUTE FUNCTION public.handle_like_change();


-- Function: Handle comment count updates on threads
CREATE OR REPLACE FUNCTION public.handle_comment_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.threads SET replies_count = replies_count + 1 WHERE id = NEW.thread_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.threads SET replies_count = GREATEST(0, replies_count - 1) WHERE id = OLD.thread_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_comment_change
AFTER INSERT OR DELETE ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.handle_comment_change();


-- Function: Handle repost count updates on threads
CREATE OR REPLACE FUNCTION public.handle_repost_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.threads SET reposts_count = reposts_count + 1 WHERE id = NEW.thread_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.threads SET reposts_count = GREATEST(0, reposts_count - 1) WHERE id = OLD.thread_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_repost_change
AFTER INSERT OR DELETE ON public.reposts
FOR EACH ROW EXECUTE FUNCTION public.handle_repost_change();


-- ============================================================================
-- FUNCTIONS FOR AUTO-NOTIFICATIONS
-- ============================================================================

-- Trigger: Notification on follow
CREATE OR REPLACE FUNCTION public.notify_on_follow()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.following_id::text != NEW.follower_id::text THEN
    INSERT INTO public.notifications (user_id, actor_id, type, content)
    VALUES (
      NEW.following_id::uuid,
      NEW.follower_id::uuid,
      'follow',
      'started following you'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_follow_notify
AFTER INSERT ON public.follows
FOR EACH ROW EXECUTE FUNCTION public.notify_on_follow();


-- Trigger: Notification on post like
CREATE OR REPLACE FUNCTION public.notify_on_like()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id TEXT;
  is_muted BOOLEAN;
BEGIN
  SELECT user_id::text, mute_notifications INTO target_user_id, is_muted 
  FROM public.threads 
  WHERE id = NEW.thread_id;
  
  IF target_user_id IS NOT NULL AND target_user_id != NEW.user_id::text AND (is_muted IS NOT TRUE) THEN
    INSERT INTO public.notifications (user_id, actor_id, type, thread_id, content)
    VALUES (
      target_user_id::uuid,
      NEW.user_id::uuid,
      'like',
      NEW.thread_id,
      'liked your post'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_like_notify
AFTER INSERT ON public.likes
FOR EACH ROW EXECUTE FUNCTION public.notify_on_like();


-- Trigger: Notification on comment
CREATE OR REPLACE FUNCTION public.notify_on_comment()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id TEXT;
  is_muted BOOLEAN;
BEGIN
  SELECT user_id::text, mute_notifications INTO target_user_id, is_muted 
  FROM public.threads 
  WHERE id = NEW.thread_id;
  
  IF target_user_id IS NOT NULL AND target_user_id != NEW.user_id::text AND (is_muted IS NOT TRUE) THEN
    INSERT INTO public.notifications (user_id, actor_id, type, thread_id, content)
    VALUES (
      target_user_id::uuid,
      NEW.user_id::uuid,
      'comment',
      NEW.thread_id,
      'commented on your post: ' || LEFT(NEW.content, 50)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_comment_notify
AFTER INSERT ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.notify_on_comment();


-- Enable realtime for tables we need updates on
ALTER PUBLICATION supabase_realtime ADD TABLE public.threads;
ALTER PUBLICATION supabase_realtime ADD TABLE public.likes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.follows;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;
ALTER PUBLICATION supabase_realtime ADD TABLE public.reposts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.blocks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.mutes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.thread_hides;
