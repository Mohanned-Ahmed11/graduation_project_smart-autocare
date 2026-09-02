-- Let accepted requester and driver read each other's profiles (name, phone, etc.)
-- for the same request (used by chat contact header).

create policy "profiles_select_chat_counterparty"
on public.profiles for select
using (
  exists (
    select 1
    from public.chats c
    join public.requests r on r.id = c.request_id
    join public.request_responses rr
      on rr.request_id = r.id and rr.status = 'accepted'
    where profiles.id = rr.driver_id
      and r.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.chats c
    join public.requests r on r.id = c.request_id
    join public.request_responses rr
      on rr.request_id = r.id and rr.status = 'accepted'
    where profiles.id = r.user_id
      and rr.driver_id = auth.uid()
  )
);
