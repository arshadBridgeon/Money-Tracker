import 'package:hive/hive.dart';

part 'custom_week.g.dart';

@HiveType(typeId: 3)
class CustomWeek extends HiveObject {
  @HiveField(0)
  final String id; // format: "year_month_weekNumber" (e.g. "2026_6_2")

  @HiveField(1)
  final String name; // custom name (e.g. "Rent Week", "Travel")

  @HiveField(2)
  final int weekNumber; // 1, 2, 3, 4, 5

  @HiveField(3)
  final int month; // 1-12

  @HiveField(4)
  final int year;

  CustomWeek({
    required this.id,
    required this.name,
    required this.weekNumber,
    required this.month,
    required this.year,
  });
}
