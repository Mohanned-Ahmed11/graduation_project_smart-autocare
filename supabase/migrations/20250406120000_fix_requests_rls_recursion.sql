-- Fix "infinite recursion detected in policy for relation requests":
-- requests SELECT (accepted_driver) scanned request_responses under RLS;
-- rr_select on request_responses subqueries requests under RLS → cycle.

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

revoke all on function public.request_has_accepted_driver(uuid, uuid) from public;
grant execute on function public.request_has_accepted_driver(uuid, uuid) to authenticated;
grant execute on function public.request_has_accepted_driver(uuid, uuid) to service_role;

drop policy if exists "requests_select_accepted_driver" on public.requests;
create policy "requests_select_accepted_driver" on public.requests for select using (
  public.request_has_accepted_driver(requests.id, auth.uid())
);

drop policy if exists "requests_update" on public.requests;
create policy "requests_update" on public.requests for update using (
  auth.uid() = user_id
  or public.request_has_accepted_driver(requests.id, auth.uid())
);
