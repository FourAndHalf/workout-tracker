import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Charts')),
      body: const Center(
        child: Text('Progress Charts Screen'),
      ),
    );
  }
}
