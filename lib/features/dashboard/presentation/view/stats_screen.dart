import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/features/dashboard/presentation/provider/money_record_provider.dart';
import 'package:money_tracker/general/models/transaction.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isMonthly = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoneyRecordProvider>();
    final transactions = provider.transactions;
    final data = _isMonthly 
        ? _getMonthlyExpenses(transactions) 
        : _getDailyExpenses(transactions);
        
    final maxData = _getMaxSpending(data);
    final stats = _calculateOverviewStats(transactions);
    final topExpensiveRecord = _getTopExpensiveRecord(transactions);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Expense Analytics',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Summary
                _buildOverviewSection(stats),
                
                const SizedBox(height: 32),
                
                // Filter Toggle
                _buildFilterToggle(),
                
                const SizedBox(height: 32),
                
                // Analytics Graph Card
                Text(
                  _isMonthly ? 'Monthly Spending Overview' : 'Daily Spending Overview',
                  style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                
                GlassmorphicContainer(
                  width: double.infinity,
                  height: 320,
                  borderRadius: 24,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
                  ),
                  borderGradient: LinearGradient(
                    colors: [Colors.white.withAlpha(51), Colors.blueAccent.withAlpha(51)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: data.isEmpty 
                      ? const Center(child: Text('No data recorded yet', style: TextStyle(color: Colors.white38)))
                      : _buildBarChart(data),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Highlight Cards Row
                if (maxData != null)
                  _buildHighlightCard(maxData),
                
                const SizedBox(height: 20),
                
                if (topExpensiveRecord != null)
                  _buildExpensiveItemCard(topExpensiveRecord),
                
                const SizedBox(height: 32),
                
                // Breakdown List
                Text(
                  _isMonthly ? 'Monthly Breakdown' : 'Daily Breakdown (This Month)',
                  style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return _buildDataTile(item, item.label == maxData?.label);
                  },
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, double> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Annual Overview (${DateTime.now().year})',
          style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMiniStatCard('Income', stats['income']!, Colors.tealAccent)),
            const SizedBox(width: 16),
            Expanded(child: _buildMiniStatCard('Expense', stats['expense']!, Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 16),
        _buildMiniStatCard('Total Savings', stats['savings']!, Colors.blueAccent, isFullWidth: true),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, double amount, Color color, {bool isFullWidth = false}) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 90,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withAlpha(12), Colors.white.withAlpha(8)],
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white.withAlpha(51), color.withAlpha(51)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '₹${amount.toStringAsFixed(0)}',
              style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensiveItemCard(MoneyRecord record) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orangeAccent.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: Colors.orangeAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Most Expensive Item', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
                Text(
                  record.title,
                  style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '₹${record.amount.toStringAsFixed(0)}',
            style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateOverviewStats(List<MoneyRecord> transactions) {
    double income = 0;
    double expense = 0;
    final year = DateTime.now().year;

    for (var tx in transactions) {
      if (tx.date.year == year) {
        if (tx.isIncome) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
    }
    return {
      'income': income,
      'expense': expense,
      'savings': income - expense,
    };
  }

  MoneyRecord? _getTopExpensiveRecord(List<MoneyRecord> transactions) {
    if (transactions.isEmpty) return null;
    final expenses = transactions.where((tx) => !tx.isIncome).toList();
    if (expenses.isEmpty) return null;
    return expenses.reduce((curr, next) => curr.amount > next.amount ? curr : next);
  }

  Widget _buildFilterToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMonthly = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _isMonthly ? const Color(0xFF6366F1) : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Monthly',
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold, 
                    color: _isMonthly ? Colors.white : Colors.white38
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMonthly = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: !_isMonthly ? const Color(0xFF6366F1) : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Daily',
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold, 
                    color: !_isMonthly ? Colors.white : Colors.white38
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ChartData> _getMonthlyExpenses(List<MoneyRecord> transactions) {
    final Map<String, double> tempMap = {};
    final now = DateTime.now();
    
    for (var tx in transactions) {
      if (!tx.isIncome && tx.date.year == now.year) {
        String monthKey = DateFormat('MMM').format(tx.date);
        tempMap[monthKey] = (tempMap[monthKey] ?? 0.0) + tx.amount;
      }
    }

    final List<String> monthsInOrder = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final List<ChartData> result = [];
    
    for (var month in monthsInOrder) {
      if (tempMap.containsKey(month)) {
        result.add(ChartData(label: month, amount: tempMap[month]!));
      }
    }
    return result;
  }

  List<ChartData> _getDailyExpenses(List<MoneyRecord> transactions) {
    final Map<int, double> tempMap = {};
    final now = DateTime.now();
    
    for (var tx in transactions) {
      if (!tx.isIncome && tx.date.year == now.year && tx.date.month == now.month) {
        tempMap[tx.date.day] = (tempMap[tx.date.day] ?? 0.0) + tx.amount;
      }
    }

    final List<ChartData> result = [];
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      if (tempMap.containsKey(day)) {
        result.add(ChartData(label: 'Day $day', amount: tempMap[day]!));
      }
    }
    return result;
  }

  ChartData? _getMaxSpending(List<ChartData> data) {
    if (data.isEmpty) return null;
    return data.reduce((curr, next) => curr.amount > next.amount ? curr : next);
  }

  Widget _buildBarChart(List<ChartData> data) {
    double maxAmount = data.isNotEmpty ? data.map((e) => e.amount).reduce((a, b) => a > b ? a : b) : 1000;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmount * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[groupIndex].label}\n₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < data.length) {
                  if (!_isMonthly && data.length > 10 && index % 5 != 0 && index != data.length - 1) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[index].label.replaceAll('Day ', ''),
                      style: GoogleFonts.lexend(color: Colors.white54, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.amount,
                color: const Color(0xFF6366F1),
                width: _isMonthly ? 16 : 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxAmount * 1.2,
                  color: Colors.white.withAlpha(12),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHighlightCard(ChartData max) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highest Transaction Gap',
                  style: GoogleFonts.lexend(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '${max.label} peak ₹${max.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.lexend(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTile(ChartData data, bool isMax) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(isMax ? 20 : 12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(isMax ? 51 : 25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isMax ? Colors.orangeAccent : Colors.tealAccent).withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  data.label.replaceAll('Day ', '').substring(0, 1),
                  style: TextStyle(color: isMax ? Colors.orangeAccent : Colors.tealAccent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                data.label,
                style: GoogleFonts.lexend(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${data.amount.toStringAsFixed(2)}',
                style: GoogleFonts.lexend(
                  color: isMax ? Colors.orangeAccent : Colors.white, 
                  fontSize: 16, 
                  fontWeight: FontWeight.bold
                ),
              ),
              if (isMax)
                Text(
                  'Peak Period',
                  style: GoogleFonts.lexend(color: Colors.orangeAccent.withAlpha(150), fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String label;
  final double amount;

  ChartData({required this.label, required this.amount});
}
