import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:money_tracker/firebase_options.dart';
import 'package:money_tracker/features/dashboard/presentation/provider/money_record_provider.dart';
import 'package:money_tracker/features/auth/presentation/provider/auth_provider.dart';
import 'package:money_tracker/features/reminder/presentation/provider/reminder_provider.dart';
import 'package:money_tracker/general/models/transaction.dart';
import 'package:money_tracker/general/models/user.dart';
import 'package:money_tracker/general/models/bill_reminder.dart';
import 'package:money_tracker/general/models/custom_week.dart';
import 'package:money_tracker/features/dashboard/presentation/provider/settings_provider.dart';
import 'package:money_tracker/features/dashboard/presentation/view/home_screen.dart';
import 'package:money_tracker/features/auth/presentation/view/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(MoneyRecordAdapter());
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(BillReminderAdapter());
  Hive.registerAdapter(CustomWeekAdapter());

  // Note: We don't pre-open boxes here as they are user-specific now

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(
          create: (_) => MoneyRecordProvider()..fetchTransactions(),
        ),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..init()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MoneyTrackerApp(),
    ),
  );
}

class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Money Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          primary: const Color(0xFF6366F1),
          secondary: Colors.teal,
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
