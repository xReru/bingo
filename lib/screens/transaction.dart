import 'package:flutter/material.dart';
import '../controller/bingo_controller.dart';
import 'package:provider/provider.dart';

class TransactionDialog extends StatelessWidget {
  const TransactionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Choose Operation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => DepositDialog(),
              );
            },
            child: Text('Deposit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => WithdrawDialog(),
              );
            },
            child: Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}

class DepositDialog extends StatefulWidget {
  @override
  _DepositDialogState createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  String paymentType = 'Gcash';
  int amount = 200;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Deposit Credits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: paymentType,
            onChanged: (value) => setState(() => paymentType = value!),
            items: ['Gcash', 'Paymaya']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
          ),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value.isNotEmpty && int.tryParse(value) != null) {
                amount = int.parse(value);
              } else {
                amount = 0; // Reset to 0 or handle invalid input appropriately
              }
            },
            decoration: InputDecoration(labelText: 'Amount (min 200)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (amount >= 200) {
              final controller =
                  Provider.of<BingoController>(context, listen: false);
              controller.depositCredits(amount); 
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Minimum deposit is 200 credits.')),
              );
            }
          },
          child: Text('Deposit'),
        ),
      ],
    );
  }
}

class WithdrawDialog extends StatefulWidget {
  @override
  _WithdrawDialogState createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  String paymentType = 'Gcash';
  int amount = 1000;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Withdraw Credits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: paymentType,
            onChanged: (value) => setState(() => paymentType = value!),
            items: ['Gcash', 'Paymaya']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
          ),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) => amount = int.parse(value),
            decoration: InputDecoration(labelText: 'Amount (min 1000)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final controller =
                Provider.of<BingoController>(context, listen: false);
            final withdrawableAmount = amount * 0.98;

            if (amount >= 1000 && controller.userCredits >= amount) {
              final controller =
                  Provider.of<BingoController>(context, listen: false);
              controller.withdrawCredits(amount); 
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Withdraw successful: ${withdrawableAmount.toStringAsFixed(2)}')),
              );
            } else if (amount < 1000) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Minimum withdrawal is 1000 credits.')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Insufficient credits.')),
              );
            }
          },
          child: Text('Withdraw'),
        ),
      ],
    );
  }
}
