import 'package:hive/hive.dart';

part 'bill_reminder.g.dart';

@HiveType(typeId: 2)
class BillReminder extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final DateTime dueDate;
  @HiveField(4)
  bool isPaid;
  @HiveField(5)
  final DateTime createdAt;

  BillReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'dueDate': dueDate.toIso8601String(),
    'isPaid': isPaid,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BillReminder.fromJson(Map<String, dynamic> json) => BillReminder(
    id: json['id'],
    title: json['title'],
    amount: (json['amount'] as num).toDouble(),
    dueDate: DateTime.parse(json['dueDate']),
    isPaid: json['isPaid'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
