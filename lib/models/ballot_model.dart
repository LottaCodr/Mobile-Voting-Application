class Ballot {
  final String id;
  final String electionId;
  final String voterId;
  final bool hasVoted;

  Ballot({required this.id, required this.electionId, required this.voterId, required this.hasVoted});
}
