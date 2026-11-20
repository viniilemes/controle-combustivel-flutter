import 'package:flutter_test/flutter_test.dart';

import 'package:controle_de_combustivel/models/fueling.dart';
import 'package:controle_de_combustivel/models/vehicle.dart';
import 'package:controle_de_combustivel/services/fueling_calculations.dart';

void main() {
  final firstDate = DateTime(2026, 1, 1, 10);

  Fueling fueling({required double odometer, required DateTime dateTime}) {
    return Fueling(
      fuelType: FuelType.gasoline,
      pricePerLiter: 6,
      odometer: odometer,
      liters: 40,
      dateTime: dateTime,
    );
  }

  test('calcula total e não cria indicadores no primeiro registro', () {
    final first = fueling(odometer: 10000, dateTime: firstDate);

    expect(calculateTotal(first), 240);
    expect(calculateDistance(first, null), isNull);
    expect(calculateConsumption(first, null), isNull);
    expect(calculateCostPerKm(first, null), isNull);
  });

  test('calcula distância, consumo e custo do segundo registro', () {
    final first = fueling(odometer: 10000, dateTime: firstDate);
    final second = fueling(
      odometer: 10400,
      dateTime: firstDate.add(const Duration(days: 1)),
    );

    expect(calculateTotal(second), 240);
    expect(calculateDistance(second, first), 400);
    expect(calculateConsumption(second, first), 10);
    expect(calculateCostPerKm(second, first), 0.6);
  });

  test('calcula corretamente um terceiro registro', () {
    final second = fueling(
      odometer: 10400,
      dateTime: firstDate.add(const Duration(days: 1)),
    );
    final third = Fueling(
      fuelType: FuelType.ethanol,
      pricePerLiter: 5,
      odometer: 10700,
      liters: 30,
      dateTime: firstDate.add(const Duration(days: 2)),
    );

    expect(calculateTotal(third), 150);
    expect(calculateDistance(third, second), 300);
    expect(calculateConsumption(third, second), 10);
    expect(calculateCostPerKm(third, second), 0.5);
  });

  test('não divide por zero quando não há distância válida', () {
    final first = fueling(odometer: 10000, dateTime: firstDate);
    final sameOdometer = fueling(
      odometer: 10000,
      dateTime: firstDate.add(const Duration(days: 1)),
    );

    expect(calculateConsumption(sameOdometer, first), isNull);
    expect(calculateCostPerKm(sameOdometer, first), isNull);
  });

  test('interpreta o formato real das opções retornadas pela BrasilAPI', () {
    final brand = VehicleOption.fromJson({'nome': 'Fiat', 'valor': '21'});
    final model = VehicleOption.fromJson({'modelo': 'Uno', 'valor': '123'});

    expect(brand.code, '21');
    expect(brand.name, 'Fiat');
    expect(model.code, '123');
    expect(model.name, 'Uno');
  });
}
