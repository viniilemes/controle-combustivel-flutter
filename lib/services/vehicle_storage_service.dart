import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';

class VehicleStorageException implements Exception {
  const VehicleStorageException(this.message);

  final String message;
}

class VehicleStorageService {
  static const _vehicleKey = 'vehicle';

  Future<Vehicle?> loadVehicle() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_vehicleKey);
    if (value == null) return null;

    try {
      return Vehicle.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      throw const VehicleStorageException(
        'Os dados do veículo estão inválidos e não puderam ser lidos.',
      );
    }
  }

  Future<bool> saveVehicle(Vehicle vehicle) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(_vehicleKey, jsonEncode(vehicle.toJson()));
  }

  Future<bool> deleteVehicle() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.remove(_vehicleKey);
  }
}
