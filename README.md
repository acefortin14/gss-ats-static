# GSS ATS - Static Vercel Version (No npm Build)

This version avoids the Vercel `npm install` error because it does not use package.json, npm, Vite, or a build step.

## Included
- `index.html` - complete ATS web application
- `api/config.js` - Vercel serverless config endpoint that reads environment variables
- `gss-logo.png` - company logo
- `supabase_schema.sql` - database schema, roles, clients, requirements and reports

## Supabase setup
1. Create a Supabase project.
2. Go to SQL Editor.
3. Open `supabase_schema.sql`.
4. Copy all SQL and run it.
5. Get your Project URL and anon/publishable key.

## Vercel environment variables
Add exactly these two variables under Project Settings > Environment Variables:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

Use your actual Supabase Project URL and anon/publishable public key. Do not use the service role key.

## Vercel deployment settings
Use this static version as a fresh Vercel project or update the current project settings:

- Framework Preset: Other
- Install Command: leave blank
- Build Command: leave blank
- Output Directory: leave blank or use `.`

If Vercel still runs npm, delete any old `package.json` and `package-lock.json` from your GitHub repository or create a new repository using only the files from this static package.

## First admin account
1. Open the live ATS.
2. Sign up your admin user.
3. In Supabase SQL Editor, run:

```sql
update public.profiles
set role = 'admin'
where email = 'your.email@gsshrsolutions.com';
```

Then refresh the ATS and open User Management.

## Roles
- `recruiter` - add candidates and view own pipeline
- `recruiter_manager` - manage clients and requirements, view team reports
- `admin` - full access including user management
