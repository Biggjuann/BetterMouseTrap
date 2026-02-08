import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8EE), AppColors.warmWhite, Color(0xFFFFF3E3)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with glow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppGradients.hero,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAmber.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tips_and_updates,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'MouseTrap',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkCharcoal,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isRegisterMode ? 'Join the club!' : 'Welcome back!',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.mutedGray),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.lightWarmGray.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.primaryAmber.withValues(alpha: 0.04),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: _isRegisterMode
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onSubmitted:
                              _isRegisterMode ? null : (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                        ),

                        if (_isRegisterMode) ...[
                          const SizedBox(height: AppSpacing.base),
                          TextField(
                            controller: _inviteCodeController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Invite Code',
                              prefixIcon: Icon(Icons.vpn_key_outlined),
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // Gradient sign-in button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _isLoading ? null : AppGradients.hero,
                            color: _isLoading
                                ? AppColors.lightWarmGray
                                : null,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            boxShadow: _isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primaryAmber
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _submit,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isRegisterMode
                                            ? 'Register'
                                            : 'Sign In',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _isRegisterMode = !_isRegisterMode;
                            }),
                    child: Text(
                      _isRegisterMode
                          ? 'Already have an account? Sign in'
                          : 'Have an invite code? Register',
                      style: TextStyle(
                        color: AppColors.primaryAmber,
                        fontWeight: FontWeight.w600,
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

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    if (_isRegisterMode && _inviteCodeController.text.trim().isEmpty) {
      _showError('Please enter your invite code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isRegisterMode) {
        await AuthService.instance.register(
          email,
          password,
          _inviteCodeController.text.trim(),
        );
      } else {
        await AuthService.instance.login(email, password);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
