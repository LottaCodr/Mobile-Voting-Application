import 'package:cloud_firestore/cloud_firestore.dart';

class Candidate {
  final String id;
  final String name;
  final String partyId;
  final String manifesto;

  Candidate(
      {required this.id,
      required this.name,
      required this.partyId,
      required this.manifesto});

  factory Candidate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Candidate(
      id: doc.id,
      name: data['name'],
      partyId: data['partyId'],
      manifesto: data['manifesto'],
    );
  }
}
