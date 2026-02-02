import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/filter_provider.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const LarIDApp());
}

class LarIDApp extends StatelessWidget {
  const LarIDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FilterProvider()..initialize(),
      child: MaterialApp(
        title: 'LarID',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
