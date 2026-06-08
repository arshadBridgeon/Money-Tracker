import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class MoneyRecord extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final bool isIncome; // true for income, false for expense
  @HiveField(5)
  final String? weekId;

  MoneyRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.weekId,
  });
}
