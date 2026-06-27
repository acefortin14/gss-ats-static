Set up the @supabase/server SDK in this project.

Install it:
npm install @supabase/server

It reads these environment variables (copy the real values from the Supabase dashboard's Connect dialog — never commit the secret key):
- SUPABASE_URL
- SUPABASE_PUBLISHABLE_KEY
- SUPABASE_SECRET_KEY
- SUPABASE_JWKS_URL (used to verify user JWTs)

Create request handlers with `withSupabase` from "@supabase/server". It validates auth and provides an RLS-scoped client (`ctx.supabase`) and an admin client that bypasses RLS (`ctx.supabaseAdmin`). Example:

import { withSupabase } from "@supabase/server"

export default {
  fetch: withSupabase({ auth: "user" }, async (_req, ctx) => {
    const { data } = await ctx.supabase.from("todos").select()
    return Response.json(data)
  }),
}

Auth modes: "user" (valid JWT), "publishable" (publishable key), "secret" (secret key), "none". On Supabase Edge Functions these env vars are injected automatically; for non-"user" auth modes, set `verify_jwt = false` for the function in supabase/config.toml.
