import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailor_desk_app/screens/income_report_screen.dart';
import 'package:tailor_desk_app/screens/login_screen.dart';
import 'package:tailor_desk_app/screens/order_history_screen.dart';
import 'package:tailor_desk_app/screens/update_profile_screen.dart';
import 'package:tailor_desk_app/widgets/app_header.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,

        // ── AppHeader ────────────────────────────────────────────────────────
        appBar: AppHeader(
          tailorName: 'Account',
          shopName: 'Manage your profile & settings',
          logoWidget: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.whiteOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.whiteOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          elevation: 6,
          toolbarHeight: 80,
          logoSize: 44,
        ),

        body: Column(
          children: [
            // ── Profile Card ──────────────────────────────────────────────
            _buildProfileCard(),
            
            // ── Menu Section ──────────────────────────────────────────────
            Expanded(
              child: _buildMenuSection(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile Card ───────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hashir',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'hashir@example.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Dev Tailor',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ── Menu Section ───────────────────────────────────────────────────────────
  Widget _buildMenuSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'GENERAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Update Profile ──────────────────────────────────────────────
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Update Profile',
            subtitle: 'Edit your personal information',
            color: const Color(0xFF1A6AE0),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Order History ───────────────────────────────────────────────
          _buildMenuItem(
            icon: Icons.receipt_long_rounded,
            title: 'Order History',
            subtitle: 'View all your past orders',
            color: const Color(0xFF1A9E5C),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Income Report ───────────────────────────────────────────────
          _buildMenuItem(
            icon: Icons.bar_chart_rounded,
            title: 'Income Report',
            subtitle: 'Track your earnings & analytics',
            color: const Color(0xFF7C3AED),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IncomeReportScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Logout ──────────────────────────────────────────────────────
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out from your account',
            color: const Color(0xFFE53935),
            isLogout: true,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showLogoutDialog();
            },
          ),

          const SizedBox(height: 20),

          // ── Footer ──────────────────────────────────────────────────────
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Menu Item Builder ──────────────────────────────────────────────────────
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isLogout
                    ? color.withValues(alpha: 0.08)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isLogout ? color : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isLogout
                    ? color.withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Divider(
          color: AppColors.neutral.withValues(alpha: 0.1),
          height: 1,
        ),       
      ],
    );
  }

  // ── Logout Dialog ──────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral.withValues(alpha: 0.6),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
                // Perform logout
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}