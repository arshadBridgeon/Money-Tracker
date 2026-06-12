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
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedWeekFilter; // null for All Weeks, 1 to 5 for specific week

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

    // Calculate active week's expense for the top card
    double activeWeekExpense = 0.0;
    String activeWeekExpenseLabel = '';

    if (_selectedWeekFilter != null) {
      final weekId = "${_selectedMonth.year}_${_selectedMonth.month}_$_selectedWeekFilter";
      final weekName = provider.getWeekName(weekId, _selectedWeekFilter!);
      activeWeekExpenseLabel = "$weekName Expense";
      activeWeekExpense = provider.transactions.where((tx) {
        return !tx.isIncome &&
            _getTxYear(tx) == _selectedMonth.year &&
            _getTxMonth(tx) == _selectedMonth.month &&
            _getTxWeekNum(tx) == _selectedWeekFilter;
      }).fold(0.0, (sum, tx) => sum + tx.amount);
    } else {
      final now = DateTime.now();
      final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
      if (isCurrentMonth) {
        final currentWeek = MoneyRecordProvider.getWeekOfMonth(now);
        final weekId = "${now.year}_${now.month}_$currentWeek";
        final weekName = provider.getWeekName(weekId, currentWeek);
        activeWeekExpenseLabel = "$weekName Expense (This Week)";
        activeWeekExpense = provider.transactions.where((tx) {
          return !tx.isIncome &&
              _getTxYear(tx) == now.year &&
              _getTxMonth(tx) == now.month &&
              _getTxWeekNum(tx) == currentWeek;
        }).fold(0.0, (sum, tx) => sum + tx.amount);
      } else {
        activeWeekExpenseLabel = "Monthly Expense";
        activeWeekExpense = provider.transactions.where((tx) {
          return !tx.isIncome &&
              _getTxYear(tx) == _selectedMonth.year &&
              _getTxMonth(tx) == _selectedMonth.month;
        }).fold(0.0, (sum, tx) => sum + tx.amount);
      }
    }

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

              // Fixed Top Card - TOTAL BALANCE & SELECTED/THIS WEEK EXPENSE
              Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: () => _showAllTimeHistorySheet(context, provider),
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: 170, // Increased height to accommodate the expense row
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total Available Balance',
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₹ ${provider.totalBalance.toStringAsFixed(0)}',
                            style: GoogleFonts.lexend(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          width: 120,
                          color: Colors.white12,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 15,
                              color: Colors.redAccent.withAlpha(200),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$activeWeekExpenseLabel: ',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                            Text(
                              '₹ ${activeWeekExpense.toStringAsFixed(0)}',
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent.withAlpha(220),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Month & Week Filters
              _buildMonthSelector(),
              const SizedBox(height: 8),
              _buildWeekChips(provider),
              const SizedBox(height: 16),

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
    final filteredRecords = _getFilteredAndSortedRecords(provider, showIncome);

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

    final double tabTotal = _calculateTabTotal(provider, showIncome);

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
                  _buildBudgetTracker(context, provider, showIncome),
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
    bool showIncome,
  ) {
    final monthIncome = provider.transactions.where((tx) {
      return tx.isIncome && 
             _getTxYear(tx) == _selectedMonth.year && 
             _getTxMonth(tx) == _selectedMonth.month;
    }).fold(0.0, (sum, tx) => sum + tx.amount);
    
    final monthExpense = provider.transactions.where((tx) {
      return !tx.isIncome && 
             _getTxYear(tx) == _selectedMonth.year && 
             _getTxMonth(tx) == _selectedMonth.month;
    }).fold(0.0, (sum, tx) => sum + tx.amount);
    
    final monthBalance = monthIncome - monthExpense;

    double income = monthIncome > 0 ? monthIncome : 1.0;
    
    // If showIncome is true, progress is the remaining balance percentage.
    // If showIncome is false, progress is the spent percentage of the income.
    double progress = showIncome 
        ? (monthBalance / income).clamp(0.0, 1.0)
        : (monthExpense / income).clamp(0.0, 1.0);

    Color progressColor = showIncome ? Colors.tealAccent : Colors.redAccent;
    if (showIncome) {
      if (progress < 0.3) {
        progressColor = Colors.redAccent;
      } else if (progress < 0.5) {
        progressColor = Colors.orangeAccent;
      }
    } else {
      if (progress > 0.8) {
        progressColor = Colors.redAccent;
      } else if (progress > 0.5) {
        progressColor = Colors.orangeAccent;
      } else {
        progressColor = Colors.tealAccent;
      }
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
                  showIncome 
                      ? 'Income: ₹${monthIncome.toStringAsFixed(0)}'
                      : 'Expense: ₹${monthExpense.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  showIncome 
                      ? '${(progress * 100).toInt()}% left'
                      : '${(progress * 100).toInt()}% spent',
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
              showIncome 
                  ? '₹${monthBalance.toStringAsFixed(0)} available for spending'
                  : '₹${monthExpense.toStringAsFixed(0)} spent out of ₹${monthIncome.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  int _getTxWeekNum(MoneyRecord tx) {
    if (tx.weekId != null) {
      final parts = tx.weekId!.split('_');
      if (parts.length == 3) {
        return int.tryParse(parts[2]) ?? MoneyRecordProvider.getWeekOfMonth(tx.date);
      }
    }
    return MoneyRecordProvider.getWeekOfMonth(tx.date);
  }

  int _getTxMonth(MoneyRecord tx) {
    if (tx.weekId != null) {
      final parts = tx.weekId!.split('_');
      if (parts.length == 3) {
        return int.tryParse(parts[1]) ?? tx.date.month;
      }
    }
    return tx.date.month;
  }

  int _getTxYear(MoneyRecord tx) {
    if (tx.weekId != null) {
      final parts = tx.weekId!.split('_');
      if (parts.length == 3) {
        return int.tryParse(parts[0]) ?? tx.date.year;
      }
    }
    return tx.date.year;
  }

  List<MoneyRecord> _getFilteredAndSortedRecords(MoneyRecordProvider provider, bool showIncome) {
    return provider.transactions.where((tx) {
      if (tx.isIncome != showIncome) return false;
      final txYear = _getTxYear(tx);
      final txMonth = _getTxMonth(tx);
      final txWeek = _getTxWeekNum(tx);
      
      final isSameMonth = txYear == _selectedMonth.year && txMonth == _selectedMonth.month;
      if (!isSameMonth) return false;
      
      if (_selectedWeekFilter != null && txWeek != _selectedWeekFilter) return false;
      
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double _calculateTabTotal(MoneyRecordProvider provider, bool showIncome) {
    final filtered = provider.transactions.where((tx) {
      if (tx.isIncome != showIncome) return false;
      final txYear = _getTxYear(tx);
      final txMonth = _getTxMonth(tx);
      final txWeek = _getTxWeekNum(tx);
      
      final isSameMonth = txYear == _selectedMonth.year && txMonth == _selectedMonth.month;
      if (!isSameMonth) return false;
      
      if (_selectedWeekFilter != null && txWeek != _selectedWeekFilter) return false;
      
      return true;
    });
    return filtered.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChips(MoneyRecordProvider provider) {
    return SizedBox(
      height: 95, // Taller container for the cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6, // All Weeks + 5 Weeks
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final weekNum = index; // 1 to 5
          final isSelected = isAll ? _selectedWeekFilter == null : _selectedWeekFilter == weekNum;
          
          final weekId = isAll ? "" : "${_selectedMonth.year}_${_selectedMonth.month}_$weekNum";
          final displayName = isAll ? "All Weeks" : provider.getWeekName(weekId, weekNum);

          // Calculate income and expense for this card
          double income = 0.0;
          double expense = 0.0;

          if (isAll) {
            income = provider.transactions.where((tx) {
              return tx.isIncome &&
                  _getTxYear(tx) == _selectedMonth.year &&
                  _getTxMonth(tx) == _selectedMonth.month;
            }).fold(0.0, (sum, tx) => sum + tx.amount);

            expense = provider.transactions.where((tx) {
              return !tx.isIncome &&
                  _getTxYear(tx) == _selectedMonth.year &&
                  _getTxMonth(tx) == _selectedMonth.month;
            }).fold(0.0, (sum, tx) => sum + tx.amount);
          } else {
            income = provider.transactions.where((tx) {
              return tx.isIncome &&
                  _getTxYear(tx) == _selectedMonth.year &&
                  _getTxMonth(tx) == _selectedMonth.month &&
                  _getTxWeekNum(tx) == weekNum;
            }).fold(0.0, (sum, tx) => sum + tx.amount);

            expense = provider.transactions.where((tx) {
              return !tx.isIncome &&
                  _getTxYear(tx) == _selectedMonth.year &&
                  _getTxMonth(tx) == _selectedMonth.month &&
                  _getTxWeekNum(tx) == weekNum;
            }).fold(0.0, (sum, tx) => sum + tx.amount);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedWeekFilter = isAll ? null : weekNum;
                });
              },
              child: GlassmorphicContainer(
                width: 150,
                height: 85,
                borderRadius: 16,
                blur: isSelected ? 20 : 0,
                alignment: Alignment.center,
                border: isSelected ? 1.5 : 0.5,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [const Color(0xFF6366F1).withAlpha(80), const Color(0xFF6366F1).withAlpha(30)]
                      : [Colors.white.withAlpha(12), Colors.white.withAlpha(5)],
                ),
                borderGradient: LinearGradient(
                  colors: isSelected
                      ? [const Color(0xFF6366F1).withAlpha(150), const Color(0xFF6366F1).withAlpha(50)]
                      : [Colors.white24, Colors.white10],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Week Name & Edit Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isAll && isSelected)
                            GestureDetector(
                              onTap: () => _showRenameWeekDialog(context, provider, weekId, weekNum),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 13,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Subtracted balance info
                      Row(
                        children: [
                          Icon(
                            (income - expense) >= 0 ? Icons.account_balance_wallet_rounded : Icons.warning_amber_rounded,
                            size: 11,
                            color: (income - expense) >= 0 ? Colors.tealAccent : Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bal: ',
                            style: GoogleFonts.lexend(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${(income - expense) < 0 ? '-' : ''}₹${(income - expense).abs().toStringAsFixed(0)}',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (income - expense) >= 0 ? Colors.tealAccent : Colors.redAccent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Small Details Row (Inc / Exp)
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.lexend(
                                  fontSize: 9,
                                  color: Colors.white38,
                                ),
                                children: [
                                  const TextSpan(text: 'In: '),
                                  TextSpan(
                                    text: '₹${income.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.tealAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const TextSpan(text: ' | Ex: '),
                                  TextSpan(
                                    text: '₹${expense.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRenameWeekDialog(BuildContext context, MoneyRecordProvider provider, String weekId, int weekNum) {
    final controller = TextEditingController(text: provider.getWeekName(weekId, weekNum));
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
                    colors: [
                      Colors.white.withAlpha(20),
                      Colors.white.withAlpha(5),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(100),
                      const Color(0xFF6366F1).withAlpha(100),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rename Week $weekNum',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter week name',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
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
                                if (controller.text.trim().isNotEmpty) {
                                  provider.updateWeekName(
                                    weekId,
                                    controller.text.trim(),
                                    weekNum,
                                    _selectedMonth.month,
                                    _selectedMonth.year,
                                  );
                                }
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Save'),
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

  Widget _buildWeeklyBreakdownCarousel(BuildContext context, MoneyRecordProvider provider) {
    final List<Widget> cards = [];
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    
    for (int weekNum = 1; weekNum <= 5; weekNum++) {
      final weekId = "${_selectedMonth.year}_${_selectedMonth.month}_$weekNum";
      final weekName = provider.getWeekName(weekId, weekNum);

      final weekIncome = provider.transactions.where((tx) {
        return tx.isIncome &&
            _getTxYear(tx) == _selectedMonth.year &&
            _getTxMonth(tx) == _selectedMonth.month &&
            _getTxWeekNum(tx) == weekNum;
      }).fold(0.0, (sum, tx) => sum + tx.amount);

      final weekExpense = provider.transactions.where((tx) {
        return !tx.isIncome &&
            _getTxYear(tx) == _selectedMonth.year &&
            _getTxMonth(tx) == _selectedMonth.month &&
            _getTxWeekNum(tx) == weekNum;
      }).fold(0.0, (sum, tx) => sum + tx.amount);

      final weekBalance = weekIncome - weekExpense;

      cards.add(
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GlassmorphicContainer(
            width: 180,
            height: 95,
            borderRadius: 16,
            blur: 15,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              colors: [Colors.white.withAlpha(12), Colors.white.withAlpha(6)],
            ),
            borderGradient: LinearGradient(
              colors: [Colors.white24, Colors.white10],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    weekName,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        'Bal: ',
                        style: TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                      Text(
                        '${weekBalance < 0 ? '-' : ''}₹${weekBalance.abs().toStringAsFixed(0)}',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: weekBalance >= 0 ? Colors.tealAccent : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 10, color: Colors.tealAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                                children: [
                                  const TextSpan(text: 'Inc: '),
                                  TextSpan(
                                    text: '₹${weekIncome.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 10, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                                children: [
                                  const TextSpan(text: 'Exp: '),
                                  TextSpan(
                                    text: '₹${weekExpense.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Weekly Breakdown ($monthName)',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 105,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            children: cards,
          ),
        ),
      ],
    );
  }

  void _showAllTimeHistorySheet(BuildContext context, MoneyRecordProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final allRecords = provider.transactions;
        final totalIncome = provider.totalIncome;
        final totalExpense = provider.totalExpense;
        final totalBalance = provider.totalBalance;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.75,
            borderRadius: 30,
            blur: 30,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withAlpha(25), Colors.white.withAlpha(5)],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withAlpha(100), Colors.blueGrey.withAlpha(100)],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All-Time History',
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Summary Stats Card inside Sheet
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Income', '₹${totalIncome.toStringAsFixed(0)}', Colors.tealAccent),
                        _buildStatItem('Expense', '₹${totalExpense.toStringAsFixed(0)}', Colors.redAccent),
                        _buildStatItem('Balance', '₹${totalBalance.toStringAsFixed(0)}', Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Weekly Breakdown Carousel
                _buildWeeklyBreakdownCarousel(context, provider),
                const SizedBox(height: 20),
                
                // Transactions List
                Expanded(
                  child: allRecords.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions found.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: allRecords.length,
                          itemBuilder: (context, index) {
                            final tx = allRecords[index];
                            final weekNum = _getTxWeekNum(tx);
                            final weekId = "${_getTxYear(tx)}_${_getTxMonth(tx)}_$weekNum";
                            final weekName = provider.getWeekName(weekId, weekNum);
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: tx.isIncome 
                                        ? Colors.tealAccent.withAlpha(30) 
                                        : Colors.redAccent.withAlpha(30),
                                    child: Icon(
                                      tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: tx.isIncome ? Colors.tealAccent : Colors.redAccent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: GoogleFonts.lexend(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${DateFormat('dd MMM yyyy').format(tx.date)} • $weekName",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${tx.isIncome ? '+' : '-'} ₹${tx.amount.toStringAsFixed(0)}",
                                    style: GoogleFonts.lexend(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: tx.isIncome ? Colors.tealAccent : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
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
