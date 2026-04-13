import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:money_tracker/general/utils/app_deteiles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About this App',
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
                // App Logo & Version Section
                Center(
                  child: Column(
                    children: [
                      GlassmorphicContainer(
                        width: 100,
                        height: 100,
                        borderRadius: 25,
                        blur: 20,
                        alignment: Alignment.center,
                        border: 2,
                        linearGradient: LinearGradient(
                          colors: [Colors.white.withAlpha(25), Colors.white.withAlpha(12)],
                        ),
                        borderGradient: LinearGradient(
                          colors: [Colors.white.withAlpha(100), Colors.blueAccent.withAlpha(100)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/app_logo2.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Money Tracker',
                        style: GoogleFonts.lexend(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Version ${AppDetails.appVersion}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white38,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Introduction
                _buildSectionHeader('What is Money Tracker?'),
                _buildContentText(
                  'Money Tracker is a smart and intuitive financial management tool designed to help you regain control over your personal finances. Whether you want to track daily expenses, monitor your income, or set financial goals, this app provides the perfect balance of simplicity and power.',
                ),

                const SizedBox(height: 32),

                // Core Features
                _buildSectionHeader('Key Features'),
                _buildFeatureItem(Icons.cloud_sync_rounded, 'Cloud Sync', 'Your data is securely backed up in the cloud and synced across all your devices.'),
                _buildFeatureItem(Icons.offline_pin_rounded, 'Offline First', 'Keep tracking even without internet. Data syncs automatically once you\'re back online.'),
                _buildFeatureItem(Icons.bar_chart_rounded, 'Detailed Analytics', 'Visualize your spending habits with intuitive charts and daily/monthly breakdowns.'),
                _buildFeatureItem(Icons.notifications_active_rounded, 'Bill Reminders', 'Never miss a payment again with our smart bill notification system.'),
                _buildFeatureItem(Icons.security_rounded, 'Privacy Protected', 'Your financial data is private and secured with industry-standard encryption.'),

                const SizedBox(height: 32),

                // How to Use
                _buildSectionHeader('How to use the App'),
                _buildStepItem('1', 'Add Transactions', 'Tap the "+" button on the home screen to log a new income or expense. Enter the title, amount, and date.'),
                _buildStepItem('2', 'Monitor Balance', 'Total balance and budget capacity are calculated automatically from your records.'),
                _buildStepItem('3', 'Review History', 'Use the tabs on the home screen to see your transaction breakdown by day.'),
                _buildStepItem('4', 'Analyze Spending', 'Go to "Transaction History" in the drawer to see deep visual analytics of your habits.'),

                const SizedBox(height: 40),

                // Footer
                Center(
                  child: Text(
                    '© 2026 Arshad. All Rights Reserved.',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildContentText(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: Colors.white70,
        height: 1.6,
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha(51),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6366F1)),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
