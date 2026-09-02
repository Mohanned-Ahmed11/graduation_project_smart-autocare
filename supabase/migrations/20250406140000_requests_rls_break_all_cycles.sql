-- Fully break RLS cycles between public.requests and public.request_responses.
-- Any policy that does EXISTS (subquery on the other table under invoker RLS) can recurse.
-- SECURITY DEFINER helpers read as table owner → no RLS re-entry.

create or replace function public.request_has_accepted_driver(
  p_request_id uuid,
  p_driver_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.request_responses rr
    where rr.request_id = p_request_id
      and rr.driver_id = p_driver_id
      and rr.status = 'accepted'
  );
$$;

create or replace function public.request_owned_by_user(p_request_id uuid, p_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.requests r
    where r.id = p_request_id
      and r.user_id = p_uid
  );
$$;

create or replace function public.request_select_allowed(p_request_id uuid, p_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.requests r
    where r.id = p_request_id
      and (
        r.user_id = p_uid
        or r.status = 'open'
        or exists (
          select 1 from public.request_responses rr
          where rr.request_id = r.id
            and rr.driver_id = p_uid
            and rr.status = 'accepted'
        )
      )
  );
$$;

revoke all on function public.request_has_accepted_driver(uuid, uuid) from public;
revoke all on function public.request_owned_by_user(uuid, uuid) from public;
revoke all on function public.request_select_allowed(uuid, uuid) from public;

grant execute on function public.request_has_accepted_driver(uuid, uuid) to authenticated, service_role;
grant execute on function public.request_owned_by_user(uuid, uuid) to authenticated, service_role;
grant execute on function public.request_select_allowed(uuid, uuid) to authenticated, service_role;

-- requests: single SELECT policy (replaces split policies that still chained with rr_select).
drop policy if exists "requests_select" on public.requests;
drop policy if exists "requests_select_accepted_driver" on public.requests;
create policy "requests_select" on public.requests for select using (
  public.request_select_allowed(requests.id, auth.uid())
);

drop policy if exists "requests_update" on public.requests;
create policy "requests_update" on public.requests for update using (
  auth.uid() = user_id
  or public.request_has_accepted_driver(requests.id, auth.uid())
);

-- request_responses: no direct SELECT on requests from policies.
drop policy if exists "rr_select" on public.request_responses;
create policy "rr_select" on public.request_responses for select using (
  auth.uid() = driver_id
  or public.request_owned_by_user(request_responses.request_id, auth.uid())
);

drop policy if exists "rr_update_requester" on public.request_responses;
create policy "rr_update_requester" on public.request_responses for update using (
  public.request_owned_by_user(request_responses.request_id, auth.uid())
);

drop policy if exists "rr_delete_requester_pending" on public.request_responses;
create policy "rr_delete_requester_pending" on public.request_responses for delete using (
  status = 'pending'
  and public.request_owned_by_user(request_responses.request_id, auth.uid())
);

-- chats insert: avoid EXISTS on requests under invoker RLS.
drop policy if exists "chats_insert" on public.chats;
create policy "chats_insert" on public.chats for insert with check (
  public.request_owned_by_user(chats.request_id, auth.uid())
  or public.request_has_accepted_driver(chats.request_id, auth.uid())
);
