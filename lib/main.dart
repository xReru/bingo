import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: BingoCard(),
      ),
    );
  }
}

class BingoCard extends StatefulWidget {
  const BingoCard({super.key});

  @override
  State<BingoCard> createState() => _BingoCardState();
}

class _BingoCardState extends State<BingoCard> {
  late List<List<int>> _bingoCardNumbers;

  @override
  void initState() {
    super.initState();
    _bingoCardNumbers = _generateBingoNumbers();
  }

  List<List<int>> _generateBingoNumbers() {
    final random = Random();
    return List.generate(5, (colIndex) {
      final start = colIndex * 15 + 1;
      final end = start + 14;
      final columnNumbers = List.generate(15, (i) => start + i)..shuffle(random);
      return columnNumbers.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemCount: 25,
        itemBuilder: (context, index) {
          final col = index % 5;
          final row = index ~/ 5;
          final number = _bingoCardNumbers[col][row];

          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}
