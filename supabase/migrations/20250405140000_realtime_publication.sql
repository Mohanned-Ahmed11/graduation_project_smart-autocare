-- Enable Supabase Realtime for chat and live request updates (idempotent where supported)
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.requests;
alter publication supabase_realtime add table public.request_responses;
