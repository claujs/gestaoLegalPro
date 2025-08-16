import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/viewmodels/auth_view_model.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onToggleTheme});
  static const route = '/login';
  final VoidCallback onToggleTheme;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = Get.find<AuthViewModel>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      context.go(DashboardPage.route);
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
          // Background gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0D1B2A),
                        const Color(0xFF102F52),
                        const Color(0xFF0A2540),
                      ]
                    : [
                        const Color(0xFFE9F1F9),
                        const Color(0xFFDDEAF7),
                        const Color(0xFFCFE1F2),
                      ],
              ),
            ),
          ),
          // Overlay gradient suave
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(isDark ? 0.28 : 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Conteúdo central
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
          // Botão de tema topo-direito
          Positioned(
            top: 12,
            right: 12,
            child: Tooltip(
              message: 'Alternar tema',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: widget.onToggleTheme,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(.25),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      size: 20,
                      color: cs.onSurface.withOpacity(.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(BuildContext context, ColorScheme cs, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(.35),
              width: 1.1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.55),
                Colors.white.withOpacity(.25),
                Colors.white.withOpacity(.18),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          child: _formContent(context, cs),
        ),
      ),
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
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primaryContainer],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.scale, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestão Legal Pro',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.5,
                        ),
                      ),
                      Text(
                        'Acesso à plataforma',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (error != null)
              AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.error.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.error.withOpacity(.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_rounded, color: cs.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: cs.error.withOpacity(.8),
                        ),
                        onPressed: () => _auth.error.value = null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (error != null) const SizedBox(height: 20),
            TextFormField(
              controller: _emailCtrl,
              decoration: _inputDecoration('E-mail', Icons.alternate_email),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o e-mail';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: _inputDecoration('Senha', Icons.lock_outline),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Esqueceu sua senha?'),
              ),
            ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(
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
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Demo: admin@demo.com / 123456',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.55),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withOpacity(.55),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withOpacity(.8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withOpacity(.9), width: 1.4),
      ),
    );
  }
}
