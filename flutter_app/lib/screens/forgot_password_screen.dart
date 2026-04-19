import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/studio_widgets.dart';

// ─────────────────────────────────────────────────────────────────────
// Forgot Password — The Correspondence
//
// Three chapters in a single editorial flow: request, verify, rewrite.
// Each with an eyebrow "chapter" label, a serif prompt, an Inter
// subprompt, and a StudioCard form beneath.
// ─────────────────────────────────────────────────────────────────────

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

  String get _chapter {
    switch (_step) {
      case _Step.enterEmail: return 'CHAPTER 01 · THE REQUEST';
      case _Step.enterCode: return 'CHAPTER 02 · THE VERIFICATION';
      case _Step.newPassword: return 'CHAPTER 03 · THE REWRITE';
    }
  }

  String get _titleA {
    switch (_step) {
      case _Step.enterEmail: return 'Let\'s ';
      case _Step.enterCode: return 'Check your ';
      case _Step.newPassword: return 'Choose a ';
    }
  }

  String get _titleB {
    switch (_step) {
      case _Step.enterEmail: return 'reset it.';
      case _Step.enterCode: return 'inbox.';
      case _Step.newPassword: return 'new secret.';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _Step.enterEmail:
        return 'We\'ll send a six-digit code to your email.';
      case _Step.enterCode:
        return 'Enter the 6-digit code sent to ${_emailController.text.trim()}.';
      case _Step.newPassword:
        return 'Eight characters or more. Make it memorable.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  IconBtn(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('THE CORRESPONDENCE', style: AppText.monoMeta),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 20, height: 2, color: AppColors.accentInk),
                        const SizedBox(width: 10),
                        Text(_chapter, style: AppText.monoMeta),
                      ],
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        style: AppText.display1,
                        children: [
                          TextSpan(text: _titleA),
                          TextSpan(
                            text: _titleB,
                            style: AppText.display1.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.accentInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_subtitle, style: AppText.lede),
                    const SizedBox(height: 24),
                    StudioCard(child: _buildStepContent()),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Back to sign in',
                          style: AppText.caption.copyWith(color: AppColors.accentInk),
                        ),
                      ),
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

  Widget _studioField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
    int? maxLength,
    TextStyle? overrideStyle,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: action,
        onSubmitted: onSubmitted,
        maxLength: maxLength,
        textAlign: textAlign,
        style: overrideStyle ?? AppText.body,
        cursorColor: AppColors.accentInk,
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          hintText: hint,
          hintStyle: (overrideStyle ?? AppText.body).copyWith(
            color: AppColors.mist, fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _studioField(
          controller: _emailController,
          hint: 'you@company.com',
          keyboardType: TextInputType.emailAddress,
          action: TextInputAction.done,
          onSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 14),
        StudioButton(
          label: _isLoading ? 'Sending…' : 'Send reset code',
          icon: Icons.mail_outline_rounded,
          kind: BtnKind.primary,
          onPressed: _isLoading ? null : _sendCode,
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _studioField(
          controller: _codeController,
          hint: '••••••',
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          overrideStyle: TextStyle(
            fontFamily: fontMono, fontSize: 26, fontWeight: FontWeight.w500,
            letterSpacing: 10, color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        StudioButton(
          label: _isLoading ? 'Verifying…' : 'Verify code',
          icon: Icons.check_rounded,
          kind: BtnKind.primary,
          onPressed: _isLoading ? null : _verifyCode,
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _isLoading ? null : _sendCode,
          child: Text(
            'Resend the code',
            style: AppText.caption.copyWith(color: AppColors.accentInk),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _studioField(
          controller: _passwordController,
          hint: 'New password',
          obscure: true,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        _studioField(
          controller: _confirmController,
          hint: 'Confirm password',
          obscure: true,
          action: TextInputAction.done,
          onSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 14),
        StudioButton(
          label: _isLoading ? 'Saving…' : 'Rewrite password',
          icon: Icons.lock_outline_rounded,
          kind: BtnKind.primary,
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
      final token = await AuthService.instance.verifyResetCode(_emailController.text.trim(), code);
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
    if (password.length < 8) { _showError('Password must be at least 8 characters.'); return; }
    if (password != confirm) { _showError('Passwords do not match.'); return; }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
