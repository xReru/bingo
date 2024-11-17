import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';

class BingoCardScreen extends StatefulWidget {
  const BingoCardScreen({super.key});

  @override
  State<BingoCardScreen> createState() => _BingoCardScreenState();
}

class _BingoCardScreenState extends State<BingoCardScreen> {
  late List<List<String>> _bingoCardNumbers;
  final Set<int> _markedNumbers = {};
  final Set<int> _calledNumbers = {};
  final FlutterTts _flutterTts = FlutterTts();
  int _spinsLeft = 75;
  String? _currentBall;

  @override
  void initState() {
    super.initState();
    _bingoCardNumbers = _generateBingoNumbers();
    _flutterTts.setSpeechRate(0.5);
  }

  List<List<String>> _generateBingoNumbers() {
    final random = Random();
    return List.generate(5, (colIndex) {
      final start = colIndex * 15 + 1;
      final end = start + 14;
      final columnNumbers = List.generate(15, (i) => start + i)..shuffle(random);
      final column = columnNumbers.take(5).map((n) => '$n').toList();
      if (colIndex == 2) column[2] = "Free";
      return column;
    });
  }

  void _spinBall() async {
    if (_spinsLeft <= 0) {
      _showGameOver();
      return;
    }

    final random = Random();
    int newNumber;
    String letter;
    do {
      final colIndex = random.nextInt(5);
      final start = colIndex * 15 + 1;
      final end = start + 15;
      newNumber = start + random.nextInt(end - start);

      letter = ['B', 'I', 'N', 'G', 'O'][colIndex];
    } while (_calledNumbers.contains(newNumber));

    setState(() {
      _currentBall = '$letter $newNumber';
      _calledNumbers.add(newNumber);
      _spinsLeft -= 1;
    });

    await _flutterTts.speak(_currentBall ?? '');
  }

  void _checkForBingo() {
    for (int i = 0; i < 5; i++) {
      if (_isMarkedRow(i) || _isMarkedColumn(i)) {
        _showWinDialog();
        return;
      }
    }

    if (_isMarkedDiagonal()) {
      _showWinDialog();
    }
  }

  bool _isMarkedRow(int row) {
    for (int col = 0; col < 5; col++) {
      if (!_isMarked(row, col)) return false;
    }
    return true;
  }

  bool _isMarkedColumn(int col) {
    for (int row = 0; row < 5; row++) {
      if (!_isMarked(row, col)) return false;
    }
    return true;
  }

  bool _isMarkedDiagonal() {
    bool topLeftToBottomRight = true;
    bool topRightToBottomLeft = true;
    for (int i = 0; i < 5; i++) {
      if (!_isMarked(i, i)) topLeftToBottomRight = false;
      if (!_isMarked(i, 4 - i)) topRightToBottomLeft = false;
    }
    return topLeftToBottomRight || topRightToBottomLeft;
  }

  bool _isMarked(int row, int col) {
    final cellValue = _bingoCardNumbers[col][row];
    return cellValue == "Free" || _markedNumbers.contains(int.tryParse(cellValue));
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bingo!'),
          content: const Text('Congratulations! You won the game!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _markedNumbers.clear();
                  _calledNumbers.clear();
                  _spinsLeft = 75;
                  _currentBall = null;
                  _bingoCardNumbers = _generateBingoNumbers();
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showGameOver() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: const Text('You have used all 75 spins.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bingo Card')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  _currentBall != null
                      ? 'Current Ball: $_currentBall'
                      : 'Spin to Start!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _spinBall,
                  child: Text(_spinsLeft > 0
                      ? 'Spin ($_spinsLeft spins left)'
                      : 'No Spins Left'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                ),
                itemCount: 30,
                itemBuilder: (context, index) {
                  if (index < 5) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          ['B', 'I', 'N', 'G', 'O'][index],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  } else {
                    final gridIndex = index - 5;
                    final col = gridIndex % 5;
                    final row = gridIndex ~/ 5;
                    final cellValue = _bingoCardNumbers[col][row];

                    return GestureDetector(
                      onTap: () {
                        if (cellValue != "Free" &&
                            _currentBall != null &&
                            _currentBall!.endsWith(cellValue)) {
                          setState(() {
                            _markedNumbers.add(int.parse(cellValue));
                          });
                          _checkForBingo();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cellValue == "Free"
                              ? Colors.green
                              : _markedNumbers.contains(int.tryParse(cellValue))
                                  ? Colors.red
                                  : Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            cellValue,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
