import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:money_tracker/general/models/transaction.dart';
import 'package:money_tracker/features/dashboard/presentation/provider/money_record_provider.dart';

class AddRecordSheet extends StatefulWidget {
  final MoneyRecord? record;
  const AddRecordSheet({super.key, this.record});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isIncome = true;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _titleController.text = widget.record!.title;
      _amountController.text = widget.record!.amount.toString();
      _isIncome = widget.record!.isIncome;
      _selectedDate = widget.record!.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 480, // Dynamic height or slightly larger base
          borderRadius: 30,
          blur: 30,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withAlpha(102), Colors.blueGrey.withAlpha(102)],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.record == null ? 'Add Record' : 'Edit Record',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Record Title
                  _buildTextField(_titleController, 'Record Title', Icons.edit_note_rounded),
                  const SizedBox(height: 16),
                  
                  // Amount
                  _buildTextField(
                    _amountController,
                    'Amount',
                    Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  _buildDatePicker(),
                  const SizedBox(height: 24),
                  
                  // Income/Expense Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTypeToggle('Income', true, const Color(0xFF10B981)),
                      const SizedBox(width: 16),
                      _buildTypeToggle('Expense', false, const Color(0xFFF43F5E)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: () => _submitTransaction(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      widget.record == null ? 'Add Record' : 'Update Record',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withAlpha(12), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.white54),
            const SizedBox(width: 16),
            Text(
              DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String label, bool isIncome, Color activeColor) {
    bool isSelected = _isIncome == isIncome;
    return GestureDetector(
      onTap: () => setState(() => _isIncome = isIncome),
      child: GlassmorphicContainer(
        width: 130,
        height: 50,
        borderRadius: 16,
        blur: isSelected ? 30 : 0,
        alignment: Alignment.center,
        border: isSelected ? 2 : 1,
        linearGradient: LinearGradient(
          colors: isSelected ? [activeColor.withAlpha(76), activeColor.withAlpha(25)] : [Colors.white10, Colors.white10],
        ),
        borderGradient: LinearGradient(
          colors: isSelected ? [activeColor.withAlpha(153), activeColor.withAlpha(51)] : [Colors.white24, Colors.white10],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _submitTransaction(BuildContext context) {
    final title = _titleController.text;
    final amountText = _amountController.text;
    if (title.isEmpty || amountText.isEmpty) return;
    
    final amount = double.tryParse(amountText) ?? 0.0;
    
    if (widget.record != null) {
      final updatedRecord = MoneyRecord(
        id: widget.record!.id,
        title: title,
        amount: amount,
        date: _selectedDate,
        isIncome: _isIncome,
      );
      context.read<MoneyRecordProvider>().updateTransaction(updatedRecord);
    } else {
      final tx = MoneyRecord(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        date: _selectedDate,
        isIncome: _isIncome,
      );
      context.read<MoneyRecordProvider>().addTransaction(tx);
    }
    
    Navigator.of(context).pop();
  }
}
