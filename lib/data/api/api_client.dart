import 'package:get/get.dart';
import 'package:mobile_voting_application/utilities/app_constants.dart';

class ApiClient extends GetConnect implements GetxService {
  final String appBaseUrl;
  late Map<String, String> _mainHeader;

  ApiClient({required this.appBaseUrl}) {
    baseUrl = appBaseUrl;
    //token = 'AIzaSyCubbANAuwA6ba-13YUQXss-HH3nEmpHRY';
    timeout = const Duration(seconds: 30);
    _mainHeader = {
      'Content-type': 'application/json ; charset=UTF-8',
      'Authorization': 'Bearer ${AppConstants.APIKEY}'
    };
  }

  // void setApiKey() {
  //   _mainHeader['Authorization'] = 'Bearer $token';
  // }

  Future<Response> getData(String uri) async {
    try {
      Response response = await get(
        uri,
      );
      print(response.body);
      return response;
    } catch (e) {
      print('Error from the api client is' + e.toString());
      return Response(statusCode: 1, statusText: e.toString());
    }
  }
}
