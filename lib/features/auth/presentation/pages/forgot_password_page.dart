import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/auth_view_model.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  static const route = '/recuperar-senha';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _auth = Get.find<AuthViewModel>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.sendPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se existir uma conta, enviaremos instruções por e-mail.',
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go(LoginPage.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Theme.of(context).colorScheme.surface),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth < 500
                    ? constraints.maxWidth * 0.9
                    : 480.0;
                return SizedBox(
                  width: maxWidth,
                  child: _glassCard(context, cs, isDark),
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              tooltip: 'Voltar',
              onPressed: () => context.go(LoginPage.route),
              icon: Icon(Icons.arrow_back, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(BuildContext context, ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      child: _formContent(context, cs),
    );
  }

  Widget _formContent(BuildContext context, ColorScheme cs) {
    return Form(
      key: _formKey,
      child: Obx(() {
        final loading = _auth.isLoading.value;
        final error = _auth.error.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/png/logo.png',
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Recuperar acesso',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Informe seu e-mail para receber o link de redefinição de senha.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (error != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(.35)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (error != null) const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: _inputDecoration('E-mail', Icons.alternate_email, cs),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o e-mail';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: cs.primary,
                overlayColor: cs.primary.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar link de redefinição'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(LoginPage.route),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: const Text('Voltar ao login'),
            ),
          ],
        );
      }),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    ColorScheme cs,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(.15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(.45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withOpacity(.9)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withOpacity(.9), width: 1.4),
      ),

      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white70),
    );
  }
}
