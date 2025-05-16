import 'dart:io';
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final File imageFile;
  const ResultPage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    // Aquí después haremos la inferencia IA
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(imageFile, height: 200),
            const SizedBox(height: 24),
            const Text(
              "Resultado IA aquí...",
              style: TextStyle(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}