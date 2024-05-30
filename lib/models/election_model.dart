import 'candidate_model.dart';

class ElectionModel {
  final int id;
  final String name;
  int totalVotes;
  final List<Candidate> candidates;

  ElectionModel({
    required this.id,
    required this.name,
    required this.totalVotes,
    required this.candidates,
  });
}

List<Candidate> presidentialCandidates = [
  firstCadidate,
  secondCadidate,
  thirdCadidate,
  fourthCadidate,
  fifthCadidate,
  sixthCadidate
];
List<Candidate> senatorialCandidates = [
  firstCadidateforSenate,
  secondCadidateforSenate,
  thirdCadidateforSenate,
  fourthCadidateforSenate,
  fifthCadidateforSenate,
  sixthCadidateforSenate
];
List<Candidate> goveronshipCandidates = [
  firstCadidateforGov,
  secondCadidateforGov,
  thirdCadidateforGov,
  fourthCadidateforGov,
  fifthCadidateforGov,
  sixthCadidateforGov
];

final ElectionModel presidentialElection = ElectionModel(
    id: 1,
    name: 'Presidential Election',
    candidates: presidentialCandidates,
    totalVotes: 3450000);
final ElectionModel senatorialElection = ElectionModel(
    id: 2,
    name: 'Senatorial Election',
    candidates: presidentialCandidates,
    totalVotes: 835000);
final ElectionModel governorshipElection = ElectionModel(
    id: 3,
    name: 'Governship Election',
    candidates: presidentialCandidates,
    totalVotes: 785000);

List<ElectionModel> upComingElection = [
  presidentialElection,
  senatorialElection,
  governorshipElection
];
List<ElectionModel> liveElection = [
  presidentialElection,
  senatorialElection,
  governorshipElection
];
List<ElectionModel> completedElection = [
  presidentialElection,
  senatorialElection,
  governorshipElection
];




// class ElectionModel {
//   int? _id;
//   String? _title;
//   String? _description;
//   DateTime? _startDate;
//   DateTime? _endDate;

//   int? get id => _id;
//   String? get title => _title;
//   String? get description => _description;
//   DateTime? get startDate => _startDate;
//   DateTime? get endDate => _endDate;

//   ElectionModel(
//       {required id,
//       required title,
//       required description,
//       required startDate,
//       required endDate}) {
//     _id = id;
//     _title = title;
//     _description = description;
//     _startDate = startDate;
//     _endDate = endDate;
//   }

//   ElectionModel.fromJson(Map<String, dynamic> json) {
//     _id = json['id'];
//     _title = json['title'];
//     _description = json['description'];
//     _startDate = json['startDate'];
//     _endDate = json['endDate'];
//   }
// }
