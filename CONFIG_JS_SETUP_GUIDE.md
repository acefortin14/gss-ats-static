# GSS ATS Config.js Setup Guide

This version does not need Vercel Environment Variables and does not need `/api/config`.
It reads Supabase settings directly from `config.js`.

## Files to upload to GitHub
Upload or replace these files in the main/root area of your GitHub repository:

- `index.html`
- `config.js`
- `gss-logo.png`
- `supabase_schema.sql`
- `README.md`
- `CONFIG_JS_SETUP_GUIDE.md`

Do not upload `package.json`, `package-lock.json`, `src`, or `public` from the older Vite version.

## Edit config.js in GitHub
Open `config.js` and replace these placeholders:

```js
window.ATS_CONFIG = {
  supabaseUrl: "https://your-project-id.supabase.co",
  supabaseAnonKey: "your_supabase_anon_or_publishable_key"
};
```

Use values from Supabase:

- Project URL
- anon public key / publishable key

Important: Do NOT use the Supabase `service_role` key.

## Vercel settings
Use:

- Framework Preset: Other
- Install Command: blank
- Build Command: blank
- Output Directory: blank or `.`

After committing changes in GitHub, Vercel should redeploy automatically.
If it does not, go to Vercel > Deployments > Redeploy without cache.

## Test
Open your live Vercel URL.
The message about missing ATS configuration should disappear after `config.js` has the correct Supabase values.
