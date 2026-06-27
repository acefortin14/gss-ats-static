-- GSS HR Talent Solutions Inc - Applicant Tracking System Schema
-- Run this full script in Supabase SQL Editor.
-- It creates multi-user login profiles, role-based access, clients, requirements, candidates, dashboards, weekly reports, and monthly reports.

create extension if not exists "pgcrypto";

-- 1. USER PROFILES AND ROLES
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'recruiter',
  team text default 'Recruitment',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists full_name text;
alter table public.profiles add column if not exists role text not null default 'recruiter';
alter table public.profiles add column if not exists team text default 'Recruitment';
alter table public.profiles add column if not exists is_active boolean not null default true;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

update public.profiles set role = 'recruiter_manager' where role = 'manager';

do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'profiles'
      and constraint_name = 'profiles_role_check'
  ) then
    alter table public.profiles drop constraint profiles_role_check;
  end if;
end $$;

alter table public.profiles
  add constraint profiles_role_check check (role in ('admin', 'recruiter_manager', 'recruiter'));

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    'recruiter'
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(public.profiles.full_name, excluded.full_name),
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles
  where id = auth.uid()
    and is_active = true
  limit 1;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() = 'admin', false);
$$;

create or replace function public.is_recruiter_manager_or_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() in ('admin', 'recruiter_manager'), false);
$$;

-- 2. CLIENTS AND JOB REQUIREMENTS
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  industry text,
  contact_person text,
  contact_email text,
  status text not null default 'Active',
  priority text default 'Medium',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.clients add column if not exists industry text;
alter table public.clients add column if not exists contact_person text;
alter table public.clients add column if not exists contact_email text;
alter table public.clients add column if not exists status text not null default 'Active';
alter table public.clients add column if not exists priority text default 'Medium';
alter table public.clients add column if not exists notes text;
alter table public.clients add column if not exists created_at timestamptz not null default now();
alter table public.clients add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'clients'
      and constraint_name = 'clients_status_check'
  ) then
    alter table public.clients drop constraint clients_status_check;
  end if;
  if exists (
    select 1 from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'clients'
      and constraint_name = 'clients_priority_check'
  ) then
    alter table public.clients drop constraint clients_priority_check;
  end if;
end $$;

alter table public.clients add constraint clients_status_check check (status in ('Active', 'Inactive'));
alter table public.clients add constraint clients_priority_check check (priority in ('High', 'Medium', 'Low'));

create table if not exists public.positions (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  title text not null,
  department text,
  openings integer not null default 1,
  salary_min numeric(12,2),
  salary_max numeric(12,2),
  work_setup text default 'Hybrid',
  location text,
  employment_type text default 'Full-time',
  status text not null default 'Open',
  jd_summary text,
  must_have_skills text,
  nice_to_have_skills text,
  target_start_date date,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.positions add column if not exists department text;
alter table public.positions add column if not exists openings integer not null default 1;
alter table public.positions add column if not exists salary_min numeric(12,2);
alter table public.positions add column if not exists salary_max numeric(12,2);
alter table public.positions add column if not exists work_setup text default 'Hybrid';
alter table public.positions add column if not exists location text;
alter table public.positions add column if not exists employment_type text default 'Full-time';
alter table public.positions add column if not exists status text not null default 'Open';
alter table public.positions add column if not exists jd_summary text;
alter table public.positions add column if not exists must_have_skills text;
alter table public.positions add column if not exists nice_to_have_skills text;
alter table public.positions add column if not exists target_start_date date;
alter table public.positions add column if not exists created_by uuid references public.profiles(id);
alter table public.positions add column if not exists created_at timestamptz not null default now();
alter table public.positions add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'positions'
      and constraint_name = 'positions_status_check'
  ) then
    alter table public.positions drop constraint positions_status_check;
  end if;
  if exists (
    select 1 from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'positions'
      and constraint_name = 'positions_openings_check'
  ) then
    alter table public.positions drop constraint positions_openings_check;
  end if;
end $$;

alter table public.positions add constraint positions_status_check check (status in ('Open', 'On Hold', 'Closed'));
alter table public.positions add constraint positions_openings_check check (openings >= 0);

create unique index if not exists positions_client_title_unique_idx on public.positions(client_id, title);

-- 3. CANDIDATES AND APPLICATION TRACKING
create table if not exists public.candidates (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text,
  phone text,
  source text,
  skills text,
  highest_education text,
  certifications text,
  overall_experience_years numeric(5,2),
  current_salary numeric(12,2),
  asking_salary numeric(12,2),
  availability text,
  current_location text,
  pending_applications text,
  reason_for_exploring text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.candidates add column if not exists source text;
alter table public.candidates add column if not exists skills text;
alter table public.candidates add column if not exists highest_education text;
alter table public.candidates add column if not exists certifications text;
alter table public.candidates add column if not exists overall_experience_years numeric(5,2);
alter table public.candidates add column if not exists current_salary numeric(12,2);
alter table public.candidates add column if not exists asking_salary numeric(12,2);
alter table public.candidates add column if not exists availability text;
alter table public.candidates add column if not exists current_location text;
alter table public.candidates add column if not exists pending_applications text;
alter table public.candidates add column if not exists reason_for_exploring text;
alter table public.candidates add column if not exists created_by uuid references public.profiles(id);
alter table public.candidates add column if not exists created_at timestamptz not null default now();
alter table public.candidates add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'candidates'
      and constraint_name = 'candidates_source_check'
  ) then
    alter table public.candidates drop constraint candidates_source_check;
  end if;
end $$;

alter table public.candidates add constraint candidates_source_check check (source in ('Referral', 'Job Portal', 'Agency', 'Direct', 'LinkedIn', 'Facebook', 'Other'));

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references public.candidates(id) on delete cascade,
  position_id uuid not null references public.positions(id) on delete cascade,
  recruiter_id uuid references public.profiles(id),
  status text not null default 'Sourced',
  stage text default 'Sourced',
  english_rating integer,
  relevant_experience_years numeric(5,2),
  interview_date timestamptz,
  client_feedback text,
  remarks text,
  result text,
  endorsed_at timestamptz,
  offer_amount numeric(12,2),
  start_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (candidate_id, position_id)
);

alter table public.applications add column if not exists stage text default 'Sourced';
alter table public.applications add column if not exists english_rating integer;
alter table public.applications add column if not exists relevant_experience_years numeric(5,2);
alter table public.applications add column if not exists interview_date timestamptz;
alter table public.applications add column if not exists client_feedback text;
alter table public.applications add column if not exists remarks text;
alter table public.applications add column if not exists result text;
alter table public.applications add column if not exists endorsed_at timestamptz;
alter table public.applications add column if not exists offer_amount numeric(12,2);
alter table public.applications add column if not exists start_date date;
alter table public.applications add column if not exists created_at timestamptz not null default now();
alter table public.applications add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'applications'
      and constraint_name = 'applications_status_check'
  ) then
    alter table public.applications drop constraint applications_status_check;
  end if;
  if exists (
    select 1 from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'applications'
      and constraint_name = 'applications_english_rating_check'
  ) then
    alter table public.applications drop constraint applications_english_rating_check;
  end if;
end $$;

alter table public.applications add constraint applications_status_check check (status in (
  'Sourced', 'Submitted', 'Client Review', 'L1 Interview', 'L2 Interview', 'Final Interview', 'Offered', 'Hired', 'Rejected', 'Withdrawn'
));
alter table public.applications add constraint applications_english_rating_check check (english_rating between 1 and 10);

create table if not exists public.application_status_history (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  old_status text,
  new_status text not null,
  changed_by uuid references public.profiles(id),
  changed_at timestamptz not null default now()
);

create table if not exists public.recruitment_targets (
  id uuid primary key default gen_random_uuid(),
  role_band text not null,
  recruiter_level text not null,
  salary_min numeric(12,2),
  salary_max numeric(12,2),
  monthly_cv_target integer not null default 80,
  monthly_shortlist_target integer not null default 64,
  monthly_interview_target integer not null default 32,
  monthly_offer_target integer not null default 4,
  monthly_hire_target integer not null default 2,
  monthly_revenue_target numeric(14,2) default 0,
  created_at timestamptz not null default now()
);

-- 4. TRIGGERS
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();

drop trigger if exists clients_set_updated_at on public.clients;
create trigger clients_set_updated_at before update on public.clients for each row execute function public.set_updated_at();

drop trigger if exists positions_set_updated_at on public.positions;
create trigger positions_set_updated_at before update on public.positions for each row execute function public.set_updated_at();

drop trigger if exists candidates_set_updated_at on public.candidates;
create trigger candidates_set_updated_at before update on public.candidates for each row execute function public.set_updated_at();

drop trigger if exists applications_set_updated_at on public.applications;
create trigger applications_set_updated_at before update on public.applications for each row execute function public.set_updated_at();

create or replace function public.log_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.application_status_history (application_id, old_status, new_status, changed_by)
    values (new.id, null, new.status, auth.uid());
  elsif old.status is distinct from new.status then
    insert into public.application_status_history (application_id, old_status, new_status, changed_by)
    values (new.id, old.status, new.status, auth.uid());
  end if;
  return new;
end;
$$;

drop trigger if exists applications_log_status_change on public.applications;
create trigger applications_log_status_change
after insert or update of status on public.applications
for each row execute function public.log_status_change();

-- 5. ROW LEVEL SECURITY
alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.positions enable row level security;
alter table public.candidates enable row level security;
alter table public.applications enable row level security;
alter table public.application_status_history enable row level security;
alter table public.recruitment_targets enable row level security;

-- Drop old policies before recreating, so the script can be rerun.
drop policy if exists profiles_read_authenticated on public.profiles;
drop policy if exists profiles_update_own_or_admin on public.profiles;
drop policy if exists clients_read_authenticated on public.clients;
drop policy if exists clients_insert_manager_admin on public.clients;
drop policy if exists clients_update_manager_admin on public.clients;
drop policy if exists positions_read_authenticated on public.positions;
drop policy if exists positions_insert_manager_admin on public.positions;
drop policy if exists positions_update_manager_admin on public.positions;
drop policy if exists candidates_read_role_based on public.candidates;
drop policy if exists candidates_insert_own on public.candidates;
drop policy if exists candidates_update_owner_or_manager on public.candidates;
drop policy if exists applications_read_role_based on public.applications;
drop policy if exists applications_insert_recruiter on public.applications;
drop policy if exists applications_update_recruiter_or_manager on public.applications;
drop policy if exists status_history_read_role_based on public.application_status_history;
drop policy if exists status_history_insert_authenticated on public.application_status_history;
drop policy if exists targets_read_authenticated on public.recruitment_targets;
drop policy if exists targets_manage_manager_admin on public.recruitment_targets;

-- Compatibility cleanup for earlier version policy names.
drop policy if exists profiles_update_own_or_manager on public.profiles;
drop policy if exists clients_insert_authenticated on public.clients;
drop policy if exists clients_update_manager on public.clients;
drop policy if exists positions_insert_authenticated on public.positions;
drop policy if exists positions_update_owner_or_manager on public.positions;
drop policy if exists candidates_read_authenticated on public.candidates;
drop policy if exists applications_read_authenticated on public.applications;
drop policy if exists status_history_read_authenticated on public.application_status_history;
drop policy if exists targets_manage_manager on public.recruitment_targets;

-- Profiles: everyone authenticated can see names/roles for reporting; only admin can manage roles.
create policy profiles_read_authenticated on public.profiles
for select to authenticated using (true);

create policy profiles_update_own_or_admin on public.profiles
for update to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

-- Clients and requirements: recruiters can read; admin and recruiter manager can create/update.
create policy clients_read_authenticated on public.clients for select to authenticated using (true);
create policy clients_insert_manager_admin on public.clients for insert to authenticated with check (public.is_recruiter_manager_or_admin());
create policy clients_update_manager_admin on public.clients for update to authenticated using (public.is_recruiter_manager_or_admin()) with check (public.is_recruiter_manager_or_admin());

create policy positions_read_authenticated on public.positions for select to authenticated using (true);
create policy positions_insert_manager_admin on public.positions for insert to authenticated with check (public.is_recruiter_manager_or_admin());
create policy positions_update_manager_admin on public.positions for update to authenticated using (public.is_recruiter_manager_or_admin()) with check (public.is_recruiter_manager_or_admin());

-- Candidates/applications: recruiter sees own data; recruiter manager and admin see all team data.
create policy candidates_read_role_based on public.candidates
for select to authenticated
using (created_by = auth.uid() or public.is_recruiter_manager_or_admin());

create policy candidates_insert_own on public.candidates
for insert to authenticated
with check (created_by = auth.uid());

create policy candidates_update_owner_or_manager on public.candidates
for update to authenticated
using (created_by = auth.uid() or public.is_recruiter_manager_or_admin())
with check (created_by = auth.uid() or public.is_recruiter_manager_or_admin());

create policy applications_read_role_based on public.applications
for select to authenticated
using (recruiter_id = auth.uid() or public.is_recruiter_manager_or_admin());

create policy applications_insert_recruiter on public.applications
for insert to authenticated
with check (recruiter_id = auth.uid() or public.is_recruiter_manager_or_admin());

create policy applications_update_recruiter_or_manager on public.applications
for update to authenticated
using (recruiter_id = auth.uid() or public.is_recruiter_manager_or_admin())
with check (recruiter_id = auth.uid() or public.is_recruiter_manager_or_admin());

create policy status_history_read_role_based on public.application_status_history
for select to authenticated
using (
  public.is_recruiter_manager_or_admin()
  or exists (
    select 1 from public.applications a
    where a.id = application_status_history.application_id
      and a.recruiter_id = auth.uid()
  )
);

create policy status_history_insert_authenticated on public.application_status_history
for insert to authenticated with check (true);

create policy targets_read_authenticated on public.recruitment_targets for select to authenticated using (true);
create policy targets_manage_manager_admin on public.recruitment_targets for all to authenticated using (public.is_recruiter_manager_or_admin()) with check (public.is_recruiter_manager_or_admin());

-- 6. REPORTING VIEWS
create or replace view public.vw_applications_detailed
with (security_invoker = on)
as
select
  a.id as application_id,
  a.created_at,
  a.updated_at,
  date_trunc('week', a.created_at)::date as week_start,
  date_trunc('month', a.created_at)::date as month_start,
  p.full_name as recruiter_name,
  p.email as recruiter_email,
  p.role as recruiter_role,
  c.full_name as candidate_name,
  c.email,
  c.phone,
  c.source,
  c.skills,
  c.highest_education,
  c.certifications,
  c.overall_experience_years,
  c.current_salary,
  c.asking_salary,
  c.availability,
  c.current_location,
  cl.name as client_name,
  cl.industry as client_industry,
  cl.priority as client_priority,
  pos.title as position_title,
  pos.department,
  pos.openings,
  pos.salary_min,
  pos.salary_max,
  pos.work_setup,
  pos.location,
  pos.employment_type,
  pos.jd_summary,
  pos.must_have_skills,
  pos.nice_to_have_skills,
  a.status,
  a.stage,
  a.english_rating,
  a.relevant_experience_years,
  a.interview_date,
  a.client_feedback,
  a.remarks,
  a.result,
  a.offer_amount,
  a.start_date
from public.applications a
left join public.candidates c on c.id = a.candidate_id
left join public.positions pos on pos.id = a.position_id
left join public.clients cl on cl.id = pos.client_id
left join public.profiles p on p.id = a.recruiter_id;

create or replace view public.vw_individual_recruiter_report
with (security_invoker = on)
as
select
  p.id as recruiter_id,
  coalesce(p.full_name, 'Unassigned') as recruiter_name,
  date_trunc('month', a.created_at)::date as month_start,
  count(*) as total_applications,
  count(*) filter (where a.status = 'Sourced') as sourced,
  count(*) filter (where a.status in ('Submitted', 'Client Review')) as submitted,
  count(*) filter (where a.status in ('L1 Interview', 'L2 Interview', 'Final Interview')) as interviews,
  count(*) filter (where a.status = 'Offered') as offers,
  count(*) filter (where a.status = 'Hired') as hires,
  count(*) filter (where a.status = 'Rejected') as rejected,
  round((count(*) filter (where a.status = 'Hired')::numeric / nullif(count(*),0)) * 100, 2) as hire_rate_percent
from public.applications a
left join public.profiles p on p.id = a.recruiter_id
group by p.id, p.full_name, date_trunc('month', a.created_at);

create or replace view public.vw_weekly_report
with (security_invoker = on)
as
select
  date_trunc('week', a.created_at)::date as week_start,
  cl.name as client_name,
  pos.title as position_title,
  p.full_name as recruiter_name,
  count(*) as total_candidates,
  count(*) filter (where a.status = 'Sourced') as sourced,
  count(*) filter (where a.status in ('Submitted', 'Client Review')) as submitted,
  count(*) filter (where a.status in ('L1 Interview', 'L2 Interview', 'Final Interview')) as interviews,
  count(*) filter (where a.status = 'Offered') as offers,
  count(*) filter (where a.status = 'Hired') as hires,
  count(*) filter (where a.status = 'Rejected') as rejected
from public.applications a
left join public.positions pos on pos.id = a.position_id
left join public.clients cl on cl.id = pos.client_id
left join public.profiles p on p.id = a.recruiter_id
group by date_trunc('week', a.created_at), cl.name, pos.title, p.full_name;

create or replace view public.vw_monthly_report
with (security_invoker = on)
as
select
  date_trunc('month', a.created_at)::date as month_start,
  cl.name as client_name,
  pos.title as position_title,
  p.full_name as recruiter_name,
  count(*) as total_candidates,
  count(*) filter (where a.status = 'Sourced') as sourced,
  count(*) filter (where a.status in ('Submitted', 'Client Review')) as submitted,
  count(*) filter (where a.status in ('L1 Interview', 'L2 Interview', 'Final Interview')) as interviews,
  count(*) filter (where a.status = 'Offered') as offers,
  count(*) filter (where a.status = 'Hired') as hires,
  count(*) filter (where a.status = 'Rejected') as rejected
from public.applications a
left join public.positions pos on pos.id = a.position_id
left join public.clients cl on cl.id = pos.client_id
left join public.profiles p on p.id = a.recruiter_id
group by date_trunc('month', a.created_at), cl.name, pos.title, p.full_name;

create or replace view public.vw_client_requirement_dashboard
with (security_invoker = on)
as
select
  cl.name as client_name,
  count(distinct pos.id) as total_requirements,
  sum(pos.openings) filter (where pos.status = 'Open') as open_headcount,
  count(a.id) as total_candidates,
  count(a.id) filter (where a.status in ('Submitted', 'Client Review')) as submitted,
  count(a.id) filter (where a.status in ('L1 Interview', 'L2 Interview', 'Final Interview')) as interviews,
  count(a.id) filter (where a.status = 'Offered') as offers,
  count(a.id) filter (where a.status = 'Hired') as hires
from public.clients cl
left join public.positions pos on pos.client_id = cl.id
left join public.applications a on a.position_id = pos.id
group by cl.name;

-- 7. PERFORMANCE INDEXES
create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_clients_status on public.clients(status);
create index if not exists idx_positions_client_id on public.positions(client_id);
create index if not exists idx_positions_status on public.positions(status);
create index if not exists idx_applications_created_at on public.applications(created_at desc);
create index if not exists idx_applications_recruiter_id on public.applications(recruiter_id);
create index if not exists idx_applications_status on public.applications(status);
create index if not exists idx_candidates_full_name on public.candidates using gin (to_tsvector('simple', full_name));

-- 8. SEED CLIENTS
insert into public.clients (name, industry, status, priority, notes)
values
  ('IOPEX', 'BPO / Shared Services', 'Active', 'High', 'Priority client for ServiceNow, cybersecurity, sales, and shared services hiring.'),
  ('ITG', 'IT Solutions', 'Active', 'High', 'Business Development Officer hiring; IT solutions and services background.'),
  ('Wipro', 'Technology Services', 'Active', 'High', 'System Engineer L4, Windows Server Admin, Project Lead, and Data Engineer hiring.'),
  ('PLDT Global', 'Telecommunications', 'Active', 'High', 'Security operations, red team, and network/security roles.'),
  ('KPMG', 'Professional Services', 'Active', 'Medium', 'Procurement and Microsoft roles.'),
  ('Pro Integrate', 'IT Consulting', 'Active', 'High', 'AI/ML, RPA, enterprise apps, cloud, data analytics, and shared services campaign.'),
  ('WSP', 'Engineering / Consulting', 'Active', 'Medium', 'MSA and onboarding coordination.'),
  ('Accenture', 'IT Services / Consulting', 'Active', 'Medium', 'Future requirements and tracking.')
on conflict (name) do update set
  industry = excluded.industry,
  status = excluded.status,
  priority = excluded.priority,
  notes = excluded.notes,
  updated_at = now();

-- 9. SEED REQUIREMENTS / JOB ORDERS
insert into public.positions (client_id, title, department, openings, salary_min, salary_max, work_setup, location, employment_type, status, jd_summary, must_have_skills)
select c.id, x.title, x.department, x.openings, x.salary_min, x.salary_max, x.work_setup, x.location, x.employment_type, x.status, x.jd_summary, x.must_have_skills
from (
  values
    ('IOPEX', 'ServiceNow Support Specialist', 'ITSM', 5, 60000::numeric, 100000::numeric, 'Hybrid', 'Alabang / BGC', 'Full-time', 'Open', 'ServiceNow support role for ITSM operations and production support.', 'ServiceNow, ITSM, troubleshooting, support operations'),
    ('IOPEX', 'ServiceNow Dispatch', 'ITSM', 2, 30000::numeric, 35000::numeric, 'Onsite', 'BGC', 'Full-time', 'Open', 'Night-shift ServiceNow dispatch support role.', 'ServiceNow, dispatch, ticket handling, night shift'),
    ('IOPEX', 'Business Development Lead - Cybersecurity', 'Sales', 2, 35000::numeric, 45000::numeric, 'Hybrid', 'BGC / Alabang', 'Full-time', 'Open', 'Business development role for cybersecurity services.', 'Business development, cybersecurity, B2B sales'),
    ('IOPEX', 'Business Development Manager - Cybersecurity', 'Sales', 1, 90000::numeric, 100000::numeric, 'Hybrid', 'BGC / Alabang', 'Full-time', 'Open', 'Manager-level business development role for cybersecurity services.', 'BDM, cybersecurity, client acquisition, B2B sales'),
    ('IOPEX', 'Accounts Receivable Specialist - German', 'Finance', 10, 80000::numeric, 100000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Accounts receivable role requiring German language and NetSuite exposure.', 'German language, accounts receivable, NetSuite'),
    ('IOPEX', 'Multi-Skill Tech Specialist', 'Technical Support', 1, 20000::numeric, 25000::numeric, 'Onsite', 'Metro Manila', 'Full-time', 'Open', 'Technical support role with UPS or related equipment experience.', 'Technical support, UPS, hardware support'),
    ('ITG', 'Business Development Officer', 'Sales', 9, 50000::numeric, 80000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Business Development Officer for IT solutions and services.', 'Business development, IT solutions, B2B sales, client management'),
    ('Wipro', 'System Engineer L4', 'Infrastructure', 5, 0::numeric, 0::numeric, 'Hybrid', 'Metro Manila', 'Contract', 'Open', 'System Engineer L4 requirement for infrastructure operations.', 'System engineering, infrastructure, troubleshooting'),
    ('Wipro', 'Lead Administrator L1 - Windows Server Admin', 'Infrastructure', 1, 0::numeric, 0::numeric, 'Hybrid', 'Metro Manila', 'Contract', 'Open', 'Windows Server Administrator contract role requiring 5 to 8 years experience.', 'Windows Server, administration, infrastructure, 5-8 years experience'),
    ('PLDT Global', 'Security Operation Lead', 'Cybersecurity', 1, 150000::numeric, 180000::numeric, 'Hybrid', 'Makati', 'Full-time', 'Open', 'Security operations lead for incident response, SIEM, and security operations.', 'SOC leadership, SIEM, incident response, Cisco firewalls, WAF, AWS'),
    ('PLDT Global', 'Red Team Specialist', 'Cybersecurity', 1, 0::numeric, 0::numeric, 'Hybrid', 'Makati', 'Full-time', 'Open', 'Red team specialist requirement for offensive security operations.', 'Red team, penetration testing, vulnerability assessment'),
    ('KPMG', 'Procurement Specialist', 'Procurement', 1, 0::numeric, 0::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Procurement role for professional services client.', 'Procurement, vendor management, sourcing'),
    ('KPMG', 'Microsoft Dynamics Developer', 'Technology', 2, 100000::numeric, 130000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Microsoft Dynamics developer role.', 'MS Dynamics, development, integration'),
    ('Pro Integrate', 'Data Engineer', 'Data & Analytics', 2, 100000::numeric, 145000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Data Engineer for shared services client requirements.', 'Data engineering, SQL, cloud data platforms'),
    ('Pro Integrate', 'Workday Compensation and Benefits Specialist', 'Workday', 1, 100000::numeric, 130000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Workday Compensation and Benefits specialist.', 'Workday, compensation, benefits, configuration'),
    ('Pro Integrate', 'Portfolio Analyst', 'PMO', 1, 100000::numeric, 145000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Portfolio analyst role for shared services.', 'Portfolio management, reporting, analysis'),
    ('Pro Integrate', 'Application Engineer - HR ServiceNow', 'Applications', 1, 100000::numeric, 130000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Application Engineer for HR ServiceNow.', 'ServiceNow HR, application support, configuration'),
    ('Pro Integrate', 'Monitoring / Observability / Event Management Architect', 'Architecture', 1, 200000::numeric, 250000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Architecture role for monitoring, observability, and event management.', 'Monitoring, observability, event management, architecture'),
    ('Pro Integrate', 'SAP Security Specialist', 'SAP', 1, 100000::numeric, 130000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'SAP Security role for shared services.', 'SAP security, roles, authorizations'),
    ('Pro Integrate', 'Site Reliability Engineer', 'SRE', 1, 100000::numeric, 110000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Site Reliability Engineer requirement.', 'SRE, monitoring, incident response, automation'),
    ('Pro Integrate', 'Application Engineer - Retail', 'Applications', 1, 100000::numeric, 110000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Application Engineer for retail systems.', 'Application support, retail systems, troubleshooting'),
    ('Pro Integrate', 'SCM P2P IT System Support Analyst', 'Supply Chain', 1, 100000::numeric, 130000::numeric, 'Hybrid', 'Metro Manila', 'Full-time', 'Open', 'Supply chain P2P IT support analyst.', 'SCM, P2P, IT system support')
) as x(client_name, title, department, openings, salary_min, salary_max, work_setup, location, employment_type, status, jd_summary, must_have_skills)
join public.clients c on c.name = x.client_name
on conflict (client_id, title) do update set
  department = excluded.department,
  openings = excluded.openings,
  salary_min = excluded.salary_min,
  salary_max = excluded.salary_max,
  work_setup = excluded.work_setup,
  location = excluded.location,
  employment_type = excluded.employment_type,
  status = excluded.status,
  jd_summary = excluded.jd_summary,
  must_have_skills = excluded.must_have_skills,
  updated_at = now();

-- 10. RECRUITMENT KPI TARGETS
insert into public.recruitment_targets (
  role_band,
  recruiter_level,
  salary_min,
  salary_max,
  monthly_cv_target,
  monthly_shortlist_target,
  monthly_interview_target,
  monthly_offer_target,
  monthly_hire_target,
  monthly_revenue_target
)
values
  ('Junior', 'Junior Recruiter', 25000, 30000, 70, 50, 20, 3, 1, 250000),
  ('Mid', 'Mid-Level Recruiter', 35000, 45000, 80, 64, 30, 4, 2, 450000),
  ('Senior', 'Senior Recruiter', 46000, 60000, 95, 76, 38, 5, 3, 650000),
  ('RDM', 'Recruitment Delivery Manager', 61000, 75000, 120, 96, 48, 7, 4, 900000)
on conflict do nothing;

-- 11. MAKE YOUR FIRST ACCOUNT ADMIN AFTER SIGNUP
-- After your first user signs up, run this and replace the email:
-- update public.profiles set role = 'admin' where email = 'your.email@gsshrsolutions.com';
-- Available roles: recruiter, recruiter_manager, admin
