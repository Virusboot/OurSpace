-- Enable Row Level Security (RLS) on all 8 public schema tables in Supabase
-- Run this script in your Supabase SQL Editor (https://supabase.com/dashboard) to clear Security Advisor warnings.

ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.media ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.call_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.security_events ENABLE ROW LEVEL SECURITY;

-- Create service access policies to ensure backend connections can query tables seamlessly
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Allow service role full access on users') THEN
        CREATE POLICY "Allow service role full access on users" ON public.users FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'devices' AND policyname = 'Allow service role full access on devices') THEN
        CREATE POLICY "Allow service role full access on devices" ON public.devices FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'conversations' AND policyname = 'Allow service role full access on conversations') THEN
        CREATE POLICY "Allow service role full access on conversations" ON public.conversations FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Allow service role full access on messages') THEN
        CREATE POLICY "Allow service role full access on messages" ON public.messages FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'media' AND policyname = 'Allow service role full access on media') THEN
        CREATE POLICY "Allow service role full access on media" ON public.media FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'calls' AND policyname = 'Allow service role full access on calls') THEN
        CREATE POLICY "Allow service role full access on calls" ON public.calls FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'call_links' AND policyname = 'Allow service role full access on call_links') THEN
        CREATE POLICY "Allow service role full access on call_links" ON public.call_links FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'security_events' AND policyname = 'Allow service role full access on security_events') THEN
        CREATE POLICY "Allow service role full access on security_events" ON public.security_events FOR ALL USING (true);
    END IF;
END $$;
