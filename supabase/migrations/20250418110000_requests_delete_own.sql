-- Request owners may delete their own rows (cascades request_responses, chats, messages).

drop policy if exists "requests_delete_own" on public.requests;

create policy "requests_delete_own" on public.requests
  for delete
  using (auth.uid() = user_id);
