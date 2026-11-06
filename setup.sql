-- =====================================================================
-- Marketplace (Philippines) - database setup for Supabase
-- Paste ALL of this in Supabase > SQL Editor > New query > Run.
-- It is safe to run more than once.
-- =====================================================================

-- ---------- 1. Tables ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Member' check (char_length(display_name) between 2 and 40),
  region text check (char_length(region) <= 60),
  city text check (char_length(city) <= 60),
  is_banned boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  seller_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 80),
  description text not null default '' check (char_length(description) <= 1000),
  price numeric(12,2) not null default 0 check (price >= 0 and price <= 10000000),
  category text not null check (char_length(category) <= 40),
  condition text not null check (condition in ('New','Like new','Used')),
  region text not null check (char_length(region) <= 60),
  city text check (char_length(city) <= 60),
  photos text[] not null default '{}' check (cardinality(photos) <= 5),
  thumbs text[] not null default '{}' check (cardinality(thumbs) <= 5),
  status text not null default 'available' check (status in ('available','sold','removed'))
);
create index if not exists listings_browse_idx on public.listings (status, created_at desc);
create index if not exists listings_seller_idx on public.listings (seller_id);

create table if not exists public.blocks (
  blocker_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  buyer_id uuid not null default auth.uid(),
  seller_id uuid not null,
  last_message text,
  last_sender uuid,
  last_message_at timestamptz not null default now(),
  buyer_last_read timestamptz,
  seller_last_read timestamptz,
  constraint conversations_buyer_fk foreign key (buyer_id) references public.profiles(id) on delete cascade,
  constraint conversations_seller_fk foreign key (seller_id) references public.profiles(id) on delete cascade,
  constraint conversations_unique unique (listing_id, buyer_id),
  constraint conversations_not_self check (buyer_id <> seller_id)
);
create index if not exists conversations_buyer_idx on public.conversations (buyer_id);
create index if not exists conversations_seller_idx on public.conversations (seller_id);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 1000)
);
create index if not exists messages_conv_idx on public.messages (conversation_id, created_at);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  reporter_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  listing_id uuid references public.listings(id) on delete set null,
  reported_user_id uuid references public.profiles(id) on delete set null,
  reason text not null check (char_length(reason) <= 60),
  details text check (char_length(details) <= 500)
);

-- ---------- 2. Helper functions ----------
create or replace function public.not_banned() returns boolean
language sql stable security definer set search_path = public as $$
  select not coalesce((select p.is_banned from public.profiles p where p.id = auth.uid()), false);
$$;

create or replace function public.is_participant(cid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.conversations c
                 where c.id = cid and auth.uid() in (c.buyer_id, c.seller_id));
$$;

create or replace function public.can_message(cid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select public.not_banned() and exists (
    select 1 from public.conversations c
    where c.id = cid and auth.uid() in (c.buyer_id, c.seller_id)
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = auth.uid() and b.blocked_id = case when c.buyer_id = auth.uid() then c.seller_id else c.buyer_id end)
           or (b.blocked_id = auth.uid() and b.blocker_id = case when c.buyer_id = auth.uid() then c.seller_id else c.buyer_id end)
      )
  );
$$;

-- ---------- 3. Triggers ----------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare nm text; rg text;
begin
  nm := left(coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'), ''), split_part(coalesce(new.email, ''), '@', 1)), 40);
  if nm is null or char_length(nm) < 2 then nm := 'Member'; end if;
  rg := nullif(left(coalesce(new.raw_user_meta_data->>'region', ''), 60), '');
  insert into public.profiles (id, display_name, region) values (new.id, nm, rg) on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.limit_listings() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.listings where seller_id = new.seller_id and status = 'available') >= 30 then
    raise exception 'You have too many active listings. Mark some as sold or remove them first.';
  end if;
  if (select count(*) from public.listings where seller_id = new.seller_id and created_at > now() - interval '1 hour') >= 10 then
    raise exception 'Too many new listings in one hour. Please try again later.';
  end if;
  return new;
end $$;
drop trigger if exists listings_limit on public.listings;
create trigger listings_limit before insert on public.listings
  for each row execute function public.limit_listings();

create or replace function public.limit_messages() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.messages where sender_id = new.sender_id and created_at > now() - interval '1 minute') >= 30 then
    raise exception 'You are sending messages too fast. Please wait a moment.';
  end if;
  return new;
end $$;
drop trigger if exists messages_limit on public.messages;
create trigger messages_limit before insert on public.messages
  for each row execute function public.limit_messages();

create or replace function public.on_message_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.conversations set
    last_message = left(new.body, 120),
    last_sender = new.sender_id,
    last_message_at = new.created_at,
    buyer_last_read = case when buyer_id = new.sender_id then new.created_at else buyer_last_read end,
    seller_last_read = case when seller_id = new.sender_id then new.created_at else seller_last_read end
  where id = new.conversation_id;
  return new;
end $$;
drop trigger if exists messages_after_insert on public.messages;
create trigger messages_after_insert after insert on public.messages
  for each row execute function public.on_message_insert();

-- ---------- 4. Row Level Security (who can do what) ----------
alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.blocks enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;

drop policy if exists "profiles are public" on public.profiles;
create policy "profiles are public" on public.profiles for select using (true);
drop policy if exists "edit own profile" on public.profiles;
create policy "edit own profile" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "listings are public" on public.listings;
create policy "listings are public" on public.listings for select
  using (status <> 'removed' or seller_id = auth.uid());
drop policy if exists "sellers add listings" on public.listings;
create policy "sellers add listings" on public.listings for insert to authenticated
  with check (seller_id = auth.uid() and status = 'available' and public.not_banned());
drop policy if exists "sellers edit own listings" on public.listings;
create policy "sellers edit own listings" on public.listings for update to authenticated
  using (seller_id = auth.uid()) with check (seller_id = auth.uid() and public.not_banned());

drop policy if exists "see own blocks" on public.blocks;
create policy "see own blocks" on public.blocks for select to authenticated using (blocker_id = auth.uid());
drop policy if exists "add own blocks" on public.blocks;
create policy "add own blocks" on public.blocks for insert to authenticated with check (blocker_id = auth.uid());
drop policy if exists "remove own blocks" on public.blocks;
create policy "remove own blocks" on public.blocks for delete to authenticated using (blocker_id = auth.uid());

drop policy if exists "see my conversations" on public.conversations;
create policy "see my conversations" on public.conversations for select to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id);
drop policy if exists "start a conversation" on public.conversations;
create policy "start a conversation" on public.conversations for insert to authenticated
  with check (
    buyer_id = auth.uid() and public.not_banned()
    and seller_id = (select l.seller_id from public.listings l where l.id = listing_id)
  );
drop policy if exists "update my read marker" on public.conversations;
create policy "update my read marker" on public.conversations for update to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id)
  with check (auth.uid() = buyer_id or auth.uid() = seller_id);

drop policy if exists "read my messages" on public.messages;
create policy "read my messages" on public.messages for select to authenticated
  using (public.is_participant(conversation_id));
drop policy if exists "send messages" on public.messages;
create policy "send messages" on public.messages for insert to authenticated
  with check (sender_id = auth.uid() and public.can_message(conversation_id));

drop policy if exists "file reports" on public.reports;
create policy "file reports" on public.reports for insert to authenticated
  with check (reporter_id = auth.uid());

-- ---------- 5. Permissions (limit what the public key can do) ----------
revoke all on public.profiles, public.listings, public.blocks, public.conversations, public.messages, public.reports from anon, authenticated;
grant select on public.profiles, public.listings to anon, authenticated;
grant update (display_name, region, city) on public.profiles to authenticated;
grant insert, update on public.listings to authenticated;
grant select, insert, delete on public.blocks to authenticated;
grant select, insert on public.conversations to authenticated;
grant update (buyer_last_read, seller_last_read) on public.conversations to authenticated;
grant select, insert on public.messages to authenticated;
grant insert on public.reports to authenticated;

-- ---------- 6. Let people delete their own account ----------
create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  delete from auth.users where id = auth.uid();
end $$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ---------- 7. Photo storage ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-photos', 'listing-photos', true, 3145728, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 3145728,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "mk photos upload own folder" on storage.objects;
create policy "mk photos upload own folder" on storage.objects for insert to authenticated
  with check (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "mk photos see own folder" on storage.objects;
create policy "mk photos see own folder" on storage.objects for select to authenticated
  using (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "mk photos delete own folder" on storage.objects;
create policy "mk photos delete own folder" on storage.objects for delete to authenticated
  using (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
