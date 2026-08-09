// Supabase Edge Function: dispatch-election-reminders
//
// Deploy with:
//   supabase functions deploy dispatch-election-reminders --no-verify-jwt
//
// Required server-side secrets:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, CRON_SECRET,
//   RESEND_API_KEY, NOTIFICATION_FROM_EMAIL
//
// This function intentionally sends only receipt-safe, election-status text.
// It never receives or sends candidate/contest choices.

import { createClient } from 'npm:@supabase/supabase-js@2'

const required = (name: string): string => {
  const value = Deno.env.get(name)
  if (!value) throw new Error(`Missing required secret: ${name}`)
  return value
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  })

const hoursUntil = (target: string) =>
  (new Date(target).getTime() - Date.now()) / (1000 * 60 * 60)

Deno.serve(async (request) => {
  try {
    const cronSecret = required('CRON_SECRET')
    if (request.headers.get('Authorization') !== `Bearer ${cronSecret}`) {
      return json({ error: 'Unauthorized' }, 401)
    }

    const supabase = createClient(
      required('SUPABASE_URL'),
      required('SUPABASE_SERVICE_ROLE_KEY'),
      { auth: { persistSession: false, autoRefreshToken: false } },
    )

    const { data: assignments, error: assignmentsError } = await supabase
      .from('ballot_assignments')
      .select('voter_id,election_id,election:elections!inner(title,starts_at,ends_at,status,is_public)')
      .eq('eligibility_status', 'eligible')
      .eq('submission_state', 'eligible')

    if (assignmentsError) throw assignmentsError

    let queued = 0
    for (const assignment of assignments ?? []) {
      const election = Array.isArray(assignment.election) ? assignment.election[0] : assignment.election
      if (!election || !election.is_public) continue

      const { data: preference } = await supabase
        .from('notification_preferences')
        .select('election_reminders')
        .eq('user_id', assignment.voter_id)
        .maybeSingle()
      if (preference?.election_reminders === false) continue

      const startHours = hoursUntil(election.starts_at)
      const endHours = hoursUntil(election.ends_at)
      let title: string | undefined
      let body: string | undefined
      let type: string | undefined
      let dedupeKey: string | undefined

      if (election.status === 'upcoming' && startHours >= 0 && startHours <= 24) {
        title = 'Assigned ballot opens soon'
        body = `${election.title} opens within the next 24 hours. Review official ballot information before voting opens.`
        type = 'election_reminder'
        dedupeKey = `opening:${assignment.voter_id}:${assignment.election_id}:${new Date(election.starts_at).toISOString().slice(0, 10)}`
      } else if (election.status === 'live' && endHours >= 0 && endHours <= 24) {
        title = 'Assigned ballot deadline approaching'
        body = `${election.title} closes within the next 24 hours. If you are eligible, review your ballot before the deadline.`
        type = 'election_reminder'
        dedupeKey = `closing:${assignment.voter_id}:${assignment.election_id}:${new Date(election.ends_at).toISOString().slice(0, 10)}`
      }

      if (!title || !body || !type || !dedupeKey) continue
      const { error } = await supabase.from('notifications').upsert(
        {
          user_id: assignment.voter_id,
          notification_type: type,
          title,
          body,
          action_route: `/ballot/${assignment.election_id}`,
          dedupe_key: dedupeKey,
        },
        { onConflict: 'dedupe_key', ignoreDuplicates: true },
      )
      if (error) throw error
      queued++
    }

    const resendKey = required('RESEND_API_KEY')
    const from = required('NOTIFICATION_FROM_EMAIL')
    const { data: pending, error: pendingError } = await supabase
      .from('notifications')
      .select('id,user_id,title,body')
      .is('delivered_at', null)
      .limit(100)
    if (pendingError) throw pendingError

    let delivered = 0
    for (const notification of pending ?? []) {
      const { data: userData, error: userError } = await supabase.auth.admin.getUserById(notification.user_id)
      if (userError || !userData.user?.email) continue

      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${resendKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from,
          to: [userData.user.email],
          subject: notification.title,
          text: notification.body,
        }),
      })
      if (!response.ok) continue

      const { error: updateError } = await supabase
        .from('notifications')
        .update({ delivered_at: new Date().toISOString() })
        .eq('id', notification.id)
      if (!updateError) delivered++
    }

    return json({ queued, delivered })
  } catch (error) {
    console.error(error)
    return json({ error: error instanceof Error ? error.message : 'Unknown error' }, 500)
  }
})
