-- Let request owner + drivers with pending or accepted offers participate in the request chat
-- (negotiation before formal accept). Enables ensureChat right after driver taps "I'm interested".

create or replace function public.is_chat_participant(p_chat_id uuid, p_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.chats c
    join public.requests r on r.id = c.request_id
    where c.id = p_chat_id
      and (
        r.user_id = p_uid
        or exists (
          select 1 from public.request_responses rr
          where rr.request_id = r.id
            and rr.driver_id = p_uid
            and rr.status in ('pending', 'accepted')
        )
      )
  );
$$;

drop policy if exists "chats_insert" on public.chats;
create policy "chats_insert" on public.chats for insert with check (
  public.request_owned_by_user(chats.request_id, auth.uid())
  or public.request_has_accepted_driver(chats.request_id, auth.uid())
  or exists (
    select 1 from public.request_responses rr
    where rr.request_id = chats.request_id
      and rr.driver_id = auth.uid()
      and rr.status = 'pending'
  )
);
