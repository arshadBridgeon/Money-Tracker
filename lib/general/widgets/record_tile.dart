import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/general/models/transaction.dart';

class RecordTile extends StatelessWidget {
  final MoneyRecord record;

  const RecordTile({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 75,
        borderRadius: 16,
        blur: 15,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          colors: [Colors.white.withAlpha(15), Colors.white.withAlpha(8)],
        ),
        borderGradient: LinearGradient(
          colors: [Colors.white.withAlpha(76), Colors.white.withAlpha(25)],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: record.isIncome
                  ? Colors.teal.withAlpha(25)
                  : Colors.redAccent.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.currency_rupee_rounded,
              color: record.isIncome ? Colors.tealAccent : Colors.redAccent,
              size: 20,
            ),
          ),
          title: Text(
            record.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            DateFormat('hh:mm a').format(record.date),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          trailing: Text(
            '${record.isIncome ? '+' : '-'}\u20B9${record.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: record.isIncome ? Colors.tealAccent : Colors.redAccent,
            ),
          ),
        ),
      ),
    );
  }
}
