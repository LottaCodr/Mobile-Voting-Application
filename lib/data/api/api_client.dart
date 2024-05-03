import 'package:get/get.dart';

class ApiClient extends GetConnect implements GetxService {
  final String appBaseUrl;
  late Map<String, String> _mainHeader;

  ApiClient({required this.appBaseUrl}) {
    baseUrl = appBaseUrl;
    timeout = const Duration(seconds: 30);
    _mainHeader = {
      'Content-type': 'application/json ; charset=UTF-8',
      'Authorization': 'Bearer '
    };
  }

  Future<Response> getData(String uri) async {
    try {
      Response response = await get(uri);
      return response;
    } catch (e) {
      print('Error from the api client is' + e.toString());
      return Response(statusCode: 1, statusText: e.toString());
    }
  }
}
