import 'package:flutter/material.dart';

import '../models/fueling.dart';
import '../models/vehicle.dart';
import '../services/fueling_calculations.dart';
import '../services/fueling_storage_service.dart';
import '../services/vehicle_storage_service.dart';

class FuelingsScreen extends StatefulWidget {
  const FuelingsScreen({super.key});

  @override
  State<FuelingsScreen> createState() => _FuelingsScreenState();
}

class _FuelingsScreenState extends State<FuelingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();
  final _vehicleStorage = VehicleStorageService();
  final _fuelingStorage = FuelingStorageService();

  Vehicle? _vehicle;
  List<Fueling> _fuelings = [];
  FuelType? _selectedFuelType;
  DateTime _selectedDateTime = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

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
        _loadError = 'Não foi possível carregar os abastecimentos.';
      });
    }
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório.' : null;

  String? _positive(String? value, String label) {
    if (_required(value) != null) return _required(value);
    final number = _number(value!);
    if (number == null || number <= 0) return '$label deve ser maior que zero.';
    return null;
  }

  String? _odometerValidator(String? value) {
    if (_required(value) != null) return _required(value);
    final odometer = _number(value!);
    if (odometer == null || odometer < 0) {
      return 'A quilometragem deve ser maior ou igual a zero.';
    }
    return null;
  }

  String _dateLabel(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String? _chronologyError(Fueling fueling) {
    if (_fuelings.isEmpty) return null;
    final previous = _fuelings.last;
    if (!fueling.dateTime.isAfter(previous.dateTime)) {
      return 'A data e o horário devem ser posteriores ao último abastecimento.';
    }
    if (fueling.odometer <= previous.odometer) {
      return 'A quilometragem deve ser maior que a do último abastecimento.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || _vehicle == null) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _selectedFuelType == null) {
      setState(() {});
      return;
    }

    final price = _number(_priceController.text);
    final odometer = _number(_odometerController.text);
    final liters = _number(_litersController.text);
    if (price == null || odometer == null || liters == null) return;

    final fueling = Fueling(
      fuelType: _selectedFuelType!,
      pricePerLiter: price,
      odometer: odometer,
      liters: liters,
      dateTime: _selectedDateTime,
    );
    final chronologyError = _chronologyError(fueling);
    if (chronologyError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(chronologyError)),
      );
      return;
    }

    setState(() => _saving = true);
    final updated = [..._fuelings, fueling];
    final saved = await _fuelingStorage.saveFuelings(_vehicle!, updated);
    if (!mounted) return;
    if (!saved) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível salvar o abastecimento.')),
      );
      return;
    }

    setState(() {
      _fuelings = updated;
      _saving = false;
      _selectedFuelType = null;
      _selectedDateTime = DateTime.now();
    });
    _priceController.clear();
    _odometerController.clear();
    _litersController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abastecimento salvo.')),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _odometerController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return Center(child: Text(_loadError!));
    if (_vehicle == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Cadastre um veículo antes de registrar abastecimentos.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildForm(),
        const SizedBox(height: 24),
        Text('Histórico', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_fuelings.isEmpty)
          const Text('Nenhum abastecimento registrado.')
        else
          ..._fuelings.asMap().entries.map(
                (entry) => _FuelingCard(
                  fueling: entry.value,
                  previous: entry.key == 0 ? null : _fuelings[entry.key - 1],
                  dateLabel: _dateLabel(entry.value.dateTime),
                ),
              ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Novo abastecimento',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<FuelType>(
                initialValue: _selectedFuelType,
                decoration: const InputDecoration(
                    labelText: 'Combustível', border: OutlineInputBorder()),
                items: FuelType.values
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)))
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _selectedFuelType = value),
                validator: (_) => _selectedFuelType == null
                    ? 'Selecione o combustível.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                      labelText: 'Preço por litro (R\$)',
                      hintText: 'Ex.: 6,00',
                      border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => _positive(value, 'O preço')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _odometerController,
                  decoration: const InputDecoration(
                      labelText: 'Quilometragem (km)',
                      border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _odometerValidator),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _litersController,
                  decoration: const InputDecoration(
                      labelText: 'Quantidade (litros)',
                      hintText: 'Ex.: 40',
                      border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => _positive(value, 'A quantidade')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: _saving ? null : _selectDateTime,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_dateLabel(_selectedDateTime))),
              const SizedBox(height: 12),
              FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label:
                      Text(_saving ? 'Salvando...' : 'Salvar abastecimento')),
              const SizedBox(height: 8),
              const Text(
                  'Cada abastecimento é considerado como tanque completo.'),
              const SizedBox(height: 4),
              const Text(
                  'Novos registros devem ter data posterior e quilometragem maior que o último abastecimento.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelingCard extends StatelessWidget {
  const _FuelingCard(
      {required this.fueling, required this.previous, required this.dateLabel});

  final Fueling fueling;
  final Fueling? previous;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final distance = calculateDistance(fueling, previous);
    final consumption = calculateConsumption(fueling, previous);
    final costPerKm = calculateCostPerKm(fueling, previous);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(fueling.fuelType.label,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(dateLabel)
            ]),
            const SizedBox(height: 8),
            Text(
                '${fueling.liters.toStringAsFixed(2)} L × ${formatCurrency(fueling.pricePerLiter)}/L'),
            Text('Quilometragem: ${fueling.odometer.toStringAsFixed(0)} km'),
            Text('Total: ${formatCurrency(calculateTotal(fueling))}'),
            const Divider(),
            if (previous == null)
              const Text('Sem referência anterior')
            else ...[
              Text('Distância: ${distance!.toStringAsFixed(0)} km'),
              Text('Consumo: ${consumption!.toStringAsFixed(2)} km/L'),
              Text('Custo: ${formatCurrency(costPerKm!)}/km'),
            ],
          ],
        ),
      ),
    );
  }
}
