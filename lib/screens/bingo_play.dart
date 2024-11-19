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
                automaticallyImplyLeading: false,
                title: const Text(
                  'Bingo Mania',
                  style:
                      TextStyle(fontFamily: 'Bingo', color: Color(0xffb22222)),
                ),
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
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/images/bgplay.png'), // Replace with your image path
                    fit: BoxFit.cover, // Adjust how the image is fitted
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: controller.currentNumber != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Current Ball: ',
                                  style: const TextStyle(
                                    color: Color(0xffffaabb),
                                    fontFamily: 'Bingo',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/${controller.currentNumber!.replaceAll(' ', '')}.png',
                                  width: 50,
                                  height: 50,
                                ),
                              ],
                            )
                          : Text(
                              'Spin to Start!',
                              style: const TextStyle(
                                color: Color(0xffffaabb),
                                fontFamily: 'Bingo',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    // Credits display (Placed right after the current ball)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Credits: ${controller.userCredits}.00 PHP',
                        style: const TextStyle(
                          color: Color(0xffffaabb),
                          fontFamily: 'Bingo',
                          fontSize: 18,
                        ),
                      ),
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
                            final cellValue =
                                controller.bingoCardNumbers[col][row];
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
                      padding: const EdgeInsets.all(5.0),
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
                                          title: const Text('Place Bet',
                                              style: const TextStyle(
                                                color: Color(0xffb22222),
                                                fontFamily: 'Bingo',
                                              )),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText: 'Bet Amount',
                                                        labelStyle: TextStyle(
                                                          color:
                                                              Color(0xffb22222),
                                                          fontFamily: 'Bingo',
                                                        )),
                                                onChanged: (value) {
                                                  final bet =
                                                      int.tryParse(value);
                                                  if (bet != null) {
                                                    controller
                                                        .updateBetAmount(bet);
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
                                                child: const Text('Confirm Bet',
                                                    style: const TextStyle(
                                                      color: Color(0xffb22222),
                                                      fontFamily: 'Bingo',
                                                    )),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                : null,
                            child: Text(
                                controller.betAmount == 0
                                    ? 'Place Bet'
                                    : 'Bet Placed: ${controller.betAmount}',
                                style: const TextStyle(
                                  color: Color(0xffffaabb),
                                  fontFamily: 'Bingo',
                                )),
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
                            child: Text(
                                controller.spinsLeft > 0
                                    ? '${controller.spinsLeft} spins left'
                                    : 'No Spins Left',
                                style: const TextStyle(
                                  color:  Color(
                                    0xffb22222),
                                  fontFamily: 'Bingo',
                                )),
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
                                activeColor: Color(
                                    0xffb22222), // Color for the thumb when active
                                inactiveTrackColor: Colors
                                    .grey, // Color for the track when inactive
                                inactiveThumbColor: Colors
                                    .white, 
                              ),
                              const Text('Auto Daub',
                                  style: TextStyle(
                                    color: Color(0xffffaabb),
                                    fontFamily: 'Bingo',
                                  )),
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
                                            'Place a bet before enabling autoplay!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Bingo',
                                            )),
                                      ),
                                    );
                                  }
                                },
                                activeColor: Color(
                                    0xffb22222), // Color for the thumb when active
                                inactiveTrackColor: Colors
                                    .grey, // Color for the track when inactive
                                inactiveThumbColor: Colors
                                    .white, // Color for the thumb when inactive
                              ),
                              const Text('Auto Play',
                                  style: TextStyle(
                                    color: Color(0xffffaabb),
                                    fontFamily: 'Bingo',
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ));
        },
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout Confirmation',
              style: const TextStyle(
                fontFamily: 'Bingo',
              )),
          content: const Text('Are you sure you want to log out?',
              style: const TextStyle(
                fontFamily: 'Bingo',
              )),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text('Cancel',
                  style: const TextStyle(
                    fontFamily: 'Bingo',
                  )),
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
              child: const Text('Logout',
                  style: const TextStyle(
                    fontFamily: 'Bingo',
                  )),
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
          title: const Text('Exit Confirmation',
              style: const TextStyle(
                fontFamily: 'Bingo',
              )),
          content: const Text(
              'Are you sure you want to exit the app? Your progress will be saved.',
              style: const TextStyle(
                fontFamily: 'Bingo',
              )),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel',
                  style: const TextStyle(
                    fontFamily: 'Bingo',
                  )),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit',
                  style: const TextStyle(
                    fontFamily: 'Bingo',
                  )),
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
    final List<String> imageNames = [
      'assets/images/BingoBall/1.png', // Image for 'B'
      'assets/images/BingoBall/2.png', // Image for 'I'
      'assets/images/BingoBall/3.png', // Image for 'N'
      'assets/images/BingoBall/4.png', // Image for 'G'
      'assets/images/BingoBall/5.png', // Image for 'O'
    ];

    return Container(
      child: Center(
        child: Image.asset(
          imageNames[index], // Use the image based on the index
          width: 60, // Adjust width and height as needed
          height: 60,
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
      onTap: value != "Free" ? onTap : null, // Ignore taps on "Free" cells
      child: Container(
        decoration: BoxDecoration(
          color: value == "Free"
              ? Color(0xffb22222) // Green background for "Free" cell
              : (marked ? Color(0xffb22222) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: marked
              ? Border.all(color: Colors.green, width: 2)
              : Border.all(color: Colors.grey, width: 1),
        ),
        child: value == "Free"
            ? Center(
                child: Text(
                  "Free",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontFamily: 'Bingo'),
                ),
              )
            : Image.asset(
                'assets/images/$value.png', // Path to the number image
                fit: BoxFit.contain, // Ensure image fits within the cell
              ),
      ),
    );
  }
}
