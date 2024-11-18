import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:bingo/database/database_helper.dart';
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
      userCredits += betAmount * 2; // Add winnings to user credits
      final dbHelper = DatabaseHelper.instance;
      final userId = await getUserId();

      // Update credits in the database
      await dbHelper.updateCredits(userId, betAmount * 2, 'reward');

      betAmount = 0; // Reset the bet amount
      notifyListeners();
    }
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

  void spinBall() async {
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

    await flutterTts.speak(currentBall ?? '');
    notifyListeners();
  }

  void checkForBingo(Function showWinCallback) {
    for (int i = 0; i < 5; i++) {
      if (_isMarkedRow(i) || _isMarkedColumn(i)) {
        rewardBet(); // Reward the player if they win
        clearBingoCard(); // Clear the bingo card after winning
        resetGame(); // Reset the game (spins and current ball)
        showWinCallback();
        return;
      }
    }

    if (_isMarkedDiagonal()) {
      rewardBet(); // Reward the player if they win
      clearBingoCard(); // Clear the bingo card after winning
      resetGame(); // Reset the game (spins and current ball)
      showWinCallback();
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
    final cellValue = bingoCardNumbers[col][row];
    return cellValue == "Free" ||
        markedNumbers.contains(int.tryParse(cellValue));
  }

  // Mark the number immediately
  void markNumber(String cellValue) {
    if (cellValue != "Free" &&
        currentBall != null &&
        currentBall!.endsWith(cellValue)) {
      final numValue = int.tryParse(cellValue);
      if (numValue != null) {
        markedNumbers.add(numValue);
        notifyListeners();
      }
    }
  }

  void updateBetAmount(int amount) {
    betAmount = amount;
    notifyListeners(); // Notify listeners to update the UI
  }
}
