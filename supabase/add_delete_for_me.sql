ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS deleted_by_sender BOOLEAN DEFAULT false;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS deleted_by_receiver BOOLEAN DEFAULT false;

-- Create an index to help with filtering deleted messages
CREATE INDEX IF NOT EXISTS idx_messages_deleted_sender ON public.messages(sender_id) WHERE deleted_by_sender = false;
CREATE INDEX IF NOT EXISTS idx_messages_deleted_receiver ON public.messages(receiver_id) WHERE deleted_by_receiver = false;

-- Add a function to automatically delete messages if BOTH sender and receiver deleted them
CREATE OR REPLACE FUNCTION delete_fully_deleted_messages()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.deleted_by_sender = true AND NEW.deleted_by_receiver = true THEN
    DELETE FROM public.messages WHERE id = NEW.id;
    RETURN NULL; -- Row is deleted, don't return it
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_delete_fully_deleted_messages ON public.messages;
CREATE TRIGGER trigger_delete_fully_deleted_messages
AFTER UPDATE ON public.messages
FOR EACH ROW
WHEN (NEW.deleted_by_sender = true AND NEW.deleted_by_receiver = true)
EXECUTE FUNCTION delete_fully_deleted_messages();
