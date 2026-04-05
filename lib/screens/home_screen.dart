import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:money_tracker/providers/auth_provider.dart';
import 'package:money_tracker/providers/money_record_provider.dart';
import 'package:money_tracker/widgets/add_record_bottom_sheet.dart';
import 'package:money_tracker/widgets/record_tile.dart';
import 'package:money_tracker/core/appdeteiles/app_deteiles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<MoneyRecordProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- FIXED TOP SECTION ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    _buildGlassAvatar(auth.currentUser?.name ?? 'User'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.lexend(fontSize: 14, color: Colors.white70),
                          ),
                          Text(
                            auth.currentUser?.name ?? 'User',
                            style: GoogleFonts.lexend(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showLogoutWarning(context),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white60),
                    ),
                  ],
                ),
              ),

              // Fixed Top Card - ONLY TOTAL BALANCE
              Padding(
                padding: const EdgeInsets.all(24),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 140, // More compact
                  borderRadius: 24,
                  blur: 25,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(10)],
                  ),
                  borderGradient: LinearGradient(
                    colors: [Colors.white.withAlpha(100), Colors.blueGrey.withAlpha(100)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Total Available Balance', style: GoogleFonts.lexend(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹${provider.totalBalance.toStringAsFixed(2)}', 
                          style: GoogleFonts.lexend(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- SCROLLABLE BOTTOM SECTION WITH TABS ---
              Expanded(
                child: Column(
                  children: [
                    // Tab Bar Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF6366F1),
                          ),
                          labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white38,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Income'),
                            Tab(text: 'Expense'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildFilteredList(provider, true),
                          _buildFilteredList(provider, false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordSheet(context),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilteredList(MoneyRecordProvider provider, bool showIncome) {
    final filteredRecords = provider.transactions.where((tx) => tx.isIncome == showIncome).toList();
    final double tabTotal = showIncome ? provider.totalIncome : provider.totalExpense;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEPARATE SUMMARY PER TAB
          GlassmorphicContainer(
            width: double.infinity,
            height: 80,
            borderRadius: 16,
            blur: 15,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              colors: [Colors.white.withAlpha(12), Colors.white.withAlpha(8)],
            ),
            borderGradient: LinearGradient(
              colors: [Colors.white.withAlpha(51), Colors.white10],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(showIncome ? Icons.arrow_downward : Icons.arrow_upward, color: showIncome ? Colors.tealAccent : Colors.redAccent),
                const SizedBox(width: 12),
                Text(
                  showIncome ? 'Total Income: ' : 'Total Expense: ',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  '₹${tabTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Budget Tracker
          Text(
            'Monthly Budget Capacity',
            style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _buildBudgetTracker(context, provider),
          
          const SizedBox(height: 32),
          Text(
            showIncome ? 'Income History' : 'Expense History',
            style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (filteredRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  showIncome ? 'No income records found.' : 'No expense records found.',
                  style: const TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRecords.length,
              itemBuilder: (context, index) {
                final record = filteredRecords[index];
                // Finding original index for deletion in provider
                final originalIndex = provider.transactions.indexWhere((t) => t.id == record.id);
                
                return Dismissible(
                  key: Key(record.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    provider.deleteTransaction(originalIndex);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${record.title} removed'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: RecordTile(record: record),
                );
              },
            ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Version ${AppDetails.appVersion}',
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: Colors.white24,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGlassAvatar(String name) {
    return GlassmorphicContainer(
      width: 55,
      height: 55,
      borderRadius: 15,
      blur: 20,
      alignment: Alignment.center,
      border: 1.5,
      linearGradient: LinearGradient(
        colors: [Colors.white.withAlpha(25), Colors.white.withAlpha(12)],
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white.withAlpha(127), Colors.blueAccent.withAlpha(127)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/app_logo2.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetTracker(BuildContext context, MoneyRecordProvider provider) {
    double income = provider.totalIncome > 0 ? provider.totalIncome : 1.0;
    double balance = provider.totalBalance;
    double progress = (balance / income).clamp(0.0, 1.0);
    
    Color progressColor = Colors.tealAccent;
    if (progress < 0.3) {
      progressColor = Colors.redAccent;
    } else if (progress < 0.5) {
      progressColor = Colors.orangeAccent;
    }

    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withAlpha(15), Colors.white.withAlpha(8)],
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white.withAlpha(51), Colors.white10],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Income: ₹${provider.totalIncome.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '${(progress * 100).toInt()}% left',
                  style: TextStyle(color: progressColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.7 * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [progressColor, progressColor.withAlpha(150)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withAlpha(76),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹${balance.toStringAsFixed(2)} available for spending',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AddRecordSheet(),
    );
  }

  void _showLogoutWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: SingleChildScrollView(
                child: GlassmorphicContainer(
                  width: 320,
                  height: 220,
                  borderRadius: 24,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
                  ),
                  borderGradient: LinearGradient(
                    colors: [Colors.white.withAlpha(100), Colors.redAccent.withAlpha(100)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Logout Warning',
                          style: GoogleFonts.lexend(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Are you sure you want to log out from your account?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<AuthProvider>().logout();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
