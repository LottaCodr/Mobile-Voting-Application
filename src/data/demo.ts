export type Candidate = { id: string; contestId: string; name: string; party: string; initials: string; color: string; platform: string };
export type Contest = { id: string; title: string; instructions: string; candidates: Candidate[] };
export type Election = { id: string; title: string; description: string; status: 'Open' | 'Upcoming' | 'Completed'; ends: string; contests: Contest[]; resultsVisible: boolean };

const mayor: Candidate[] = [
 {id:'amara',contestId:'mayor',name:'Amara Okafor',party:'Forward Riverside · FR',initials:'AO',color:'#1D5FD0',platform:'Expand reliable bus routes, publish quarterly spending updates, and protect neighbourhood services through participatory budgeting.'},
 {id:'daniel',contestId:'mayor',name:'Daniel Reyes',party:'Civic Independent · CI',initials:'DR',color:'#007C6C',platform:'Make planning decisions easier to follow, support small local businesses, and invest in safe walking and cycling connections.'},
 {id:'leila',contestId:'mayor',name:'Leila Mensah',party:'Neighbourhood Alliance · NA',initials:'LM',color:'#7C3AED',platform:'Prioritise affordable homes, youth advisory panels, and climate-resilient public spaces in every ward.'}
];
const streets: Candidate[] = [
 {id:'yes',contestId:'streets',name:'Yes — prioritise safer streets',party:'Referendum option · YES',initials:'Y',color:'#007C6C',platform:'Fund slower streets, safer crossings, and direct walking and cycling routes.'},
 {id:'no',contestId:'streets',name:'No — retain the current plan',party:'Referendum option · NO',initials:'N',color:'#B42318',platform:'Keep the existing street programme and reconsider through the annual budget cycle.'}
];
export const elections: Election[] = [
 {id:'riverside',title:'Riverside community ballot',description:'A fictional multi-contest ballot used to explore the CivicVote experience.',status:'Open',ends:'Tomorrow at 5:00 PM',resultsVisible:true,contests:[{id:'mayor',title:'Mayor of Riverside',instructions:'Choose one candidate for mayor.',candidates:mayor},{id:'streets',title:'Safer streets proposal',instructions:'Choose one proposal for the fictional mobility plan.',candidates:streets}]},
 {id:'parks',title:'Neighbourhood parks referendum',description:'A non-binding fictional referendum about improving green spaces.',status:'Upcoming',ends:'Opens in 18 days',resultsVisible:false,contests:[]},
 {id:'library',title:'Community library board',description:'A completed fictional election demonstrating published results.',status:'Completed',ends:'Closed 29 days ago',resultsVisible:true,contests:[]}
];
export const resultRows = [{name:'Amara Okafor',party:'Forward Riverside',votes:12840,color:'#1D5FD0'},{name:'Daniel Reyes',party:'Civic Independent',votes:11020,color:'#007C6C'},{name:'Leila Mensah',party:'Neighbourhood Alliance',votes:9860,color:'#7C3AED'}];
