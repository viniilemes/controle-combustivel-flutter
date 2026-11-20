import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vehicle.dart';

class VehicleApiException implements Exception {
  const VehicleApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VehicleApiService {
  VehicleApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://brasilapi.com.br/api';
  final http.Client _client;

  Future<List<VehicleOption>> fetchBrands() async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/fipe/marcas/v1/carros'),
        )
        .timeout(const Duration(seconds: 15));
    return _parseOptions(response, 'marcas');
  }

  Future<List<VehicleOption>> fetchModels(String brandCode) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/fipe/veiculos/v1/carros/$brandCode'),
        )
        .timeout(const Duration(seconds: 15));
    return _parseOptions(response, 'modelos');
  }

  List<VehicleOption> _parseOptions(http.Response response, String resource) {
    if (response.statusCode != 200) {
      throw VehicleApiException(
        'Não foi possível carregar $resource (HTTP ${response.statusCode}).',
      );
    }

    try {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded
          .map((item) => VehicleOption.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw VehicleApiException(
          'A API retornou dados inválidos para $resource.');
    }
  }

  void dispose() => _client.close();
}
