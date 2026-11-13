create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  full_name text not null
);
grant select, insert, update on public.profiles to authenticated;
