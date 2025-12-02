import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chemical.dart';
import '../models/api_response.dart';

class ApiService {
  static const String baseUrl =
      'https://api.jsonbin.io/v3/b/68918782f7e7a370d1f4029d';

  Future<List<Chemical>> fetchChemicals() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonData);
        return apiResponse.chemicals;
      } else {
        throw Exception('Failed to load chemicals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}