import 'chemical.dart';

class ApiResponse {
  final List<Chemical> chemicals;

  ApiResponse({required this.chemicals});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    final record = json['record'] as Map<String, dynamic>;
    final chemicalsJson = record['chemicals'] as List;

    return ApiResponse(
      chemicals: chemicalsJson
          .map((json) => Chemical.fromJson(json))
          .toList(),
    );
  }
}