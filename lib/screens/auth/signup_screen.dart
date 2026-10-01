import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/user_profile_model.dart';
import '../../providers/finance_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onSignupSuccess;
  final VoidCallback onNavigateToLogin;

  const SignupScreen({
    super.key,
    required this.onSignupSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Nupur Sharma');
  final _emailCtrl = TextEditingController(text: 'nupur@example.com');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _passwordCtrl = TextEditingController(text: 'secret123');
  final _budgetCtrl = TextEditingController(text: '50000');
  bool _obscurePassword = true;
  bool _agreedToTerms = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service to continue.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final newBudget = double.tryParse(_budgetCtrl.text.trim()) ?? 50000.0;

    final finance = context.read<FinanceProvider>();
    final updatedProfile = UserProfileModel(
      name: name,
      email: email,
      phone: phone,
      totalMonthlyBudget: newBudget,
    );
    await finance.updateUserProfile(updatedProfile);

    try {
      final firebase = FirebaseService();
      if (firebase.isInitialized) {
        try {
          await firebase.signUpWithEmail(
            email: email,
            password: password,
            displayName: name,
          );
          // Initial sync to Cloud Firestore
          await finance.syncWithCloud();
        } catch (e) {
          final msg = FirebaseService.getAuthErrorMessage(e);
          if (e.toString().contains('email-already-in-use') || e.toString().contains('weak-password')) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = msg;
              });
            }
            return;
          }
          debugPrint('[Signup] Firebase note: $msg. Saved local profile.');
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        widget.onSignupSuccess();
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = FirebaseService.getAuthErrorMessage(err);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        'Start Your Financial Journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Create your account with Firebase Authentication and cloud history backup.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.redError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.redError.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.redError, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12, color: AppColors.redError, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _nameCtrl,
                            label: 'Full Legal Name',
                            hint: 'e.g. Nupur Sharma',
                            prefixIcon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _emailCtrl,
                            label: 'Email Address',
                            hint: 'nupur@example.com',
                            prefixIcon: Icons.email_outlined,
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _phoneCtrl,
                            label: 'Phone Number',
                            hint: '+91 98765 43210',
                            prefixIcon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _budgetCtrl,
                            label: 'Initial Monthly Budget Target (₹)',
                            hint: '50000',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.monetization_on_outlined,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _passwordCtrl,
                            label: 'Create Secure Password',
                            hint: 'Minimum 6 characters',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 chars' : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.slateSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Checkbox(
                                value: _agreedToTerms,
                                activeColor: AppColors.emeraldGreen,
                                onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
                              ),
                              const Expanded(
                                child: Text(
                                  'I agree to BudgetBuddy Terms & Privacy and Firebase Cloud Sync.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            text: 'Create Firebase Account',
                            width: double.infinity,
                            isLoading: _isLoading,
                            onPressed: _submitSignup,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already registered? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToLogin,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
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
  }
}
