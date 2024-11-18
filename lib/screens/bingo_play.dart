import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/bingo_controller.dart';

class BingoCardScreen extends StatelessWidget {
  const BingoCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BingoController(),
      child: Consumer<BingoController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(title: Text('Bingo Card')),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: controller.spinsLeft > 0 && controller.betAmount == 0
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
                                        decoration: const InputDecoration(labelText: 'Bet Amount'),
                                        onChanged: (value) {
                                          final bet = int.tryParse(value);
                                          if (bet != null) {
                                            controller.updateBetAmount(bet); // Update bet amount without placing the bet
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () {
                                          controller.placeBet(controller.betAmount); // Place the bet when confirmed
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
                ),
                Text(
                  controller.currentBall != null
                      ? 'Current Ball: ${controller.currentBall}'
                      : 'Spin to Start!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: controller.betAmount > 0
                        ? controller.spinBall
                        : null,
                    child: Text(controller.spinsLeft > 0
                        ? 'Spin (${controller.spinsLeft} spins left)'
                        : 'No Spins Left'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Credits: ${controller.userCredits}'),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          marked: controller.markedNumbers.contains(int.tryParse(cellValue)),
                          onTap: () {
                            if (cellValue != "Free") {
                              controller.markNumber(cellValue);
                              controller.checkForBingo(() {
                                showDialog(
                                  context: context,
                                  builder: (context) => const AlertDialog(
                                    title: Text('Bingo!'),
                                    content: Text('Congratulations! You won!'),
                                  ),
                                );
                              });
                            }
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
      onTap: onTap,
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
