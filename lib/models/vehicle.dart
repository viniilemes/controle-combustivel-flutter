class VehicleOption {
  const VehicleOption({required this.code, required this.name});

  final String code;
  final String name;

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    final code = json['codigo'] ?? json['valor'];
    final name = json['nome'] ?? json['modelo'];
    if (code == null || name == null) {
      throw const FormatException('Opção de veículo sem código ou nome.');
    }
    return VehicleOption(
      code: '$code',
      name: '$name',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VehicleOption && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

class Vehicle {
  const Vehicle({
    required this.brand,
    required this.model,
    required this.year,
    required this.engineDisplacement,
  });

  final String brand;
  final String model;
  final int year;
  final double engineDisplacement;

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'year': year,
        'engineDisplacement': engineDisplacement,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      engineDisplacement: (json['engineDisplacement'] as num).toDouble(),
    );
  }
}
