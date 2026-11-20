import 'dart:async';

import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/vehicle_api_service.dart';
import '../services/fueling_storage_service.dart';
import '../services/vehicle_storage_service.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _engineController = TextEditingController();
  final _api = VehicleApiService();
  final _storage = VehicleStorageService();
  final _fuelingStorage = FuelingStorageService();

  Vehicle? _vehicle;
  List<VehicleOption> _brands = [];
  List<VehicleOption> _models = [];
  VehicleOption? _selectedBrand;
  VehicleOption? _selectedModel;
  bool _loading = true;
  bool _loadingBrands = false;
  bool _loadingModels = false;
  bool _saving = false;
  String? _apiError;
  String? _storageError;
  int _modelsRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    Vehicle? savedVehicle;
    try {
      savedVehicle = await _storage.loadVehicle();
    } on VehicleStorageException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _storageError = error.message;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _vehicle = savedVehicle;
      _loading = false;
    });
    if (savedVehicle == null) await _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loadingBrands = true;
      _apiError = null;
    });
    try {
      final brands = await _api.fetchBrands();
      if (!mounted) return;
      setState(() => _brands = brands);
    } on VehicleApiException catch (error) {
      if (mounted) setState(() => _apiError = error.message);
    } catch (_) {
      if (mounted) setState(() => _apiError = 'Erro de conexão com a API.');
    } finally {
      if (mounted) setState(() => _loadingBrands = false);
    }
  }

  Future<void> _loadModels(VehicleOption brand) async {
    final requestId = ++_modelsRequestId;
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _models = [];
      _loadingModels = true;
      _apiError = null;
    });
    try {
      final models = await _api.fetchModels(brand.code);
      if (!mounted || requestId != _modelsRequestId) return;
      setState(() => _models = models);
    } on VehicleApiException catch (error) {
      if (mounted && requestId == _modelsRequestId) {
        setState(() => _apiError = error.message);
      }
    } catch (_) {
      if (mounted && requestId == _modelsRequestId) {
        setState(() => _apiError = 'Erro de conexão com a API.');
      }
    } finally {
      if (mounted && requestId == _modelsRequestId) {
        setState(() => _loadingModels = false);
      }
    }
  }

  Future<void> _retryApi() {
    if (_selectedBrand != null) return _loadModels(_selectedBrand!);
    return _loadBrands();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório.' : null;

  String? _validateYear(String? value) {
    if (_required(value) != null) return _required(value);
    final year = int.tryParse(value!.trim());
    final currentYear = DateTime.now().year;
    if (year == null || year <= 0 || year < 1886 || year > currentYear + 1) {
      return 'Informe um ano inteiro entre 1886 e ${currentYear + 1}.';
    }
    return null;
  }

  String? _validateEngine(String? value) {
    if (_required(value) != null) return _required(value);
    final engine = double.tryParse(value!.trim().replaceAll(',', '.'));
    if (engine == null || engine <= 0) {
      return 'Informe uma cilindrada positiva.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _selectedBrand == null ||
        _selectedModel == null) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    final vehicle = Vehicle(
      brand: _selectedBrand!.name,
      model: _selectedModel!.name,
      year: int.parse(_yearController.text.trim()),
      engineDisplacement: double.parse(
        _engineController.text.trim().replaceAll(',', '.'),
      ),
    );
    final saved = await _storage.saveVehicle(vehicle);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _vehicle = vehicle;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              saved ? 'Veículo salvo.' : 'Não foi possível salvar o veículo.')),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: const Text('O veículo atual será removido deste dispositivo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _storage.deleteVehicle();
    if (!mounted) return;
    if (deleted) {
      await _fuelingStorage.deleteFuelings();
      if (!mounted) return;
      setState(() {
        _vehicle = null;
        _selectedBrand = null;
        _selectedModel = null;
        _models = [];
        _yearController.clear();
        _engineController.clear();
      });
      await _loadBrands();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Veículo excluído.')));
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _engineController.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_storageError != null) {
      return Center(child: Text(_storageError!, textAlign: TextAlign.center));
    }
    if (_vehicle != null) return _buildSavedVehicle(_vehicle!);
    return _buildForm();
  }

  Widget _buildSavedVehicle(Vehicle vehicle) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.directions_car, size: 64),
        const SizedBox(height: 16),
        Text('${vehicle.brand} ${vehicle.model}',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text('Ano: ${vehicle.year}'),
        Text('Cilindrada: ${vehicle.engineDisplacement.toStringAsFixed(1)} L'),
        const SizedBox(height: 24),
        const Text(
            'Já existe um veículo cadastrado. Exclua-o para cadastrar outro.'),
        const SizedBox(height: 16),
        OutlinedButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir veículo')),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Cadastre seu veículo',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          if (_apiError != null) ...[
            Text(_apiError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextButton.icon(
                onPressed: _retryApi,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente')),
          ],
          DropdownButtonFormField<VehicleOption>(
            initialValue: _selectedBrand,
            decoration: const InputDecoration(
                labelText: 'Marca', border: OutlineInputBorder()),
            items: _brands
                .map((brand) =>
                    DropdownMenuItem(value: brand, child: Text(brand.name)))
                .toList(),
            onChanged: _loadingBrands
                ? null
                : (brand) {
                    if (brand != null) unawaited(_loadModels(brand));
                  },
            validator: (_) =>
                _selectedBrand == null ? 'Selecione uma marca.' : null,
            hint: Text(_loadingBrands ? 'Carregando marcas...' : 'Selecione'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<VehicleOption>(
            initialValue: _selectedModel,
            decoration: const InputDecoration(
                labelText: 'Modelo', border: OutlineInputBorder()),
            items: _models
                .map((model) =>
                    DropdownMenuItem(value: model, child: Text(model.name)))
                .toList(),
            onChanged: _loadingModels || _selectedBrand == null
                ? null
                : (model) => setState(() => _selectedModel = model),
            validator: (_) =>
                _selectedModel == null ? 'Selecione um modelo.' : null,
            hint: Text(_loadingModels
                ? 'Carregando modelos...'
                : 'Selecione uma marca primeiro'),
          ),
          const SizedBox(height: 16),
          TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                  labelText: 'Ano', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: _validateYear),
          const SizedBox(height: 16),
          TextFormField(
              controller: _engineController,
              decoration: const InputDecoration(
                  labelText: 'Cilindrada (L)',
                  hintText: 'Ex.: 1,6',
                  border: OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validateEngine),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Salvando...' : 'Salvar veículo')),
        ],
      ),
    );
  }
}
