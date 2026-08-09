-- Fictional development-only data. Do not use these people, places, or records
-- as an official election fixture.

insert into public.elections (
  id, title, description, jurisdiction, status, starts_at, ends_at,
  registered_voters, is_public, results_visible, requires_mfa
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'Riverside mayoral election',
    'A fictional local election used to exercise the CivicVote interface.',
    'Riverside Borough',
    'live',
    now() - interval '5 hours',
    now() + interval '1 day 7 hours',
    48260,
    true,
    true,
    false
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'Neighbourhood parks referendum',
    'A fictional local referendum used for development.',
    'Riverside Borough',
    'upcoming',
    now() + interval '18 days',
    now() + interval '20 days',
    48260,
    true,
    false,
    false
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'Community library board',
    'A fictional completed election used to test published result views.',
    'Riverside Borough',
    'completed',
    now() - interval '31 days',
    now() - interval '29 days',
    48260,
    true,
    true,
    false
  )
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  jurisdiction = excluded.jurisdiction,
  status = excluded.status,
  starts_at = excluded.starts_at,
  ends_at = excluded.ends_at,
  registered_voters = excluded.registered_voters,
  is_public = excluded.is_public,
  results_visible = excluded.results_visible,
  requires_mfa = excluded.requires_mfa;

insert into public.contests (
  id, election_id, title, instructions, contest_type, seats, position, is_required
)
values
  (
    '40000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Mayor of Riverside',
    'Choose one fictional mayoral candidate.',
    'single_choice',
    1,
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000001',
    'Safer streets proposal',
    'Choose one fictional mobility proposal.',
    'referendum',
    1,
    2,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'Fund green corridors?',
    'Choose yes or no in this fictional referendum.',
    'referendum',
    1,
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000003',
    'Library board representative',
    'Choose one fictional library board candidate.',
    'single_choice',
    1,
    1,
    true
  )
on conflict (id) do update set
  title = excluded.title,
  instructions = excluded.instructions,
  contest_type = excluded.contest_type,
  seats = excluded.seats,
  position = excluded.position,
  is_required = excluded.is_required;

insert into public.candidates (
  id, election_id, contest_id, full_name, party_name, party_abbreviation,
  manifesto, accent_color, ballot_position
)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'Amara Okafor', 'Forward Riverside', 'FR',
    'Expand reliable bus routes, publish quarterly spending updates, and protect neighbourhood services through participatory budgeting.',
    '#1D5FD0', 1
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'Daniel Reyes', 'Civic Independent', 'CI',
    'Make planning decisions easier to follow, support small local businesses, and invest in safe walking and cycling connections.',
    '#007C6C', 2
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'Leila Mensah', 'Neighbourhood Alliance', 'NA',
    'Prioritise affordable homes, create youth advisory panels, and put climate-resilient public spaces at the centre of every ward.',
    '#7C3AED', 3
  ),
  (
    '20000000-0000-0000-0000-000000000008',
    '10000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000004',
    'Yes — prioritise safer streets', 'Referendum option', 'YES',
    'Fund slower streets, safe crossings, and connected walking and cycling routes.',
    '#007C6C', 1
  ),
  (
    '20000000-0000-0000-0000-000000000009',
    '10000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000004',
    'No — retain the current plan', 'Referendum option', 'NO',
    'Retain the existing street programme and review it through the annual budget cycle.',
    '#B42318', 2
  ),
  (
    '20000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000002',
    'Yes — fund green corridors', 'Referendum option', 'YES',
    'Support a five-year investment plan for shaded paths, play areas, accessible benches, and native planting.',
    '#007C6C', 1
  ),
  (
    '20000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000002',
    'No — retain current funding', 'Referendum option', 'NO',
    'Keep the current parks maintenance budget and review any future capital expenditure through the annual budget process.',
    '#B42318', 2
  ),
  (
    '20000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000003',
    'Sofia Adeyemi', 'Community Readers', 'CR',
    'A fictional completed-election candidate for UI testing.',
    '#1D5FD0', 1
  ),
  (
    '20000000-0000-0000-0000-000000000007',
    '10000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000003',
    'Marcus Lee', 'Open Shelves', 'OS',
    'A fictional completed-election candidate for UI testing.',
    '#B54708', 2
  )
on conflict (id) do update set
  contest_id = excluded.contest_id,
  full_name = excluded.full_name,
  party_name = excluded.party_name,
  party_abbreviation = excluded.party_abbreviation,
  manifesto = excluded.manifesto,
  accent_color = excluded.accent_color,
  ballot_position = excluded.ballot_position;
