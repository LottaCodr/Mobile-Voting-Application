// import 'package:get/get.dart';
// import 'package:mobile_voting_application/data/api/repo/election_repo.dart';

// import '../models/election_model.dart';

// class ElectionController extends GetxController {
//   final ElectonRepo electonRepo;

//   ElectionController({required this.electonRepo});

//   List<ElectionModel> _electionModel = [];
//   bool isLoading = false;

//   List<ElectionModel> get electionModel => _electionModel;

//   Future<void> electionDetails() async {
//     Response response = await electonRepo.getElectionDetails();

//     if (response.statusCode == 200) {
//       print('Got the Election Details from Api');
//       List<dynamic> data = response.body;

//       _electionModel = data.map((e) => ElectionModel.fromJson(e)).toList();
//     } else {
//       // Get.snackbar(
//       //     'Error Loading data!', 'Server responded: ${response.statusCode}');
//       print(
//           "This is the statuscode because the request was unsuccessful: ${response.statusCode}");
//     }
//   }
// }
