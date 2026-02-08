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
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(
                      Icons.tips_and_updates_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'MouseTrap',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isRegisterMode ? 'Join the club!' : 'Welcome back!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.stone,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.elevated,
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

                        // Dark pill CTA (Etsy)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submit,
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
                                    _isRegisterMode ? 'Register' : 'Sign In',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
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
