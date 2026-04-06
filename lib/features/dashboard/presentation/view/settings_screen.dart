import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:money_tracker/general/utils/app_deteiles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'App Settings',
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
                _buildSectionTitle('Preferences'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.currency_rupee_rounded,
                  title: 'Default Currency',
                  subtitle: 'Indian Rupee (INR)',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Reminders',
                  subtitle: 'Enabled',
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('Security'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Lock',
                  subtitle: 'Disabled',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.password_rounded,
                  title: 'Change App Pin',
                  subtitle: 'Set a 4-digit security pin',
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('Data Storage'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.cloud_done_rounded,
                  title: 'Cloud Sync',
                  subtitle: 'Last synced: Just now',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Clear Local Cache',
                  subtitle: 'Frees up storage space',
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('App Info'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Money Tracker',
                  subtitle: 'Version ${AppDetails.appVersion}',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Rate the App',
                  subtitle: 'Support us on App Store',
                  onTap: () {},
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
