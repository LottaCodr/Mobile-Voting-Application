import 'package:get/get.dart';
import 'package:mobile_voting_application/data/api/api_client.dart';
import 'package:mobile_voting_application/utilities/app_constants.dart';

class ElectonRepo extends GetxService {
  final ApiClient apiClient;

  ElectonRepo({required this.apiClient});

  Future<Response> getElectionDetails() async {
    return await apiClient.getData(AppConstants.ELECTION_ENDPOINT);
  }
}
