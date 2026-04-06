import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/features/reminder/presentation/provider/reminder_provider.dart';
import 'package:money_tracker/general/models/bill_reminder.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();

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
          'Bill Reminders',
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
          child: Column(
            children: [
              _buildUpcomingSummary(provider),
              const SizedBox(height: 20),
              Expanded(
                child: provider.isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : provider.reminders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: provider.reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = provider.reminders[index];
                          return _buildReminderTile(context, provider, reminder);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderSheet(context),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add_alert_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildUpcomingSummary(ReminderProvider provider) {
    final unpaidCount = provider.reminders.where((r) => !r.isPaid).length;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 100,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
        ),
        borderGradient: LinearGradient(
          colors: [Colors.white.withAlpha(100), Colors.blueGrey.withAlpha(100)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month_rounded, color: Colors.white60, size: 30),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unpaidCount == 0 ? 'All caught up!' : '$unpaidCount Pending Bills',
                  style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  unpaidCount == 0 ? 'No upcoming payments' : 'Keep tracking your due dates',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.white.withAlpha(25)),
          const SizedBox(height: 20),
          Text(
            'No reminders set.',
            style: GoogleFonts.lexend(fontSize: 18, color: Colors.white38),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add your bills to never miss a payment.',
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(BuildContext context, ReminderProvider provider, BillReminder reminder) {
    final bool isOverdue = !reminder.isPaid && reminder.dueDate.isBefore(DateTime.now());
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(reminder.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => provider.deleteReminder(reminder.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withAlpha(50),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 90,
          borderRadius: 20,
          blur: 15,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            colors: [Colors.white.withAlpha(reminder.isPaid ? 5 : 15), Colors.white.withAlpha(5)],
          ),
          borderGradient: LinearGradient(
            colors: [Colors.white.withAlpha(51), Colors.white10],
          ),
          child: ListTile(
            leading: _buildDateBadge(reminder.dueDate, isOverdue, reminder.isPaid),
            title: Text(
              reminder.title,
              style: GoogleFonts.lexend(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: reminder.isPaid ? Colors.white38 : Colors.white,
                decoration: reminder.isPaid ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '₹${reminder.amount.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(color: reminder.isPaid ? Colors.white24 : Colors.white60),
            ),
            trailing: Checkbox(
              value: reminder.isPaid,
              activeColor: Colors.tealAccent,
              checkColor: Colors.black,
              onChanged: (_) => provider.markAsPaid(reminder.id),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(DateTime date, bool isOverdue, bool isPaid) {
    Color bgColor = isPaid ? Colors.white10 : (isOverdue ? Colors.redAccent.withAlpha(50) : Colors.tealAccent.withAlpha(50));
    Color textColor = isPaid ? Colors.white24 : (isOverdue ? Colors.redAccent : Colors.tealAccent);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd').format(date),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Bill Reminder',
                style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              _buildInput('Bill Title', Icons.title, _titleController),
              const SizedBox(height: 16),
              _buildInput('Amount', Icons.currency_rupee, _amountController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text('Create Reminder', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, IconData icon, TextEditingController controller, {TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          icon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: Color(0xFF6366F1), size: 20),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Due Date', style: TextStyle(color: Colors.white38, fontSize: 12)),
                Text(
                  DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveReminder() {
    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty) return;
    
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;

    context.read<ReminderProvider>().addReminder(
      title: _titleController.text.trim(),
      amount: amount,
      dueDate: _selectedDate,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder added!'), backgroundColor: Colors.teal),
    );
  }
}
