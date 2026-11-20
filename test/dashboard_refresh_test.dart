import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:controle_de_combustivel/models/fueling.dart';
import 'package:controle_de_combustivel/models/vehicle.dart';
import 'package:controle_de_combustivel/screens/home_screen.dart';

void main() {
  testWidgets('Dashboard relê os abastecimentos ao entrar na aba',
      (tester) async {
    final vehicle = const Vehicle(
      brand: 'Marca',
      model: 'Modelo',
      year: 2020,
      engineDisplacement: 1.6,
    );
    SharedPreferences.setMockInitialValues({
      'vehicle': jsonEncode(vehicle.toJson()),
    });

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final fueling = Fueling(
      fuelType: FuelType.gasoline,
      pricePerLiter: 6,
      odometer: 10000,
      liters: 40,
      dateTime: DateTime(2026, 1, 1, 10),
    );
    await preferences.setString(
        'fuelings',
        jsonEncode({
          'vehicle': vehicle.toJson(),
          'records': [fueling.toJson()],
        }));

    await tester.tap(find.byIcon(Icons.dashboard));
    await tester.pumpAndSettle();

    expect(find.text('Valores por abastecimento'), findsOneWidget);
    expect(find.textContaining('Abastecimento 1'), findsOneWidget);
    expect(find.textContaining(r'R$ 240,00'), findsOneWidget);
  });
}
