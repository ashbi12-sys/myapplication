-- Read-only compatibility check for the Learning Hub Marketplace
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema='public' and table_name='listings'
order by ordinal_position;

select column_name, data_type, is_nullable
from information_schema.columns
where table_schema='public' and table_name='profiles'
order by ordinal_position;

select policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname='public' and tablename='listings'
order by policyname;
