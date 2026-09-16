import 'package:flutter/material.dart';

/// The converter screen.
///
/// Placeholder until the real layout lands. Conversion logic belongs in
/// `lib/core/` — this widget reads a result, it never computes one.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kurs')),
      body: const Center(child: Text('Converter goes here')),
    );
  }
}
