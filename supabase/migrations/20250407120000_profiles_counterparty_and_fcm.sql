-- Request owners may read driver profiles for pending/accepted offers on their requests
-- (names + map coordinates for distance UX). Keeps profiles_select_own for everyone else.

create policy "profiles_select_request_counterparty"
on public.profiles for select
using (
  exists (
    select 1
    from public.request_responses rr
    join public.requests r on r.id = rr.request_id
    where rr.driver_id = profiles.id
      and r.user_id = auth.uid()
      and rr.status in ('pending', 'accepted')
  )
);

-- Phase 2 push notifications: store device token from Flutter when FCM is wired.
alter table public.profiles add column if not exists fcm_token text;
