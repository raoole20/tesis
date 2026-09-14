import 'package:flutter/material.dart';

import 'theme/theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupo',
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: Text('Cupo', style: AppTypography.logo(size: 28))),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Futura app lista para el proyecto Cupo'),
          ),
        ),
      ),
    );
  }
}
