import '../models/fueling.dart';

double calculateTotal(Fueling fueling) =>
    fueling.pricePerLiter * fueling.liters;

double? calculateDistance(Fueling fueling, Fueling? previous) {
  if (previous == null) return null;
  return fueling.odometer - previous.odometer;
}

double? calculateConsumption(Fueling fueling, Fueling? previous) {
  final distance = calculateDistance(fueling, previous);
  if (distance == null || distance <= 0) return null;
  return distance / fueling.liters;
}

double? calculateCostPerKm(Fueling fueling, Fueling? previous) {
  final distance = calculateDistance(fueling, previous);
  if (distance == null || distance <= 0) return null;
  return calculateTotal(fueling) / distance;
}

String formatCurrency(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
