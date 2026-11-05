-- Marketplace database for Learning Hub (Supabase / Postgres)
-- Paste this whole file in Supabase > SQL Editor > New query > Run.

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  title text not null check (char_length(title) between 3 and 80),
  description text check (char_length(description) <= 500),
  price numeric not null default 0 check (price >= 0 and price <= 100000),
  category text not null check (char_length(category) <= 30),
  condition text not null check (char_length(condition) <= 20),
  emoji text not null default '🛍️' check (char_length(emoji) <= 8),
  seller text not null check (char_length(seller) between 2 and 40),
  section text check (char_length(section) <= 40),
  contact text not null check (char_length(contact) between 2 and 100),
  meetup text check (char_length(meetup) <= 80),
  status text not null default 'available' check (status in ('available','sold','removed'))
);

alter table public.listings enable row level security;

-- Visitors can read listings that are not removed.
create policy "read listings" on public.listings
  for select using (status <> 'removed');

-- Visitors can add a new listing (always starts as available).
create policy "add listings" on public.listings
  for insert with check (status = 'available');

-- Visitors can only change the status column (sold / available / removed).
create policy "change status" on public.listings
  for update using (true) with check (status in ('available','sold','removed'));

-- Limit what the public key is allowed to do.
revoke all on public.listings from anon;
grant select, insert on public.listings to anon;
grant update (status) on public.listings to anon;
