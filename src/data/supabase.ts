import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';

// The preview intentionally has no network client. Supply public values in .env to enable it.
const url = process.env.EXPO_PUBLIC_SUPABASE_URL;
const key = process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
export const supabase = url && key ? createClient(url, key, {
  auth: { storage: AsyncStorage, autoRefreshToken: true, persistSession: true, detectSessionInUrl: false }
}) : null;

/** Submits no voter identity with choices; the database RPC enforces assignment, MFA and one ballot. */
export async function submitBallot(electionId: string, choices: { contest_id: string; candidate_id: string }[]) {
  if (!supabase) throw new Error('Supabase is not configured. Product preview cannot submit a real ballot.');
  const { data, error } = await supabase.rpc('submit_ballot', {
    p_election_id: electionId,
    p_choices: choices,
  });
  if (error) throw error;

  const row = Array.isArray(data) ? data[0] : data;
  if (!row?.receipt_code || !row?.submitted_at) {
    throw new Error('The authority did not return a submission receipt. Check ballot status before retrying.');
  }
  return row as { receipt_code: string; submitted_at: string };
}
