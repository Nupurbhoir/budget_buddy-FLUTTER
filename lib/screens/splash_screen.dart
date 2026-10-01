import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/primary_button.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const SplashScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhiteBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Brand Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldGreen.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // App Title
                  Text(
                    'BudgetBuddy',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Take control of your money',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Track spending effortlessly, set realistic budgets, conquer your bills, and achieve lasting financial freedom.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Feature badges
                  _buildFeatureRow(
                    Icons.flash_on_rounded,
                    'Smart Expense Logging',
                    'Instant categorization & UPI tracking',
                    isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeatureRow(
                    Icons.pie_chart_rounded,
                    'Visual Budget Tracking',
                    'Real-time thresholds & overspend alerts',
                    isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeatureRow(
                    Icons.event_repeat_rounded,
                    'Automated Bill Reminders',
                    'Never miss a due date or incur late fees',
                    isDark,
                  ),
                  const Spacer(),
                  // Get Started CTA
                  PrimaryButton(
                    text: 'Get Started',
                    width: double.infinity,
                    onPressed: onGetStarted,
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Local offline-first storage • Secure & Private',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.emeraldGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.emeraldGreen, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
