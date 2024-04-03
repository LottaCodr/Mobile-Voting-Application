import 'package:cloud_firestore/cloud_firestore.dart';

class Candidate {
  final int id;
  final String name;
  final String partyId;
  final String manifesto;
  final String imageUrl;

  Candidate(
      {required this.imageUrl,
      required this.id,
      required this.name,
      required this.partyId,
      required this.manifesto});

  // factory Candidate.fromFirestore(DocumentSnapshot doc) {
  //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //   return Candidate(
  //       id: doc.id,
  //       name: data['name'],
  //       partyId: data['partyId'],
  //       manifesto: data['manifesto'],
  //       imageUrl: data['imageUrl']);
  // }
}

final Candidate firstCadidate = Candidate(
    imageUrl: 'assets/imageUrl/Barka.jpeg',
    id: 1,
    name: 'Mr. Barka',
    partyId: 'partyId',
    manifesto: 'manifesto');

final Candidate secondCadidate = Candidate(
    imageUrl: 'assets/imageUrl/worthy.jpeg',
    id: 2,
    name: 'Worthy',
    partyId: 'partyId',
    manifesto: 'manifesto');

final Candidate thirdCadidate = Candidate(
    imageUrl: 'assets/imageUrl/Godwin.jpeg',
    id: 3,
    name: 'Jiggy',
    partyId: 'partyId',
    manifesto: 'manifesto');

final Candidate fourthCadidate = Candidate(
    imageUrl: 'assets/imageUrl/prince.jpeg',
    id: 4,
    name: 'Prince',
    partyId: 'partyId',
    manifesto: 'manifesto');
final Candidate fifthCadidate = Candidate(
    imageUrl: 'assets/imageUrl/chris.jpeg',
    id: 5,
    name: 'Chris',
    partyId: 'partyId',
    manifesto: 'manifesto');
final Candidate sixthCadidate = Candidate(
    imageUrl: 'assets/imageUrl/dan.jpeg',
    id: 6,
    name: 'Dan',
    partyId: 'partyId',
    manifesto: 'manifesto');

List<Candidate> myCandidates = [
  firstCadidate,
  secondCadidate,
  thirdCadidate,
  fourthCadidate,
  fifthCadidate,
  sixthCadidate
];
