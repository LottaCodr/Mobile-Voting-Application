class Vote {
  final String id;
  final String voterId;
  final String candidateId;
  final DateTime timestamp;

  Vote({required this.id, required this.voterId, required this.candidateId, required this.timestamp});
}
