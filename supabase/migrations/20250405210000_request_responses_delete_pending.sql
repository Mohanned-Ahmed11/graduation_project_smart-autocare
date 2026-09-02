-- Allow request owner to delete pending responses (when accepting another driver).
create policy "rr_delete_requester_pending"
on public.request_responses for delete
using (
  status = 'pending'
  and exists (
    select 1 from public.requests r
    where r.id = request_responses.request_id
      and r.user_id = auth.uid()
  )
);
