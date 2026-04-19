import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/credit_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import '../widgets/studio_widgets.dart';
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Masthead
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.memory_rounded, color: AppColors.canvas, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'MOUSE·TRAP',
                        style: TextStyle(
                          fontFamily: fontMono,
                          fontSize: 10,
                          letterSpacing: 2.5,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  const Eyebrow('File Nº 0049 · the entrance'),
                  const SizedBox(height: AppSpacing.md),
                  RichText(
                    text: TextSpan(
                      style: AppText.display1,
                      children: [
                        TextSpan(text: _isRegisterMode ? 'Open the\n' : 'Welcome\n'),
                        TextSpan(
                          text: _isRegisterMode ? 'workshop.' : 'back.',
                          style: AppText.display1.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    _isRegisterMode
                        ? 'Three free credits on arrival. No card needed.'
                        : 'Sign in to pick up where you left off.',
                    style: AppText.bodyLg.copyWith(color: AppColors.graphite),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  if (showApple) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _signInWithApple,
                        icon: const Icon(Icons.apple, size: 22),
                        label: const Text('Continue with Apple'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.canvas,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: fontSans,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.hairline, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            'or by email',
                            style: TextStyle(
                              fontFamily: fontMono,
                              fontSize: 10,
                              letterSpacing: 2,
                              color: AppColors.mist,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.hairline, height: 1)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Specimen form — email / password
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.ink.withValues(alpha: 0.9)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _isRegisterMode ? 'NEW · CREDENTIALS' : 'RETURNING · CREDENTIALS',
                                style: TextStyle(
                                  fontFamily: fontMono,
                                  fontSize: 10,
                                  color: AppColors.canvas,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '01 / 02',
                                style: TextStyle(
                                  fontFamily: fontMono,
                                  fontSize: 10,
                                  color: AppColors.canvas,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _formField(
                          marker: 'A.',
                          label: 'EMAIL',
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: AppText.display4.copyWith(color: AppColors.ink),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hintText: 'you@workshop.com',
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.hairline, indent: 14, endIndent: 14),
                        _formField(
                          marker: 'B.',
                          label: 'PASSWORD',
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            style: AppText.display4.copyWith(color: AppColors.ink),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hintText: '••••••••',
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (!_isRegisterMode)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontFamily: fontSans,
                            fontSize: 13,
                            color: AppColors.graphite,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.mist,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  StudioButton(
                    label: _isRegisterMode ? 'Create account' : 'Sign in',
                    icon: _isRegisterMode ? Icons.person_add_rounded : Icons.arrow_forward_rounded,
                    onPressed: _isLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.base),

                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isRegisterMode = !_isRegisterMode),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: fontSans,
                            fontSize: 13,
                            color: AppColors.graphite,
                          ),
                          children: [
                            TextSpan(
                              text: _isRegisterMode
                                  ? 'Already a member? '
                                  : "First visit? ",
                            ),
                            TextSpan(
                              text: _isRegisterMode ? 'Sign in' : 'Create an account',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField({required String marker, required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  marker,
                  style: TextStyle(
                    fontFamily: fontMono,
                    fontSize: 10,
                    color: AppColors.mist,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: fontMono,
                  fontSize: 9.5,
                  letterSpacing: 2,
                  color: AppColors.mist,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: child,
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
