-- Learning Hub Marketplace: compatibility/security migration for the EXISTING project
-- Known from the existing RLS policies: public.listings has user_id and status columns.
-- This script does NOT drop tables, rows, users, or existing RLS policies.
-- Review the comments before running. It only adjusts known listing permissions/defaults
-- and prepares the public photo bucket used by the frontend.

begin;

-- Ensure RLS remains enabled. Existing four listing policies are intentionally preserved.
alter table public.listings enable row level security;

-- New listings created through the app explicitly send auth.uid(); this default is a fallback.
alter table public.listings alter column user_id set default auth.uid();

-- Keep the owner lookup efficient.
create index if not exists listings_user_id_idx on public.listings (user_id);

-- Remove powerful table-level privileges from ordinary signed-in users.
-- RLS does not replace these privilege restrictions (for example, TRUNCATE bypasses row policies).
revoke truncate, references, trigger on table public.listings from authenticated;

-- Ensure the intended application privileges exist. RLS policies still decide which rows
-- authenticated users may select/insert/update/delete.
grant select on table public.listings to anon, authenticated;
grant insert, update, delete on table public.listings to authenticated;

-- Public read bucket for listing photos. Upload/delete remain restricted by storage policies.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-photos', 'listing-photos', true, 3145728,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Idempotently create storage policies if their names are not already present.
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='learning hub listing photos public read') then
    create policy "learning hub listing photos public read" on storage.objects
      for select to anon, authenticated
      using (bucket_id = 'listing-photos');
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='learning hub listing photos owner upload') then
    create policy "learning hub listing photos owner upload" on storage.objects
      for insert to authenticated
      with check (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='learning hub listing photos owner delete') then
    create policy "learning hub listing photos owner delete" on storage.objects
      for delete to authenticated
      using (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
end $$;

commit;

-- Expected existing listings policies (do not recreate or drop them):
-- SELECT: status <> 'removed'
-- INSERT: auth.uid() = user_id AND status = 'available'
-- UPDATE: auth.uid() = user_id (USING and WITH CHECK)
-- DELETE: auth.uid() = user_id
