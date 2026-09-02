-- Ensure authenticated users can insert their own requests.
-- If this policy was never applied or was dropped, inserts fail with:
-- PostgrestException: new row violates row-level security policy for table "requests"

drop policy if exists "requests_insert_own" on public.requests;

create policy "requests_insert_own" on public.requests
  for insert
  with check (auth.uid() = user_id);
