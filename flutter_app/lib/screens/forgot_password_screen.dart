import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/whiskers_widgets.dart';

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

  String get _stepTitle {
    switch (_step) {
      case _Step.enterEmail: return "Let's Reset It";
      case _Step.enterCode: return 'Check Your Inbox';
      case _Step.newPassword: return 'Choose a New Secret';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case _Step.enterEmail:
        return "We'll send a six-digit code to your email.";
      case _Step.enterCode:
        return 'Enter the 6-digit code sent to ${_emailController.text.trim()}.';
      case _Step.newPassword:
        return 'Eight characters or more. Make it memorable.';
    }
  }

  int get _stepIndex {
    switch (_step) {
      case _Step.enterEmail: return 0;
      case _Step.enterCode: return 1;
      case _Step.newPassword: return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  IconBtn(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('Reset Password', style: AppText.sectionTitle),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mascot + step pills
                    const Mascot(
                        pose: MascotPose.detective, size: 80),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Pill('1. Email',
                            bg: _stepIndex >= 0
                                ? AppColors.lav
                                : AppColors.lavLight,
                            fg: _stepIndex >= 0
                                ? Colors.white
                                : AppColors.lavDark),
                        const SizedBox(width: 6),
                        Pill('2. Code',
                            bg: _stepIndex >= 1
                                ? AppColors.lav
                                : AppColors.lavLight,
                            fg: _stepIndex >= 1
                                ? Colors.white
                                : AppColors.lavDark),
                        const SizedBox(width: 6),
                        Pill('3. Password',
                            bg: _stepIndex >= 2
                                ? AppColors.lav
                                : AppColors.lavLight,
                            fg: _stepIndex >= 2
                                ? Colors.white
                                : AppColors.lavDark),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title + subtitle
                    Text(_stepTitle,
                        style: AppText.display2,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(_stepSubtitle,
                        style: AppText.caption,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),

                    // Step content card
                    WCard(child: _buildStepContent()),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text('Back to sign in',
                          style: AppText.caption.copyWith(
                              color: AppColors.lavDark)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _Step.enterEmail: return _buildEmailStep();
      case _Step.enterCode: return _buildCodeStep();
      case _Step.newPassword: return _buildPasswordStep();
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: action,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      textAlign: textAlign,
      style: AppText.bodyLg,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _emailController,
          hint: 'you@company.com',
          keyboardType: TextInputType.emailAddress,
          action: TextInputAction.done,
          onSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 14),
        PrimaryBtn(
          label: _isLoading ? 'Sending…' : 'Send Reset Code',
          leading: Icons.mail_outline_rounded,
          loading: _isLoading,
          onPressed: _isLoading ? null : _sendCode,
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _codeController,
          hint: '000000',
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        PrimaryBtn(
          label: _isLoading ? 'Verifying…' : 'Verify Code',
          leading: Icons.check_rounded,
          loading: _isLoading,
          onPressed: _isLoading ? null : _verifyCode,
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _sendCode,
            child: Text('Resend the code',
                style: AppText.caption
                    .copyWith(color: AppColors.lavDark)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _passwordController,
          hint: 'New password',
          obscure: true,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _confirmController,
          hint: 'Confirm password',
          obscure: true,
          action: TextInputAction.done,
          onSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 14),
        PrimaryBtn(
          label: _isLoading ? 'Saving…' : 'Reset Password',
          leading: Icons.lock_outline_rounded,
          loading: _isLoading,
          onPressed: _isLoading ? null : _resetPassword,
        ),
      ],
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) { _showError('Please enter your email.'); return; }
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.forgotPassword(email);
      if (!mounted) return;
      setState(() => _step = _Step.enterCode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset code sent. Check your email.')),
      );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) { _showError('Enter the 6-digit code.'); return; }
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.instance
          .verifyResetCode(_emailController.text.trim(), code);
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
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.resetPassword(_resetToken!, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset. Please sign in.')),
      );
      Navigator.pop(context);
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
}
