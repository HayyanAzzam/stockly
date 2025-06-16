import 'package:flutter/material.dart';

class HarvestersPage extends StatelessWidget {
  const HarvestersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvesters'),
      ),
      body: const Center(
        child: Text('Harvesters Page'),
      ),
    );
  }
}
