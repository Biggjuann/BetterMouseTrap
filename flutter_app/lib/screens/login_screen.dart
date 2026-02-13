import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/credit_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showApple = AuthService.instance.isAppleSignInAvailable;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hero icon — Stitch: rotated bg + icon (matches home)
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Transform.rotate(
                              angle: 0.1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                                boxShadow: AppShadows.button,
                              ),
                              child: const Icon(
                                Icons.precision_manufacturing,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Title — "MouseTrap" with gold accent
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.ink,
                        ),
                        children: [
                          TextSpan(text: 'Mouse'),
                          TextSpan(
                            text: 'Trap',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Subtitle
                    Text(
                      _isRegisterMode ? 'Create your account' : 'Welcome back!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Sign in with Apple button (iOS only)
                    if (showApple) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithApple,
                          icon: const Icon(Icons.apple, size: 24),
                          label: const Text(
                            'Sign in with Apple',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // "or" divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.ink.withValues(alpha: 0.15))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: AppColors.ink.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.ink.withValues(alpha: 0.15))),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Form card — Stitch: white, primary/5 border, xl radius
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.05),
                        ),
                        boxShadow: AppShadows.elevated,
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.primary.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.base),

                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: AppColors.primary.withValues(alpha: 0.6),
                              ),
                            ),
                          ),

                          if (!_isRegisterMode)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                                child: const Text('Forgot password?'),
                              ),
                            ),

                          const SizedBox(height: AppSpacing.lg),

                          // Primary CTA — Stitch gold button with shadow
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                boxShadow: _isLoading ? [] : AppShadows.button,
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                              ),
                              child: FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          strokeCap: StrokeCap.round,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isRegisterMode
                                                ? Icons.person_add
                                                : Icons.login,
                                            size: 20,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            _isRegisterMode ? 'Create Account' : 'Sign In',
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Toggle link
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                _isRegisterMode = !_isRegisterMode;
                              }),
                      child: Text(
                        _isRegisterMode
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Create one",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithApple();
      CreditService.instance.refresh();
      PurchaseService.instance.init();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthService.instance.onboardingSeen
              ? const HomeScreen()
              : const OnboardingScreen(),
        ),
      );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    if (_isRegisterMode && password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isRegisterMode) {
        await AuthService.instance.register(email, password);
      } else {
        await AuthService.instance.login(email, password);
      }
      CreditService.instance.refresh();
      PurchaseService.instance.init();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthService.instance.onboardingSeen
              ? const HomeScreen()
              : const OnboardingScreen(),
        ),
      );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
