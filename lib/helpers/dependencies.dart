import 'package:get/get.dart';
import 'package:mobile_voting_application/controllers/election_controller.dart';
import 'package:mobile_voting_application/data/api/api_client.dart';
import 'package:mobile_voting_application/data/api/repo/election_repo.dart';
import 'package:mobile_voting_application/utilities/app_constants.dart';

Future<void> init() async {
  //api client
  Get.lazyPut(() => ApiClient(appBaseUrl: AppConstants.BASE_URL));

  //repos
  Get.lazyPut(() => ElectonRepo(apiClient: Get.find()));

  //controllers
  Get.lazyPut(() => ElectionController(electonRepo: Get.find()));
}
