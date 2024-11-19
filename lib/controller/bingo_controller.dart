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
  bool isDiagonalMarked = false; // Tracks if the diagonal is marked

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
    print('Loaded user credits: $userCredits');
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

  void rewardBet(int patternCount) async {
    if (betAmount > 0) {
      double multiplier = 1.0;

      // Adjust multiplier based on spins left and apply the patternCount multiplier
      if (spinsLeft >= 50) {
        multiplier = 2.0 * patternCount; // 50+ spins left -> 2x * patternCount
      } else if (spinsLeft >= 40) {
        multiplier =
            1.7 * patternCount; // 40+ spins left -> 1.7x * patternCount
      } else if (spinsLeft >= 30) {
        multiplier = 1.0 * patternCount; // 30+ spins left -> 1x * patternCount
      } else if (spinsLeft >= 20) {
        multiplier =
            0.5 * patternCount; // 20+ spins left -> 0.5x * patternCount
      } else {
        multiplier = 0.0 * patternCount; // Below 20 spins -> 0x * patternCount
      }

      // Calculate the reward based on the multiplier
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

  Future<void> spinBall(BuildContext context) async {
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

    // Auto-mark the number if auto-daub is enabled
    if (autoDaubEnabled && currentBall != null) {
      autoMark(context); // Call autoMark after the spin
      checkForBingo(context); // Check for bingo after auto-marking
    }
  }

  void checkForBingo(BuildContext context) {
    int patternCount = 0;

    // Check rows and columns for Bingo
    for (int i = 0; i < 5; i++) {
      if (_isMarkedRow(i)) {
        patternCount++; // Count the row pattern
      }
      if (_isMarkedColumn(i)) {
        patternCount++; // Count the column pattern
      }
    }

    if (isDiagonalMarked) {
      patternCount++; // Count the diagonal pattern if it's marked
    }

    // If there are any patterns, handle the bingo
    if (patternCount > 0) {
      _handleBingo(context, patternCount); // Pass pattern count to handle bingo
    }
  }

  void markNumber(String cellValue, BuildContext context) {
    if (cellValue != "Free" &&
        currentBall != null &&
        currentBall!.endsWith(cellValue)) {
      final numValue = int.tryParse(cellValue);
      if (numValue != null) {
        markedNumbers.add(numValue);
        _updateDiagonalStatus(); // Update the diagonal status
        notifyListeners(); // Ensure state update
        checkForBingo(
            context); // Check bingo immediately after marking a number
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

  void _updateDiagonalStatus() {
    isDiagonalMarked = (_isMarked(0, 0) &&
            _isMarked(1, 1) &&
            _isMarked(2, 2) &&
            _isMarked(3, 3) &&
            _isMarked(4, 4)) ||
        (_isMarked(0, 4) &&
            _isMarked(1, 3) &&
            _isMarked(2, 2) &&
            _isMarked(3, 1) &&
            _isMarked(4, 0));
  }

  void _handleBingo(BuildContext context, int patternCount) {
    // Reward based on the number of patterns detected
    rewardBet(patternCount);
    clearBingoCard();
    autoPlayEnabled = false;
    showWinDialog(context); // Show the win dialog before resetting
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
      _autoPlayLoop(context);
    }
    notifyListeners();
  }

  Future<void> _autoPlayLoop(BuildContext context) async {
    while (autoPlayEnabled && spinsLeft > 0 && betAmount > 0) {
      await Future.delayed(const Duration(seconds: 1));
      await spinBall(context); // Spin the ball and get the next number
      if (autoDaubEnabled && currentBall != null) {
        autoMark(context); // Auto-mark the number if it's in the bingo card
        // Check for bingo immediately after auto-marking the number
        checkForBingo(
            context); // This checks if the bingo condition is met immediately
      }
    }
  }

  void autoMark(BuildContext context) {
    if (currentBall == null) return;
    final ballNumber = int.tryParse(currentBall!.split(' ').last ?? '');
    if (ballNumber != null) {
      markedNumbers.add(ballNumber);
      _updateDiagonalStatus(); // Update the diagonal status after marking
      notifyListeners(); // Notify listeners to update the UI
      checkForBingo(context); // Ensure bingo is checked immediately
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

  void depositCredits(int amount) async {
    if (amount >= 200) {
      final dbHelper = DatabaseHelper.instance;
      final userId = await getUserId();

      try {
        await dbHelper.updateCredits(userId, amount, 'deposit');
        await _loadUserCredits();
        notifyListeners();
        print('Deposit successful: $amount credits');
      } catch (e) {
        print('Error during deposit: $e');
        // Optionally notify user of failure
      }
    } else {
      print('Minimum deposit is 200 credits.');
    }
  }

  void withdrawCredits(int amount) async {
    if (amount >= 1000 && userCredits >= amount) {
      final dbHelper = DatabaseHelper.instance;
      final userId = await getUserId();
      int taxedAmount = (amount * 0.98).round();
      await dbHelper.updateCredits(userId, -taxedAmount, 'withdraw');
      userCredits -= taxedAmount;
      await _loadUserCredits();
      notifyListeners();
    }
  }
}
