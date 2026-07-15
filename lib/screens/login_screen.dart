import 'package:flutter/material.dart';

import '../core/owner_theme.dart';
import '../services/owner_service.dart';
import 'recover_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await OwnerService.instance.signIn(_email.text.trim(), _password.text);
    } catch (e) {
      setState(() => _error = 'No pudimos iniciar sesión: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwnerTheme.fondo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 520;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: OwnerTheme.violetaMarca,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fernecito Owner',
                        style: OwnerTheme.baloo(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: OwnerTheme.texto,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Acceso restringido al equipo',
                        style: OwnerTheme.baloo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OwnerTheme.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: OwnerTheme.borde),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              enableSuggestions: false,
                              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                              decoration: const InputDecoration(labelText: 'Email'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              enableSuggestions: false,
                              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                              onSubmitted: (_) => _loading ? null : _login(),
                              decoration: const InputDecoration(labelText: 'Contraseña'),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: OwnerTheme.baloo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: FilledButton(
                                onPressed: _loading ? null : _login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: OwnerTheme.violetaMarca,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'Entrar',
                                        style: OwnerTheme.baloo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RecoverPasswordScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: OwnerTheme.baloo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: OwnerTheme.violetaMarca,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
