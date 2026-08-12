export type Candidate = {
  id: string;
  contestId: string;
  name: string;
  party: string;
  abbreviation: string;
  initials: string;
  color: string;
  platform: string;
  priorities: string[];
  experience: string;
};

export type Contest = {
  id: string;
  title: string;
  instructions: string;
  type: 'candidate' | 'referendum';
  candidates: Candidate[];
};

export type ElectionStatus = 'Open' | 'Upcoming' | 'Completed';

export type Election = {
  id: string;
  title: string;
  shortTitle: string;
  description: string;
  jurisdiction: string;
  status: ElectionStatus;
  timing: string;
  dateRange: string;
  contests: Contest[];
  resultsVisible: boolean;
};

const mayorContestId = '40000000-0000-0000-0000-000000000001';
const streetsContestId = '40000000-0000-0000-0000-000000000004';

const mayor: Candidate[] = [
  {
    id: '20000000-0000-0000-0000-000000000001',
    contestId: mayorContestId,
    name: 'Amara Okafor',
    party: 'Forward Riverside',
    abbreviation: 'FR',
    initials: 'AO',
    color: '#2F64E1',
    platform:
      'Expand reliable bus routes, publish quarterly spending updates, and protect neighbourhood services through participatory budgeting.',
    priorities: ['Reliable public transport', 'Open city finances', 'Neighbourhood services'],
    experience: 'Community planning chair and former public transport commissioner.',
  },
  {
    id: '20000000-0000-0000-0000-000000000002',
    contestId: mayorContestId,
    name: 'Daniel Reyes',
    party: 'Civic Independent',
    abbreviation: 'CI',
    initials: 'DR',
    color: '#087A6B',
    platform:
      'Make planning decisions easier to follow, support small local businesses, and invest in safe walking and cycling connections.',
    priorities: ['Small business support', 'Safer local streets', 'Transparent planning'],
    experience: 'Local business owner and two-term neighbourhood representative.',
  },
  {
    id: '20000000-0000-0000-0000-000000000003',
    contestId: mayorContestId,
    name: 'Leila Mensah',
    party: 'Neighbourhood Alliance',
    abbreviation: 'NA',
    initials: 'LM',
    color: '#7546C9',
    platform:
      'Prioritise affordable homes, create youth advisory panels, and put climate-resilient public spaces at the centre of every ward.',
    priorities: ['Affordable homes', 'Youth participation', 'Climate-ready parks'],
    experience: 'Housing advocate and former Riverside youth services director.',
  },
];

const streets: Candidate[] = [
  {
    id: '20000000-0000-0000-0000-000000000008',
    contestId: streetsContestId,
    name: 'Yes — prioritise safer streets',
    party: 'Referendum option',
    abbreviation: 'YES',
    initials: 'Y',
    color: '#087A6B',
    platform:
      'Fund slower streets, safer crossings, and direct walking and cycling routes through a five-year mobility programme.',
    priorities: ['Safer crossings', 'Lower-speed streets', 'Connected walking routes'],
    experience: 'A yes vote approves the proposed five-year mobility programme.',
  },
  {
    id: '20000000-0000-0000-0000-000000000009',
    contestId: streetsContestId,
    name: 'No — retain the current plan',
    party: 'Referendum option',
    abbreviation: 'NO',
    initials: 'N',
    color: '#A33B30',
    platform:
      'Keep the existing street programme and reconsider any larger mobility investment through the annual budget process.',
    priorities: ['Keep current programme', 'Annual budget review', 'No new five-year fund'],
    experience: 'A no vote keeps the current programme without the proposed expansion.',
  },
];

export const elections: Election[] = [
  {
    id: '10000000-0000-0000-0000-000000000001',
    title: 'Riverside community election',
    shortTitle: 'Riverside 2026',
    description: 'A fictional local election with one candidate contest and one referendum.',
    jurisdiction: 'Riverside Borough',
    status: 'Open',
    timing: 'Closes tomorrow at 8:00 PM',
    dateRange: '11–13 August 2026',
    resultsVisible: false,
    contests: [
      {
        id: mayorContestId,
        title: 'Mayor of Riverside',
        instructions: 'Select one candidate. You can change this choice before casting your ballot.',
        type: 'candidate',
        candidates: mayor,
      },
      {
        id: streetsContestId,
        title: 'Safer streets proposal',
        instructions: 'Select Yes or No for the proposed five-year mobility programme.',
        type: 'referendum',
        candidates: streets,
      },
    ],
  },
  {
    id: '10000000-0000-0000-0000-000000000002',
    title: 'Neighbourhood parks referendum',
    shortTitle: 'Parks referendum',
    description: 'A fictional referendum about improving green spaces and accessible play areas.',
    jurisdiction: 'Riverside Borough',
    status: 'Upcoming',
    timing: 'Opens in 18 days',
    dateRange: '30 August–1 September 2026',
    resultsVisible: false,
    contests: [],
  },
  {
    id: '10000000-0000-0000-0000-000000000003',
    title: 'Community library board',
    shortTitle: 'Library board',
    description: 'A completed fictional election with certified aggregate results.',
    jurisdiction: 'Riverside Borough',
    status: 'Completed',
    timing: 'Certified 15 July 2026',
    dateRange: '12–14 July 2026',
    resultsVisible: true,
    contests: [],
  },
];

export type ResultRow = {
  name: string;
  party: string;
  votes: number;
  color: string;
};

export const resultRows: ResultRow[] = [
  { name: 'Sofia Adeyemi', party: 'Community Readers', votes: 12840, color: '#2F64E1' },
  { name: 'Marcus Lee', party: 'Open Shelves', votes: 11020, color: '#087A6B' },
];

export type UpdateItem = {
  id: string;
  kind: 'ballot' | 'security' | 'result';
  title: string;
  body: string;
  time: string;
  unread: boolean;
};

export const updateItems: UpdateItem[] = [
  {
    id: 'ballot-open',
    kind: 'ballot',
    title: 'Your Riverside ballot is open',
    body: 'You can review two contests and cast your fictional ballot until tomorrow at 8:00 PM.',
    time: 'Today, 9:00 AM',
    unread: true,
  },
  {
    id: 'security-check',
    kind: 'security',
    title: 'Security check complete',
    body: 'Your verified voter profile and assigned ballot are ready.',
    time: 'Yesterday',
    unread: true,
  },
  {
    id: 'library-results',
    kind: 'result',
    title: 'Library board results certified',
    body: 'Final aggregate results are now available. Your selections are never shown in updates.',
    time: '15 July',
    unread: false,
  },
];
