import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

enum _Step { enterEmail, enterCode, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.enterEmail;
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _resetToken;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    // Icon
                    SizedBox(
                      width: 80,
                      height: 80,
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
                              child: Icon(
                                _stepIcon,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                      _stepTitle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Subtitle
                    Text(
                      _stepSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Form card
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
                      child: _buildStepContent(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Back to login
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Back to login'),
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

  IconData get _stepIcon {
    switch (_step) {
      case _Step.enterEmail:
        return Icons.lock_reset;
      case _Step.enterCode:
        return Icons.mark_email_read;
      case _Step.newPassword:
        return Icons.lock_open;
    }
  }

  String get _stepTitle {
    switch (_step) {
      case _Step.enterEmail:
        return 'Forgot Password?';
      case _Step.enterCode:
        return 'Check Your Email';
      case _Step.newPassword:
        return 'New Password';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case _Step.enterEmail:
        return "Enter your email and we'll send you a reset code.";
      case _Step.enterCode:
        return 'Enter the 6-digit code we sent to\n${_emailController.text.trim()}';
      case _Step.newPassword:
        return 'Choose a new password\n(minimum 8 characters).';
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _Step.enterEmail:
        return _buildEmailStep();
      case _Step.enterCode:
        return _buildCodeStep();
      case _Step.newPassword:
        return _buildPasswordStep();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendCode(),
          decoration: InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildButton('Send Code', _sendCode),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            hintStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: AppColors.ink.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildButton('Verify Code', _verifyCode),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _isLoading ? null : _sendCode,
          child: const Text('Resend code'),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        TextField(
          controller: _passwordController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'New password',
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        TextField(
          controller: _confirmController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _resetPassword(),
          decoration: InputDecoration(
            hintText: 'Confirm password',
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildButton('Reset Password', _resetPassword),
      ],
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: _isLoading ? [] : AppShadows.button,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: FilledButton(
          onPressed: _isLoading ? null : onPressed,
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    strokeCap: StrokeCap.round,
                    color: Colors.white,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.forgotPassword(email);
      if (!mounted) return;
      setState(() => _step = _Step.enterCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reset code sent! Check your email.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError('Please enter the 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await AuthService.instance.verifyResetCode(
        _emailController.text.trim(),
        code,
      );
      _resetToken = token;
      if (!mounted) return;
      setState(() => _step = _Step.newPassword);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.resetPassword(_resetToken!, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset! Please sign in.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
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
