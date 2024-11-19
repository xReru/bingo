import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/bingo_controller.dart';
import 'user_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'transaction.dart';

class BingoCardScreen extends StatelessWidget {
  const BingoCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back accidentally
        final shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit ?? false;
      },
      child: Consumer<BingoController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Bingo Card'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => TransactionDialog(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showLogoutConfirmationDialog(context),
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    controller.currentBall != null
                        ? 'Current Ball: ${controller.currentBall}'
                        : 'Spin to Start!',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                // Credits display (Placed right after the current ball)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Credits: ₱${controller.userCredits}.00'),
                ),
                // Bingo card grid (Main part of the screen)
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                    ),
                    itemCount: 30,
                    itemBuilder: (context, index) {
                      if (index < 5) {
                        return BingoHeader(index: index);
                      } else {
                        final gridIndex = index - 5;
                        final col = gridIndex % 5;
                        final row = gridIndex ~/ 5;
                        final cellValue = controller.bingoCardNumbers[col][row];
                        return BingoCell(
                          value: cellValue,
                          marked: controller.markedNumbers
                              .contains(int.tryParse(cellValue)),
                          onTap: () {
                            if (cellValue != "Free") {
                              controller.markNumber(cellValue, context);
                              controller.checkForBingo(context);
                            }
                          },
                        );
                      }
                    },
                  ),
                ),
                // Row for Place Bet Button and Spin Button at the bottom
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Place Bet Button
                      ElevatedButton(
                        onPressed: controller.spinsLeft > 0 &&
                                controller.betAmount == 0
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Place Bet'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                                labelText: 'Bet Amount'),
                                            onChanged: (value) {
                                              final bet = int.tryParse(value);
                                              if (bet != null) {
                                                controller.updateBetAmount(bet);
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton(
                                            onPressed: () {
                                              controller.placeBet(
                                                  controller.betAmount);
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Confirm Bet'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }
                            : null,
                        child: Text(controller.betAmount == 0
                            ? 'Place Bet'
                            : 'Bet Placed: ${controller.betAmount}'),
                      ),
                      const SizedBox(width: 20), // Spacing between buttons
                      // Spin Button (Disabled when Auto Play is on)
                      ElevatedButton(
                        onPressed: controller.autoPlayEnabled ||
                                controller.betAmount <= 0
                            ? null
                            : () async {
                                await context
                                    .read<BingoController>()
                                    .spinBall(context);
                              },
                        child: Text(controller.spinsLeft > 0
                            ? 'Spin (${controller.spinsLeft} spins left)'
                            : 'No Spins Left'),
                      ),
                    ],
                  ),
                ),
                // Toggles wrapped in Column for alignment in one row
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Auto Daub Toggle
                      Row(
                        children: [
                          Switch(
                            value: controller.autoDaubEnabled,
                            onChanged: (value) {
                              controller.toggleAutoDaub();
                            },
                          ),
                          const Text('Auto Daub'),
                        ],
                      ),
                      const SizedBox(width: 20), // Spacing between toggles
                      // Auto Play Toggle
                      Row(
                        children: [
                          Switch(
                            value: controller.autoPlayEnabled,
                            onChanged: (value) {
                              if (controller.betAmount > 0) {
                                controller.toggleAutoPlay(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Place a bet before enabling autoplay!'),
                                  ),
                                );
                              }
                            },
                          ),
                          const Text('Auto Play'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Clear user session
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit Confirmation'),
          content: const Text(
              'Are you sure you want to exit the app? Your progress will be saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}

class BingoHeader extends StatelessWidget {
  final int index;
  const BingoHeader({required this.index, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          ['B', 'I', 'N', 'G', 'O'][index],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class BingoCell extends StatelessWidget {
  final String value;
  final bool marked;
  final VoidCallback onTap;

  const BingoCell({
    required this.value,
    required this.marked,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap(); // Mark the number and check for bingo
        final controller = Provider.of<BingoController>(context, listen: false);
        controller.checkForBingo(
            context); // Ensure bingo is checked immediately after marking
      },
      child: Container(
        decoration: BoxDecoration(
          color: marked ? Colors.red : Colors.blueAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
