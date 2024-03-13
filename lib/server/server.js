const express = require('express');
const app = express();

// Sample data for candidates, parties, ballots, and users
const candidates = [{ id: 1, name: 'Candidate A' }, { id: 2, name: 'Candidate B' }];
const parties = [{ id: 1, name: 'Party X' }, { id: 2, name: 'Party Y' }];
const ballots = [{ id: 1, candidate_id: 1, party_id: 1 }, { id: 2, candidate_id: 2, party_id: 2 }];
const users = [{ id: 1, name: 'User 1' }, { id: 2, name: 'User 2' }];

// Define routes
app.get('/api/candidates', (req, res) => {
  res.json(candidates);
});

app.get('/api/parties', (req, res) => {
  res.json(parties);
});

app.get('/api/ballots', (req, res) => {
  res.json(ballots);
});

app.get('/api/users', (req, res) => {
  res.json(users);
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
