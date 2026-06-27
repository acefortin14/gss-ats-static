# Deploy Now Steps for Current Vercel Error

The screenshot error says `npm error Exit handler never called` during `npm install`. Use this package because it has no npm dependencies.

## Option A - Recommended: create a fresh GitHub repo
1. Create a new GitHub repository named `gss-ats-static`.
2. Upload only the files from this folder:
   - `index.html`
   - `api/config.js`
   - `gss-logo.png`
   - `supabase_schema.sql`
   - `README.md`
3. Do not upload `package.json` or `package-lock.json`.
4. In Vercel, click Add New > Project.
5. Import the new repository.
6. Choose Framework Preset: Other.
7. Leave Install Command blank.
8. Leave Build Command blank.
9. Leave Output Directory blank or set it to `.`.
10. Add environment variables:
    - `VITE_SUPABASE_URL`
    - `VITE_SUPABASE_ANON_KEY`
11. Deploy.

## Option B - Fix the existing Vercel project
1. In GitHub, delete these files if present:
   - `package.json`
   - `package-lock.json`
   - `src` folder
   - `public` folder from the Vite version
2. Upload the files from this static package.
3. In Vercel Project Settings > Build and Development Settings:
   - Framework Preset: Other
   - Install Command: blank
   - Build Command: blank
   - Output Directory: `.`
4. Redeploy without cache.

## Important
Do not paste your password, OTP, GitHub token, Supabase service role key, or Vercel token into ChatGPT or GitHub.
