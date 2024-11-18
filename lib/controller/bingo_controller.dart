import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:bingo/database/database_helper.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BingoController extends ChangeNotifier {
  late List<List<String>> bingoCardNumbers;
  final Set<int> markedNumbers = {};
  final Set<int> calledNumbers = {};
  final FlutterTts flutterTts = FlutterTts();

  int spinsLeft = 75;
  String? currentBall;
  int userCredits = 0;
  int betAmount = 0; // New field to track the bet amount
  bool lastGameWon = false; // Track if the last game was a win
  double winProbability = 0.2; // 20% chance to win a game

  bool autoDaubEnabled = false; // Tracks if auto-daub is enabled
  bool autoPlayEnabled = false; // Tracks if autoplay is enabled

  BingoController() {
    _init();
  }

  Future<void> _init() async {
    bingoCardNumbers = _generateBingoNumbers();
    flutterTts.setSpeechRate(0.5);
    await _loadUserCredits();
    notifyListeners();
  }

  Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  Future<void> _loadUserCredits() async {
    final dbHelper = DatabaseHelper.instance;
    final userId = await getUserId();
    userCredits = await dbHelper.getCredits(userId);
    notifyListeners();
  }

  // Reset the game after a win or when the user starts a new game
  void resetGame() {
    spinsLeft = 75; // Reset spins to the initial value
    currentBall = null; // Reset current ball to null
    notifyListeners(); // Notify listeners to update the UI
  }

  void placeBet(int amount) async {
    if (amount > 0 && userCredits >= amount) {
      betAmount = amount;
      userCredits -= amount;

      final dbHelper = DatabaseHelper.instance;
      final userId = await getUserId();

      // Deduct credits in the database
      await dbHelper.updateCredits(
          userId, -amount, 'bet'); // Negative amount to deduct

      notifyListeners();
    }
  }

  void rewardBet() async {
    if (betAmount > 0) {
      double multiplier = 1.0;

      if (spinsLeft <= 20) {
        multiplier = 0.3;
      } else if (spinsLeft <= 30) {
        multiplier = 0.5;
      } else if (spinsLeft >= 50) {
        multiplier = lastGameWon
            ? 1.5
            : 2.0; // 1.5x if won previously, else 2.0x for more than 50 spins left
      } else if (spinsLeft >= 40) {
        multiplier = lastGameWon
            ? 1.0
            : 1.5; // 1.0x if won previously, else 1.5x for 40+ spins left
      }
      int reward = (betAmount * multiplier).round();
      userCredits += reward;

      // Update the user's credits in the database
      final dbHelper = DatabaseHelper.instance;
      final userId = await getUserId();
      await dbHelper.updateCredits(userId, reward, 'reward');

      // Reset the bet amount after rewarding
      betAmount = 0;
      notifyListeners(); // Notify listeners to update UI
    }
  }

  void adjustWinProbability() {
    if (lastGameWon) {
      winProbability =
          max(0.1, winProbability - 0.05); // Decrease win probability
    } else {
      winProbability =
          min(0.5, winProbability + 0.05); // Increase win probability
    }
  }

  bool shouldWin() {
    final random = Random();
    return random.nextDouble() < winProbability;
  }

  List<List<String>> _generateBingoNumbers() {
    final random = Random();
    return List.generate(5, (colIndex) {
      final start = colIndex * 15 + 1;
      final end = start + 14;
      final columnNumbers = List.generate(15, (i) => start + i)
        ..shuffle(random);
      final column = columnNumbers.take(5).map((n) => '$n').toList();
      if (colIndex == 2) column[2] = "Free";
      return column;
    });
  }

  // Reset the bingo card and marked numbers
  void clearBingoCard() {
    bingoCardNumbers = _generateBingoNumbers(); // Regenerate the bingo card
    markedNumbers.clear(); // Clear all marked numbers
    calledNumbers.clear(); // Clear the called numbers
    notifyListeners(); // Notify listeners to update UI
  }

  Future<void> spinBall() async {
    if (spinsLeft <= 0 || betAmount == 0) return;

    final random = Random();
    int newNumber;
    String letter;
    do {
      final colIndex = random.nextInt(5);
      final start = colIndex * 15 + 1;
      final end = start + 15;
      newNumber = start + random.nextInt(end - start);

      letter = ['B', 'I', 'N', 'G', 'O'][colIndex];
    } while (calledNumbers.contains(newNumber));

    currentBall = '$letter $newNumber';
    calledNumbers.add(newNumber);
    spinsLeft--;
    notifyListeners();
    await flutterTts.speak(currentBall ?? '');
    await Future.delayed(const Duration(seconds: 1));
  }

  void checkForBingo(BuildContext context) {
    if (!shouldWin()) return;

    // Check rows and columns for Bingo
    for (int i = 0; i < 5; i++) {
      if (_isMarkedRow(i) || _isMarkedColumn(i)) {
        _handleBingo(context);
        return; // Return early if bingo is found
      }
    }

    // Check diagonals for Bingo
    if (_isMarkedDiagonal()) {
      _handleBingo(context);
    }
  }

  void markNumber(String cellValue, BuildContext context) {
    if (cellValue != "Free" &&
        currentBall != null &&
        currentBall!.endsWith(cellValue)) {
      final numValue = int.tryParse(cellValue);
      if (numValue != null) {
        markedNumbers.add(numValue);
        notifyListeners(); // Ensure state update
        checkForBingo(context); // Ensure bingo is checked immediately
      }
    }
  }

  bool _isMarked(int row, int col) {
    final cellValue = bingoCardNumbers[col]
        [row]; // Assuming bingoCardNumbers is [column][row]
    return cellValue == "Free" ||
        markedNumbers.contains(int.tryParse(cellValue)); // Marked number check
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
    // Check top-left to bottom-right diagonal
    bool topLeftToBottomRight = true;
    bool topRightToBottomLeft = true;

    for (int i = 0; i < 5; i++) {
      if (!_isMarked(i, i)) topLeftToBottomRight = false;
      if (!_isMarked(i, 4 - i)) topRightToBottomLeft = false;

      // Exit early if both diagonals are already invalid
      if (!topLeftToBottomRight && !topRightToBottomLeft) {
        return false;
      }
    }

    return topLeftToBottomRight || topRightToBottomLeft;
  }

  void _handleBingo(BuildContext context) {
    lastGameWon = true;
    rewardBet();
    adjustWinProbability();
    clearBingoCard();
    autoPlayEnabled = false;
    showWinDialog(context); // Show the win dialog before resetting
    // Optionally, allow the user to reset the game manually after showing the dialog
    resetGame();
  }

  void updateBetAmount(int amount) {
    betAmount = amount;
    notifyListeners(); // Notify listeners to update the UI
  }

  // Toggle auto-daub
  void toggleAutoDaub() {
    autoDaubEnabled = !autoDaubEnabled;
    notifyListeners();
  }

  // Toggle autoplay
  void toggleAutoPlay(BuildContext context) {
    autoPlayEnabled = !autoPlayEnabled;
    if (autoPlayEnabled && betAmount > 0 && spinsLeft > 0) {
      _autoPlayLoop(context); // Pass context here
    }
    notifyListeners();
  }

  Future<void> _autoPlayLoop(BuildContext context) async {
    while (autoPlayEnabled && spinsLeft > 0 && betAmount > 0) {
      await Future.delayed(const Duration(seconds: 1)); // Delay between spins
      await spinBall();
      if (autoDaubEnabled && currentBall != null) {
        autoMark(); // Auto-mark the ball
        checkForBingo(context); // Check for bingo immediately
      }
    }
  }

  // Automatically mark the current ball
  void autoMark() {
    if (currentBall == null) return;
    final ballNumber = int.tryParse(currentBall!.split(' ').last ?? '');
    if (ballNumber != null) {
      markedNumbers.add(ballNumber);
      notifyListeners();
    }
  }

  void showWinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You won the game!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
