import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:money_tracker/features/auth/presentation/provider/auth_provider.dart';
import 'package:money_tracker/features/dashboard/presentation/provider/money_record_provider.dart';
import 'package:money_tracker/general/widgets/add_record_bottom_sheet.dart';
import 'package:money_tracker/general/widgets/record_tile.dart';
import 'package:money_tracker/general/utils/app_deteiles.dart';
import 'package:money_tracker/features/dashboard/presentation/view/stats_screen.dart';
import 'package:money_tracker/features/dashboard/presentation/view/settings_screen.dart';
import 'package:money_tracker/features/auth/presentation/view/profile_settings_screen.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/features/reminder/presentation/view/reminder_screen.dart';
import 'package:money_tracker/features/reminder/presentation/provider/reminder_provider.dart';
import 'package:money_tracker/features/dashboard/presentation/view/about_screen.dart';
import 'package:money_tracker/general/models/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      key: _scaffoldKey,
      drawer: _buildDrawer(context, auth),
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
                    IconButton(
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
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
                    Consumer<ReminderProvider>(
                      builder: (context, reminders, _) {
                        final count = reminders.overdueCount;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (count > 0) {
                                  _showOverdueDialog(context, reminders);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ReminderScreen(),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                count > 0
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                color: count > 0
                                    ? Colors.orangeAccent
                                    : Colors.white70,
                                size: 28,
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
                    colors: [
                      Colors.white.withAlpha(20),
                      Colors.white.withAlpha(10),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(100),
                      Colors.blueGrey.withAlpha(100),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Available Balance',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹ ${provider.totalBalance.toStringAsFixed(0)}',
                          style: GoogleFonts.lexend(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                          labelStyle: GoogleFonts.lexend(
                            fontWeight: FontWeight.bold,
                          ),
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
    final filteredRecords = provider.getFilteredTransactions(showIncome);

    final Map<DateTime, List<MoneyRecord>> groupedByDate = {};
    for (var tx in filteredRecords) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(tx);
    }

    final List<DateTime> sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final double tabTotal = showIncome
        ? provider.totalIncome
        : provider.totalExpense;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            provider.hasMore(showIncome)) {
          context.read<MoneyRecordProvider>().fetchMoreTransactions(showIncome);
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => provider.fetchTransactions(),
        color: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF1E293B),
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabSummaryCard(showIncome, tabTotal),
                  const SizedBox(height: 24),
                  Text(
                    'Monthly Budget Capacity',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBudgetTracker(context, provider),
                  const SizedBox(height: 24),
                  Text(
                    showIncome ? 'Income History' : 'Expense History',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          if (filteredRecords.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No records found.',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            ...sortedDates.expand(
              (date) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Text(
                      _formatDateHeader(date),
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final record = groupedByDate[date]![index];
                    final originalIndexInProvider = provider.transactions
                        .indexWhere((t) => t.id == record.id);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      child: Dismissible(
                        key: Key(record.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) =>
                            _showDeleteConfirmation(context, record.title),
                        onDismissed: (_) {
                          provider.deleteTransaction(originalIndexInProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${record.title} removed'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        background: _buildDismissBackground(),
                        child: RecordTile(
                          record: record,
                          onTap: () => _showAddRecordSheet(context, record: record),
                        ),
                      ),
                    );
                  }, childCount: groupedByDate[date]!.length),
                ),
              ],
            ),

          // Loader Sliver
          if (provider.isLoadingMore && provider.hasMore(showIncome))
            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 24),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Version ${AppDetails.appVersion}',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: Colors.white24,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    ),
  );
}

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';
    return DateFormat('EEE, dd MMM yyyy').format(date);
  }

  Widget _buildTabSummaryCard(bool showIncome, double tabTotal) {
    return GlassmorphicContainer(
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
          Icon(
            showIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: showIncome ? Colors.tealAccent : Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Text(
            showIncome ? 'Total Income: ' : 'Total Expense: ',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            '₹${tabTotal.toStringAsFixed(0)}',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetTracker(
    BuildContext context,
    MoneyRecordProvider provider,
  ) {
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
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
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
              '₹${balance.toStringAsFixed(0)} available for spending',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecordSheet(BuildContext context, {MoneyRecord? record}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddRecordSheet(record: record),
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
                  height: 250,
                  borderRadius: 24,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(20),
                      Colors.white.withAlpha(5),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(100),
                      Colors.redAccent.withAlpha(100),
                    ],
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
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<AuthProvider>().logout();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Profile Info Header
            _buildGlassAvatar(auth.currentUser?.name ?? 'User'),
            const SizedBox(height: 20),
            Text(
              auth.currentUser?.name ?? 'Guest User',
              style: GoogleFonts.lexend(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              auth.currentUser?.phoneNumber ?? 'No phone associated',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 40),
            const Divider(color: Colors.white10),

            // Menu Items
            _buildDrawerItem(
              icon: Icons.person_outline_rounded,
              title: 'Profile Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.history_rounded,
              title: 'Transaction History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications_active_rounded,
              title: 'Bill Reminders',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReminderScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'App Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.info_outline_rounded,
              title: 'About this App',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),

            const Spacer(),

            // Logout Button at Bottom
            Padding(
              padding: const EdgeInsets.all(24),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutWarning(context);
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.redAccent.withAlpha(51)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Text(
              'Money Tracker v${AppDetails.appVersion}',
              style: GoogleFonts.lexend(fontSize: 10, color: Colors.white24),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
      ),
      onTap: onTap,
    );
  }

  void _showOverdueDialog(BuildContext context, ReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              Text(
                'Payment Alerts',
                style: GoogleFonts.lexend(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.overdueReminders.length,
              itemBuilder: (context, index) {
                final bill = provider.overdueReminders[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    bill.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Overdue since ${DateFormat('MMM dd').format(bill.dueDate)}',
                    style: const TextStyle(color: Colors.white38),
                  ),
                  trailing: Text(
                    '₹${bill.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Dismiss',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReminderScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text(
                'Manage Bills',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SingleChildScrollView(
                child: GlassmorphicContainer(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 250, // Increased height to prevent overflow
                  borderRadius: 24,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(20),
                      Colors.white.withAlpha(5),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(100),
                      Colors.redAccent.withAlpha(100),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Delete Record?',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Are you sure you want to delete "$title"?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
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
