// Deletes the calling user's account (PRD F4, §8.4): their Storage files,
// then the Auth user. Every user_* table and profiles reference auth.users
// with `on delete cascade`, so removing the user removes all their rows.
//
// verify_jwt stays on: only a signed-in user's access token gets here, and
// the user is looked up again from that token, never from the request body.
import { createClient } from 'npm:@supabase/supabase-js@2'

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })

function secretKey(): string {
  const keys = Deno.env.get('SUPABASE_SECRET_KEYS')
  if (keys) return JSON.parse(keys)['default']
  return Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
}

const admin = createClient(Deno.env.get('SUPABASE_URL')!, secretKey(), {
  auth: { persistSession: false, autoRefreshToken: false },
})

// Every file path under `prefix`, including in sub folders.
async function filesUnder(bucket: string, prefix: string): Promise<string[]> {
  const paths: string[] = []
  for (let offset = 0; ; offset += 1000) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, { limit: 1000, offset })
    if (error) throw error
    for (const entry of data) {
      const path = `${prefix}/${entry.name}`
      // Folders come back without an id.
      if (entry.id) paths.push(path)
      else paths.push(...(await filesUnder(bucket, path)))
    }
    if (data.length < 1000) return paths
  }
}

// Files live under `<user id>/` in each bucket (none exist yet; avatars in v2.0).
async function deleteFiles(userId: string) {
  const { data: buckets, error } = await admin.storage.listBuckets()
  if (error) throw error
  for (const bucket of buckets) {
    const paths = await filesUnder(bucket.id, userId)
    for (let i = 0; i < paths.length; i += 1000) {
      const { error } = await admin.storage.from(bucket.id).remove(paths.slice(i, i + 1000))
      if (error) throw error
    }
  }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json(405, { error: 'method_not_allowed' })
  const token = req.headers.get('Authorization')?.replace(/^Bearer /, '')
  if (!token) return json(401, { error: 'not_signed_in' })
  const { data, error } = await admin.auth.getUser(token)
  if (error || !data.user) return json(401, { error: 'not_signed_in' })
  const userId = data.user.id

  try {
    await deleteFiles(userId)
    const { error: deleteError } = await admin.auth.admin.deleteUser(userId)
    if (deleteError) throw deleteError
  } catch (e) {
    console.error('delete-account failed', userId, e)
    return json(500, { error: 'delete_failed' })
  }
  console.log('deleted account', userId)
  return json(200, { deleted: true })
})
