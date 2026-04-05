import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class AppUser extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String phoneNumber;
  @HiveField(3)
  final double initialBalance;
  @HiveField(4)
  final DateTime joinedDate;

  AppUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.initialBalance,
    required this.joinedDate,
  });
}
