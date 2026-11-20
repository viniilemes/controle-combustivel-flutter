import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'fuelings_screen.dart';
import 'vehicle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const VehicleScreen(),
    const FuelingsScreen(),
    const DashboardScreen(),
  ];

  static const _titles = ['Veículo', 'Abastecimentos', 'Dashboard'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() {
          _selectedIndex = index;
          // Uma nova chave força a tela a reler o armazenamento ao voltar à aba.
          if (index == 1) _screens[1] = FuelingsScreen(key: UniqueKey());
          if (index == 2) _screens[2] = DashboardScreen(key: UniqueKey());
        }),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.directions_car), label: 'Veículo'),
          NavigationDestination(
              icon: Icon(Icons.local_gas_station), label: 'Abastecimentos'),
          NavigationDestination(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ],
      ),
    );
  }
}
