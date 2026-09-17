-- ============================================================================
-- DAK SOCIAL NETWORK - ENTERPRISE AUTOMATED PUSH NOTIFICATIONS TRIGGERS
-- Supports: Messages, Comments, Likes, Follows, Mentions
-- Anti-Spam Protections:
--   1. Self-action suppression (never notify on own likes, comments, mentions)
--   2. OS Tag collapsing (like_<thread_id>, comment_<thread_id>) to prevent tray flooding
--   3. Silent delivery for likes (no annoying repeated vibrations/chimes)
--   4. Fast pg_net async invocation to Edge Function
-- Execute this script in your Supabase SQL Editor.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.notify_fcm_edge_function()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  receiver_id UUID;
  receiver_token TEXT;
  sender_name TEXT;
  push_title TEXT;
  push_body TEXT;
  notif_tag TEXT;
  notif_channel TEXT;
  is_silent BOOLEAN := false;
  payload JSONB;
BEGIN
  -- 1. Messages / Chat
  IF TG_TABLE_NAME = 'messages' THEN
    receiver_id := NEW.receiver_id;
    IF receiver_id = NEW.sender_id THEN RETURN NEW; END IF;
    
    SELECT COALESCE(full_name, username, 'Someone') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;
    push_title := sender_name;
    push_body := 'Sent you a new message';
    notif_tag := 'dm_' || NEW.sender_id::text;
    notif_channel := 'pigeon_messages';

  -- 2. Comments on threads
  ELSIF TG_TABLE_NAME = 'comments' THEN
    SELECT user_id INTO receiver_id FROM public.threads WHERE id = NEW.thread_id;
    IF receiver_id IS NULL OR receiver_id = NEW.user_id THEN RETURN NEW; END IF;

    SELECT COALESCE(full_name, username, 'Someone') INTO sender_name FROM public.profiles WHERE id = NEW.user_id;
    push_title := 'New Comment';
    push_body := sender_name || ' commented on your post: ' || LEFT(NEW.content, 80);
    notif_tag := 'comment_' || NEW.thread_id::text;
    notif_channel := 'pigeon_activity';

  -- 3. Notifications table (Likes, Follows, Mentions)
  ELSIF TG_TABLE_NAME = 'notifications' THEN
    receiver_id := NEW.user_id;
    IF receiver_id = NEW.actor_id THEN RETURN NEW; END IF;

    SELECT COALESCE(full_name, username, 'Someone') INTO sender_name FROM public.profiles WHERE id = NEW.actor_id;

    IF NEW.type = 'like' THEN
      push_title := sender_name;
      push_body := 'liked your post';
      notif_tag := 'like_' || COALESCE(NEW.thread_id::text, NEW.actor_id::text);
      notif_channel := 'pigeon_likes';
      is_silent := true; -- Anti-spam: silent on device so phone does not vibrate for every like!
    ELSIF NEW.type = 'follow' THEN
      push_title := 'New Follower';
      push_body := sender_name || ' started following you';
      notif_tag := 'follow_' || NEW.actor_id::text;
      notif_channel := 'pigeon_follows';
    ELSIF NEW.type = 'mention' THEN
      push_title := 'New Mention';
      push_body := sender_name || ' mentioned you: ' || LEFT(COALESCE(NEW.content, ''), 80);
      notif_tag := 'mention_' || COALESCE(NEW.thread_id::text, NEW.actor_id::text);
      notif_channel := 'pigeon_mentions';
    ELSE
      -- Skip other internal types
      RETURN NEW;
    END IF;

  END IF;

  -- Fetch receiver's active FCM token
  SELECT fcm_token INTO receiver_token FROM public.profiles WHERE id = receiver_id;

  IF receiver_token IS NOT NULL AND LENGTH(receiver_token) > 10 THEN
    payload := jsonb_build_object(
      'fcm_token', receiver_token,
      'title', push_title,
      'body', push_body,
      'tag', notif_tag,
      'channel_id', notif_channel,
      'silent', is_silent
    );

    -- Async HTTP post via pg_net
    PERFORM net.http_post(
      url := 'https://lznxtbnqwaryqkyxfwgy.supabase.co/functions/v1/send_auto_push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6bnh0Ym5xd2FyeXFreXhmd2d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNTk1MjIsImV4cCI6MjA5NjkzNTUyMn0.PGQqRFmGjE5GncIs5Eeqf5fvgxQtDMgvggNLzNEGOJk'
      ),
      body := payload
    );
  END IF;

  RETURN NEW;
END;
$$;

-- 1. Trigger for Messages
DROP TRIGGER IF EXISTS trigger_push_on_message ON public.messages;
CREATE TRIGGER trigger_push_on_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_fcm_edge_function();

-- 2. Trigger for Comments
DROP TRIGGER IF EXISTS trigger_push_on_comment ON public.comments;
CREATE TRIGGER trigger_push_on_comment
  AFTER INSERT ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_fcm_edge_function();

-- 3. Trigger for Notifications (Likes, Follows, Mentions)
DROP TRIGGER IF EXISTS trigger_push_on_notification ON public.notifications;
CREATE TRIGGER trigger_push_on_notification
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  WHEN (NEW.type IN ('like', 'follow', 'mention'))
  EXECUTE FUNCTION public.notify_fcm_edge_function();
