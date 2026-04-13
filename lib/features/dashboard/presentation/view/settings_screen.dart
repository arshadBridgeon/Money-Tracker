import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:money_tracker/features/dashboard/presentation/provider/money_record_provider.dart';
import 'package:money_tracker/features/dashboard/presentation/provider/settings_provider.dart';
import 'package:money_tracker/features/dashboard/presentation/view/about_screen.dart';
import 'package:money_tracker/general/utils/app_deteiles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final recordProvider = context.watch<MoneyRecordProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Settings',
          style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold, color: Colors.white),
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
                _buildSectionTitle('Preferences'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.currency_rupee_rounded,
                  title: 'Default Currency',
                  subtitle: settings.currency == 'INR'
                      ? 'Indian Rupee (INR)'
                      : settings.currency,
                  onTap: () => _showCurrencyPicker(context, settings),
                ),
                _buildSettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Reminders',
                  subtitle:
                      settings.remindersEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: settings.remindersEnabled,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (val) => settings.toggleReminders(val),
                  ),
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('Security'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Lock',
                  subtitle:
                      settings.biometricEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: settings.biometricEnabled,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (val) => settings.toggleBiometric(val),
                  ),
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.password_rounded,
                  title: 'Change App Pin',
                  subtitle: settings.hasPin ? 'PIN Setup' : 'Not Set',
                  onTap: () => _showPinDialog(context, settings),
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('Data Storage'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.cloud_done_rounded,
                  title: 'Cloud Sync',
                  subtitle: 'Sync manual data with Firestore',
                  onTap: () async {
                    _showLoadingSnackBar(context, 'Syncing with cloud...');
                    await recordProvider.fetchTransactions();
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Clear Local Cache',
                  subtitle: 'Reset local data and resync',
                  onTap: () =>
                      _showClearCacheDialog(context, recordProvider),
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('App Info'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Money Tracker',
                  subtitle: 'Version ${AppDetails.appVersion}',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Rate the App',
                  subtitle: 'Support us on App Store',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Store...')),
                    );
                  },
                ),

                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Money Tracker Premium',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Made with ❤️ for financial freedom',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final currencies = ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)'];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((c) {
              return ListTile(
                title: Text(c, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  settings.setCurrency(c.split(' ')[0]);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showPinDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Set 4-Digit PIN',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter PIN',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.length == 4) {
                settings.setPin(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(
      BuildContext context, MoneyRecordProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Clear Local Cache?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'This will remove local data and refetch from cloud. Recommended if you see sync issues.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.clearLocalCache();
              await provider.fetchTransactions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared & Resynced')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showLoadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 85,
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
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1)),
          ),
          title: Text(
            title,
            style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
          ),
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
        ),
      ),
    );
  }
}
