import 'package:books_app/Utils/helpers.dart';
import 'package:books_app/constants/api.dart';
import 'package:http/http.dart';

class QuoteRequest {
  static Future<Response> getQuoteData(String token) async {
    return sendRequest(() => get(Uri.parse(BASE_ROUTE + '/quote'),
        headers: {'authorization': token}));
  }
}