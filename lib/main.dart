import 'package:flutter/material.dart';

import 'package:kurs/ui/screens/home_screen.dart';
import 'package:kurs/ui/theme/app_theme.dart';

void main() {
  runApp(const KursApp());
}

class KursApp extends StatelessWidget {
  const KursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kurs',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
