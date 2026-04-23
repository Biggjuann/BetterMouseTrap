import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/credit_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import '../widgets/whiskers_widgets.dart';
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final showApple = AuthService.instance.isAppleSignInAvailable;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Mascot
                  const Mascot(pose: MascotPose.guardian, size: 88),
                  const SizedBox(height: 16),

                  Text(
                    _isRegisterMode
                        ? 'Join the Workshop'
                        : 'Welcome Back!',
                    style: AppText.display1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegisterMode
                        ? '3 free credits on arrival. No card needed.'
                        : 'Sign in to pick up where you left off.',
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  if (showApple) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _signInWithApple,
                        icon: const Icon(Icons.apple, size: 22),
                        label: const Text('Continue with Apple'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: AppColors.hairline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Text('or with email',
                              style: AppText.tiny),
                        ),
                        const Expanded(
                            child: Divider(color: AppColors.hairline)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form card
                  WCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRegisterMode
                              ? 'Create Account'
                              : 'Sign In',
                          style: AppText.sectionTitle,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: AppText.bodyLg,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: AppText.caption,
                            hintText: 'you@example.com',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          style: AppText.bodyLg,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: AppText.caption,
                            hintText: '••••••••',
                          ),
                        ),
                        if (!_isRegisterMode) ...[
                          const SizedBox(height: 6),
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
                              child: Text('Forgot password?',
                                  style: AppText.caption.copyWith(
                                      color: AppColors.lavDark)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        PrimaryBtn(
                          label: _isRegisterMode
                              ? 'Create Account'
                              : 'Sign In',
                          trailing: _isRegisterMode
                              ? Icons.person_add_rounded
                              : Icons.arrow_forward_rounded,
                          loading: _isLoading,
                          onPressed: _isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => setState(
                            () => _isRegisterMode = !_isRegisterMode),
                    child: RichText(
                      text: TextSpan(
                        style: AppText.caption,
                        children: [
                          TextSpan(
                            text: _isRegisterMode
                                ? 'Already a member? '
                                : 'First visit? ',
                          ),
                          TextSpan(
                            text: _isRegisterMode
                                ? 'Sign in'
                                : 'Create an account',
                            style: AppText.caption.copyWith(
                                color: AppColors.lavDark,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.lavDark),
                          ),
                        ],
                      ),
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
}
