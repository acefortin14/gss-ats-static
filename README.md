# GSS HR Talent Solutions Inc Applicant Tracking System

Static no-build ATS with Supabase backend and simple `config.js` setup.

## Features
- Multi-user login via Supabase Auth
- Roles: recruiter, recruiter_manager, admin
- Clients module
- Requirements / job openings module
- Candidate tracking and pipeline status
- Executive dashboard
- Individual recruiter performance
- Weekly and monthly reports
- CSV export

## Setup
1. Run `supabase_schema.sql` in Supabase SQL Editor.
2. Edit `config.js` and place your Supabase Project URL and anon/public/publishable key.
3. Upload files to GitHub.
4. Deploy on Vercel with Framework Preset: Other, no install command, no build command.
5. First user signs up, then update their role to admin in Supabase SQL Editor:

```sql
update public.profiles
set role = 'admin'
where email = 'your.email@gsshrsolutions.com';
```

Do not use your Supabase service_role key in `config.js`.
