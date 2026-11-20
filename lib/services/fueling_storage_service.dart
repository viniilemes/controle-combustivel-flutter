import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fueling.dart';
import '../models/vehicle.dart';

class FuelingStorageException implements Exception {
  const FuelingStorageException(this.message);

  final String message;
}

class FuelingStorageService {
  static const _fuelingsKey = 'fuelings';

  Future<List<Fueling>> loadFuelings(Vehicle vehicle) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_fuelingsKey);
    if (value == null) return [];

    try {
      final saved = jsonDecode(value) as Map<String, dynamic>;
      final savedVehicle = saved['vehicle'] as Map<String, dynamic>;
      if (!_sameVehicle(savedVehicle, vehicle.toJson())) return [];
      final records = saved['records'] as List<dynamic>;
      return records
          .map((item) => Fueling.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (_) {
      throw const FuelingStorageException(
        'Os dados dos abastecimentos estão inválidos e não puderam ser lidos.',
      );
    }
  }

  Future<bool> saveFuelings(Vehicle vehicle, List<Fueling> fuelings) async {
    final preferences = await SharedPreferences.getInstance();
    final value = jsonEncode({
      'vehicle': vehicle.toJson(),
      'records': fuelings.map((fueling) => fueling.toJson()).toList(),
    });
    return preferences.setString(_fuelingsKey, value);
  }

  Future<bool> deleteFuelings() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.remove(_fuelingsKey);
  }

  bool _sameVehicle(Map<String, dynamic> saved, Map<String, dynamic> current) =>
      jsonEncode(saved) == jsonEncode(current);
}
