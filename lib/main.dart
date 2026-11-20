import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const FuelControlApp());
}

class FuelControlApp extends StatelessWidget {
  const FuelControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Combustível',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
