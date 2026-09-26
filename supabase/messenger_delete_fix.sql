-- ==============================================================================
-- MESSENGER DELETION, CLEAR CHAT & FOR EVERYONE / FOR ME REPAIR SCRIPT
-- ==============================================================================

-- 1. Ensure columns exist with default false
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS deleted_by_sender BOOLEAN DEFAULT false;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS deleted_by_receiver BOOLEAN DEFAULT false;

-- 2. Update all existing NULL values to false to prevent query filtering issues
UPDATE public.messages SET deleted_by_sender = false WHERE deleted_by_sender IS NULL;
UPDATE public.messages SET deleted_by_receiver = false WHERE deleted_by_receiver IS NULL;

-- 3. Set NOT NULL with DEFAULT false
ALTER TABLE public.messages ALTER COLUMN deleted_by_sender SET DEFAULT false;
ALTER TABLE public.messages ALTER COLUMN deleted_by_receiver SET DEFAULT false;

-- 4. Create optimized indexes for active messages filtering
CREATE INDEX IF NOT EXISTS idx_messages_deleted_sender ON public.messages(sender_id) WHERE deleted_by_sender = false;
CREATE INDEX IF NOT EXISTS idx_messages_deleted_receiver ON public.messages(receiver_id) WHERE deleted_by_receiver = false;
CREATE INDEX IF NOT EXISTS idx_messages_room_filter ON public.messages(sender_id, receiver_id, created_at DESC);

-- 5. Auto cleanup: If BOTH sender and receiver marked as deleted, remove row
CREATE OR REPLACE FUNCTION delete_fully_deleted_messages()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.deleted_by_sender = true AND NEW.deleted_by_receiver = true THEN
    DELETE FROM public.messages WHERE id = NEW.id;
    RETURN NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_delete_fully_deleted_messages ON public.messages;
CREATE TRIGGER trigger_delete_fully_deleted_messages
AFTER UPDATE OF deleted_by_sender, deleted_by_receiver ON public.messages
FOR EACH ROW
WHEN (NEW.deleted_by_sender = true AND NEW.deleted_by_receiver = true)
EXECUTE FUNCTION delete_fully_deleted_messages();

-- 6. Row Level Security Policies for Messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Allow users to read messages where they are sender or receiver, unless deleted for them
DROP POLICY IF EXISTS "Allow users to read their own messages" ON public.messages;
CREATE POLICY "Allow users to read their own messages" 
ON public.messages FOR SELECT 
USING (
  (auth.uid() = sender_id AND deleted_by_sender = false) OR 
  (auth.uid() = receiver_id AND deleted_by_receiver = false)
);

-- Allow users to insert messages where they are sender
DROP POLICY IF EXISTS "Allow users to insert their own messages" ON public.messages;
CREATE POLICY "Allow users to insert their own messages" 
ON public.messages FOR INSERT 
WITH CHECK (auth.uid() = sender_id);

-- Allow sender to update their message (edit text, reactions, pin, deleted_by_sender)
DROP POLICY IF EXISTS "Allow senders to update their own messages" ON public.messages;
DROP POLICY IF EXISTS "Allow senders to edit their own messages" ON public.messages;
CREATE POLICY "Allow senders to update their own messages" 
ON public.messages FOR UPDATE 
USING (auth.uid() = sender_id);

-- Allow receiver to update message (read status, reactions, pin, deleted_by_receiver)
DROP POLICY IF EXISTS "Allow receivers to update their received messages" ON public.messages;
DROP POLICY IF EXISTS "Allow receivers to update read status" ON public.messages;
CREATE POLICY "Allow receivers to update their received messages" 
ON public.messages FOR UPDATE 
USING (auth.uid() = receiver_id);

-- Allow sender to hard-delete their messages (Delete for Everyone)
DROP POLICY IF EXISTS "Allow senders to delete their own messages" ON public.messages;
CREATE POLICY "Allow senders to delete their own messages" 
ON public.messages FOR DELETE 
USING (auth.uid() = sender_id);

-- 7. Secure RPC Functions for Message & Conversation Deletion
CREATE OR REPLACE FUNCTION public.delete_message_for_me(p_message_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN false;
  END IF;

  UPDATE public.messages
  SET deleted_by_sender = true
  WHERE id = p_message_id AND sender_id = v_uid;

  UPDATE public.messages
  SET deleted_by_receiver = true
  WHERE id = p_message_id AND receiver_id = v_uid;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.delete_message_for_everyone(p_message_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN false;
  END IF;

  DELETE FROM public.messages
  WHERE id = p_message_id AND sender_id = v_uid;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.delete_conversation_for_me(p_other_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN false;
  END IF;

  UPDATE public.messages
  SET deleted_by_sender = true
  WHERE sender_id = v_uid AND receiver_id = p_other_user_id;

  UPDATE public.messages
  SET deleted_by_receiver = true
  WHERE receiver_id = v_uid AND sender_id = p_other_user_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
