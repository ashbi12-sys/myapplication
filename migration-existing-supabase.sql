-- Learning Hub Marketplace: EXISTING Supabase project migration
-- Safe scope: no table drops, no row deletes, no auth-user changes, no policy drops.
-- The frontend fetches seller profiles separately, so listings -> profiles embedding
-- does NOT require a PostgREST foreign-key relationship.

begin;

-- Existing listings table and ownership column are expected from the current project.
-- Add only the international listing metadata needed by the updated frontend.
alter table public.listings enable row level security;
alter table public.listings
  add column if not exists country_code text not null default 'PH',
  add column if not exists currency_code text not null default 'PHP';

-- Normalize and validate ISO-style codes without changing existing prices.
update public.listings set country_code = 'PH' where country_code is null or btrim(country_code) = '';
update public.listings set currency_code = 'PHP' where currency_code is null or btrim(currency_code) = '';

create index if not exists listings_user_id_idx on public.listings (user_id);
create index if not exists listings_country_created_idx on public.listings (country_code, created_at desc);
create index if not exists listings_currency_idx on public.listings (currency_code);

-- Ordinary users need row-level operations only. RLS policies remain the authority.
revoke truncate, references, trigger on table public.listings from authenticated;
grant select on table public.listings to anon, authenticated;
grant insert, update, delete on table public.listings to authenticated;

-- Public listing images; uploads and deletes are restricted to the owner's folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-photos', 'listing-photos', true, 3145728,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

do $$ begin
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='learning hub listing photos public read') then
    create policy "learning hub listing photos public read" on storage.objects
      for select to anon, authenticated using (bucket_id = 'listing-photos');
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='learning hub listing photos owner upload') then
    create policy "learning hub listing photos owner upload" on storage.objects
      for insert to authenticated with check (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='learning hub listing photos owner delete') then
    create policy "learning hub listing photos owner delete" on storage.objects
      for delete to authenticated using (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
end $$;

commit;

-- After running, refresh PostgREST schema cache:
notify pgrst, 'reload schema';

-- Existing four listings RLS policies are intentionally preserved:
-- SELECT: status <> 'removed'
-- INSERT: auth.uid() = user_id AND status = 'available'
-- UPDATE/DELETE: auth.uid() = user_id
