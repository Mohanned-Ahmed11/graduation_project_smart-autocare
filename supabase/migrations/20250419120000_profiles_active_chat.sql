-- Presence for chat push: skip FCM when user has this chat open (foreground) recently.
alter table public.profiles
  add column if not exists active_chat_id uuid references public.chats (id) on delete set null;
alter table public.profiles
  add column if not exists active_chat_at timestamptz;

comment on column public.profiles.active_chat_id is 'Chat thread currently open in the app (cleared on leave/background).';
comment on column public.profiles.active_chat_at is 'Last heartbeat while active_chat_id is set.';
