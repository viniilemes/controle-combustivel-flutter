import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/fueling.dart';
import '../models/vehicle.dart';
import '../services/fueling_calculations.dart';
import '../services/fueling_storage_service.dart';
import '../services/vehicle_storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _vehicleStorage = VehicleStorageService();
  final _fuelingStorage = FuelingStorageService();

  Vehicle? _vehicle;
  List<Fueling> _fuelings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final vehicle = await _vehicleStorage.loadVehicle();
      final fuelings = vehicle == null
          ? <Fueling>[]
          : await _fuelingStorage.loadFuelings(vehicle);
      fuelings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      if (!mounted) return;
      setState(() {
        _vehicle = vehicle;
        _fuelings = fuelings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar o dashboard.';
      });
    }
  }

  String _dateLabel(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  List<FlSpot> _metricSpots(double? Function(Fueling, Fueling?) metric) {
    return [
      for (var index = 1; index < _fuelings.length; index++)
        FlSpot(
          index.toDouble(),
          metric(_fuelings[index], _fuelings[index - 1])!,
        ),
    ];
  }

  double _maxY(Iterable<double> values) {
    final maximum = values.fold<double>(
      0,
      (current, value) => math.max(current, value).toDouble(),
    );
    return maximum == 0 ? 1 : maximum * 1.2;
  }

  Widget _axisTitle(double value, TitleMeta meta, {required String unit}) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${value.toStringAsFixed(1)} $unit',
          style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final index = value.round();
    if (index < 0 || index >= _fuelings.length) return const SizedBox.shrink();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _chartCard(
      {required String title,
      required Widget chart,
      required String description}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(height: 230, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _totalsChart() {
    final maximum = _maxY(_fuelings.map(calculateTotal));
    return BarChart(
      BarChartData(
        maxY: maximum,
        minY: 0,
        barTouchData: BarTouchData(enabled: true),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 58,
                  getTitlesWidget: (value, meta) =>
                      _axisTitle(value, meta, unit: 'R\$'))),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: _bottomTitle,
                  reservedSize: 30)),
        ),
        barGroups: [
          for (var index = 0; index < _fuelings.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                    toY: calculateTotal(_fuelings[index]),
                    color: Colors.indigo,
                    width: 18)
              ],
            ),
        ],
      ),
    );
  }

  Widget _metricChart(
      {required List<FlSpot> spots,
      required String unit,
      required Color color}) {
    final maximum = _maxY(spots.map((spot) => spot.y));
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maximum,
        minX: 1,
        maxX: math.max(1, _fuelings.length - 1).toDouble(),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 58,
                  getTitlesWidget: (value, meta) =>
                      _axisTitle(value, meta, unit: unit))),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: _bottomTitle,
                  reservedSize: 30)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _history() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valores por abastecimento',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var index = 0; index < _fuelings.length; index++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Abastecimento ${index + 1} — ${_dateLabel(_fuelings[index].dateTime)}'),
                subtitle: Text(
                    '${_fuelings[index].fuelType.label} · ${_fuelings[index].liters.toStringAsFixed(2)} L'),
                trailing:
                    Text(formatCurrency(calculateTotal(_fuelings[index]))),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_vehicle == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Cadastre um veículo para visualizar o dashboard.',
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_fuelings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Registre ao menos um abastecimento para visualizar o dashboard.',
              textAlign: TextAlign.center),
        ),
      );
    }

    final consumptionSpots = _metricSpots(calculateConsumption);
    final costSpots = _metricSpots(calculateCostPerKm);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Resumo do veículo',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${_vehicle!.brand} ${_vehicle!.model}'),
        const SizedBox(height: 16),
        _chartCard(
          title: 'Valor total por abastecimento',
          description:
              'Toque nas barras ou consulte a lista abaixo. Valores em reais.',
          chart: _totalsChart(),
        ),
        const SizedBox(height: 12),
        _history(),
        const SizedBox(height: 12),
        if (_fuelings.length == 1)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'É necessário registrar pelo menos dois abastecimentos para calcular consumo e custo por quilômetro.')))
        else ...[
          _chartCard(
            title: 'Evolução do consumo',
            description:
                'Cada ponto representa um abastecimento a partir do segundo. Unidade: km/L.',
            chart: _metricChart(
                spots: consumptionSpots, unit: 'km/L', color: Colors.green),
          ),
          const SizedBox(height: 12),
          _chartCard(
            title: 'Evolução do custo por quilômetro',
            description:
                'Cada ponto representa um abastecimento a partir do segundo. Unidade: R\$/km.',
            chart: _metricChart(
                spots: costSpots, unit: 'R\$/km', color: Colors.deepOrange),
          ),
        ],
      ],
    );
  }
}
