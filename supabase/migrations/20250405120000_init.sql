-- SmartAutoCar schema: profiles, issues, requests, request_responses, chats, messages
-- Run in Supabase SQL editor or via CLI. Enable Realtime on: requests, messages, request_responses (Dashboard).

-- Extensions
create extension if not exists "uuid-ossp";

-- Enums
do $$ begin
  create type request_status as enum ('open', 'accepted', 'completed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type response_status as enum ('pending', 'accepted');
exception when duplicate_object then null; end $$;

-- Profiles (synced with auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text,
  phone text,
  car_model text,
  profile_image text,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.issues (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  description text,
  image_url text,
  voice_url text,
  ai_response jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text,
  image_url text,
  price numeric(12, 2),
  latitude double precision,
  longitude double precision,
  status request_status not null default 'open',
  created_at timestamptz not null default now()
);

create index if not exists idx_requests_status on public.requests (status);
create index if not exists idx_requests_created on public.requests (created_at desc);

create table if not exists public.request_responses (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.requests (id) on delete cascade,
  driver_id uuid not null references public.profiles (id) on delete cascade,
  status response_status not null default 'pending',
  created_at timestamptz not null default now(),
  unique (request_id, driver_id)
);

create index if not exists idx_request_responses_request on public.request_responses (request_id);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.requests (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  message text,
  image_url text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_chat on public.messages (chat_id, created_at);

-- Updated_at trigger for profiles
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- New user -> profile row
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Helper: is user a participant in this chat?
create or replace function public.is_chat_participant(p_chat_id uuid, p_uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.chats c
    join public.requests r on r.id = c.request_id
    left join public.request_responses rr
      on rr.request_id = r.id and rr.status = 'accepted'
    where c.id = p_chat_id
      and (r.user_id = p_uid or rr.driver_id = p_uid)
  );
$$;

-- RLS
alter table public.profiles enable row level security;
alter table public.issues enable row level security;
alter table public.requests enable row level security;
alter table public.request_responses enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;

-- Profiles
create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);

-- Issues
create policy "issues_select_own" on public.issues for select using (auth.uid() = user_id);
create policy "issues_insert_own" on public.issues for insert with check (auth.uid() = user_id);
create policy "issues_update_own" on public.issues for update using (auth.uid() = user_id);
create policy "issues_delete_own" on public.issues for delete using (auth.uid() = user_id);

-- Requests: MVP — open rows for all auth users; own rows; driver who accepted
create policy "requests_select" on public.requests for select using (
  auth.uid() = user_id or status = 'open'
);
create policy "requests_select_accepted_driver" on public.requests for select using (
  exists (
    select 1 from public.request_responses rr
    where rr.request_id = requests.id
      and rr.driver_id = auth.uid()
      and rr.status = 'accepted'
  )
);
create policy "requests_insert_own" on public.requests for insert with check (auth.uid() = user_id);
-- Owner or accepted driver can update (e.g. status)
create policy "requests_update" on public.requests for update using (
  auth.uid() = user_id
  or exists (
    select 1 from public.request_responses rr
    where rr.request_id = requests.id and rr.driver_id = auth.uid() and rr.status = 'accepted'
  )
);

-- Request responses
create policy "rr_select" on public.request_responses for select using (
  auth.uid() = driver_id
  or exists (select 1 from public.requests r where r.id = request_responses.request_id and r.user_id = auth.uid())
);
create policy "rr_insert_driver" on public.request_responses for insert with check (auth.uid() = driver_id);
create policy "rr_update_driver" on public.request_responses for update using (auth.uid() = driver_id);
create policy "rr_update_requester" on public.request_responses for update using (
  exists (select 1 from public.requests r where r.id = request_responses.request_id and r.user_id = auth.uid())
);

-- Chats: participants only
create policy "chats_select" on public.chats for select using (public.is_chat_participant(id, auth.uid()));
create policy "chats_insert" on public.chats for insert with check (
  exists (
    select 1 from public.requests r
    where r.id = chats.request_id and r.user_id = auth.uid()
  )
  or exists (
    select 1 from public.requests r
    join public.request_responses rr on rr.request_id = r.id and rr.status = 'accepted'
    where r.id = chats.request_id and rr.driver_id = auth.uid()
  )
);

-- Messages
create policy "messages_select" on public.messages for select using (public.is_chat_participant(chat_id, auth.uid()));
create policy "messages_insert" on public.messages for insert with check (
  sender_id = auth.uid() and public.is_chat_participant(chat_id, auth.uid())
);
create policy "messages_update" on public.messages for update using (public.is_chat_participant(chat_id, auth.uid()));

-- Storage buckets (create in Dashboard if SQL fails on older projects)
insert into storage.buckets (id, name, public)
values
  ('profile_images', 'profile_images', true),
  ('issue_images', 'issue_images', false),
  ('voice_records', 'voice_records', false),
  ('chat_images', 'chat_images', false)
on conflict (id) do nothing;

-- Storage policies: own folder {user_id}/...
create policy "profile_images_own"
on storage.objects for all using (
  bucket_id = 'profile_images' and (storage.foldername(name))[1] = auth.uid()::text
) with check (
  bucket_id = 'profile_images' and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "issue_images_own"
on storage.objects for all using (
  bucket_id = 'issue_images' and (storage.foldername(name))[1] = auth.uid()::text
) with check (
  bucket_id = 'issue_images' and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "voice_records_own"
on storage.objects for all using (
  bucket_id = 'voice_records' and (storage.foldername(name))[1] = auth.uid()::text
) with check (
  bucket_id = 'voice_records' and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "chat_images_authenticated"
on storage.objects for all using (
  bucket_id = 'chat_images' and auth.role() = 'authenticated'
) with check (
  bucket_id = 'chat_images' and auth.role() = 'authenticated'
);
