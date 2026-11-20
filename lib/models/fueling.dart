enum FuelType { ethanol, gasoline, diesel }

extension FuelTypeLabel on FuelType {
  String get label {
    switch (this) {
      case FuelType.ethanol:
        return 'Etanol';
      case FuelType.gasoline:
        return 'Gasolina';
      case FuelType.diesel:
        return 'Diesel';
    }
  }
}

class Fueling {
  const Fueling({
    required this.fuelType,
    required this.pricePerLiter,
    required this.odometer,
    required this.liters,
    required this.dateTime,
  });

  final FuelType fuelType;
  final double pricePerLiter;
  final double odometer;
  final double liters;
  final DateTime dateTime;

  Map<String, dynamic> toJson() => {
        'fuelType': fuelType.name,
        'pricePerLiter': pricePerLiter,
        'odometer': odometer,
        'liters': liters,
        'dateTime': dateTime.toIso8601String(),
      };

  factory Fueling.fromJson(Map<String, dynamic> json) {
    return Fueling(
      fuelType: FuelType.values.byName(json['fuelType'] as String),
      pricePerLiter: (json['pricePerLiter'] as num).toDouble(),
      odometer: (json['odometer'] as num).toDouble(),
      liters: (json['liters'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }
}
