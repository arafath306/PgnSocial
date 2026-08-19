-- ============================================================================
-- DAK SOCIAL NETWORK - PRODUCTION ROW LEVEL SECURITY (RLS) POLICIES
-- Execute this script in your Supabase SQL Editor AFTER running new_clean_schema.sql.
-- This secures all 15 tables, ensuring users can only modify their own data.
-- ============================================================================

-- 1. PROFILES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on profiles" 
ON public.profiles FOR SELECT 
USING (true);

CREATE POLICY "Allow authenticated insert on profiles" 
ON public.profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to update their own profiles" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);


-- 2. THREADS
ALTER TABLE public.threads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on threads" 
ON public.threads FOR SELECT 
USING (true);

CREATE POLICY "Allow authenticated users to insert threads" 
ON public.threads FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update their own threads" 
ON public.threads FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to delete their own threads" 
ON public.threads FOR DELETE 
USING (auth.uid() = user_id);


-- 3. LIKES
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on likes" 
ON public.likes FOR SELECT 
USING (true);

CREATE POLICY "Allow users to insert their own likes" 
ON public.likes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete their own likes" 
ON public.likes FOR DELETE 
USING (auth.uid() = user_id);


-- 4. COMMENTS
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on comments" 
ON public.comments FOR SELECT 
USING (true);

CREATE POLICY "Allow users to insert comments" 
ON public.comments FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update their own comments" 
ON public.comments FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to delete their own comments" 
ON public.comments FOR DELETE 
USING (auth.uid() = user_id);


-- 5. COMMENT LIKES
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on comment_likes" 
ON public.comment_likes FOR SELECT 
USING (true);

CREATE POLICY "Allow users to insert comment_likes" 
ON public.comment_likes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete comment_likes" 
ON public.comment_likes FOR DELETE 
USING (auth.uid() = user_id);


-- 6. FOLLOWS
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on follows" 
ON public.follows FOR SELECT 
USING (true);

CREATE POLICY "Allow users to insert follows" 
ON public.follows FOR INSERT 
WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Allow users to delete follows" 
ON public.follows FOR DELETE 
USING (auth.uid() = follower_id);


-- 7. MESSAGES
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read their own messages" 
ON public.messages FOR SELECT 
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Allow users to insert their own messages" 
ON public.messages FOR INSERT 
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Allow receivers to update read status" 
ON public.messages FOR UPDATE 
USING (auth.uid() = receiver_id);

CREATE POLICY "Allow senders to edit their own messages" 
ON public.messages FOR UPDATE 
USING (auth.uid() = sender_id);

CREATE POLICY "Allow senders to delete their own messages" 
ON public.messages FOR DELETE 
USING (auth.uid() = sender_id);


-- 8. NOTIFICATIONS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read their own notifications" 
ON public.notifications FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to update their own notifications" 
ON public.notifications FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Allow authenticated users to insert notifications" 
ON public.notifications FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = actor_id);


-- 9. REPORTS
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow select for reports" 
ON public.reports FOR SELECT 
USING (true);

CREATE POLICY "Allow users to insert reports" 
ON public.reports FOR INSERT 
WITH CHECK (auth.uid() = user_id);


-- 10. SYSTEM SETTINGS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on system_settings" 
ON public.system_settings FOR SELECT 
USING (true);

CREATE POLICY "Admins can modify system_settings" 
ON public.system_settings FOR ALL 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
  )
);


-- 11. AUDIT LOGS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow select on audit_logs" 
ON public.audit_logs FOR SELECT 
USING (true);

CREATE POLICY "Allow insert on audit_logs" 
ON public.audit_logs FOR INSERT 
WITH CHECK (true);


-- 12. BLOCKS
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read their blocks" 
ON public.blocks FOR SELECT 
USING (auth.uid() = blocker_id OR auth.uid() = blocked_id);

CREATE POLICY "Allow users to insert blocks" 
ON public.blocks FOR INSERT 
WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Allow users to delete blocks" 
ON public.blocks FOR DELETE 
USING (auth.uid() = blocker_id);


-- 13. MUTES
ALTER TABLE public.mutes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read their mutes" 
ON public.mutes FOR SELECT 
USING (auth.uid() = muter_id);

CREATE POLICY "Allow users to insert mutes" 
ON public.mutes FOR INSERT 
WITH CHECK (auth.uid() = muter_id);

CREATE POLICY "Allow users to delete mutes" 
ON public.mutes FOR DELETE 
USING (auth.uid() = muter_id);


-- 14. THREAD HIDES
ALTER TABLE public.thread_hides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read their thread_hides" 
ON public.thread_hides FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to insert thread_hides" 
ON public.thread_hides FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete thread_hides" 
ON public.thread_hides FOR DELETE 
USING (auth.uid() = user_id);


-- 15. REPOSTS
ALTER TABLE public.reposts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on reposts" 
ON public.reposts FOR SELECT 
USING (true);

CREATE POLICY "Allow users to insert reposts" 
ON public.reposts FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete reposts" 
ON public.reposts FOR DELETE 
USING (auth.uid() = user_id);
