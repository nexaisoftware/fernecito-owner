import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recuperación de contraseña con OTP de 8 dígitos.
/// Flujo PWA-friendly (sin deep links).
///
/// Paso 1: pedir email → resetPasswordForEmail
/// Paso 2: ingresar código → verifyOTP (type recovery)
/// Paso 3: nueva contraseña → updateUser
class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  int _paso = 1;
  final _email = TextEditingController();
  final _codigo = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _loading = false;
  bool _ocultarNueva = true;
  bool _ocultarConfirmar = true;

  SupabaseClient get _sb => Supabase.instance.client;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _alert('Ingresá un email válido');
      return;
    }
    setState(() => _loading = true);
    try {
      await _sb.auth.resetPasswordForEmail(email);
      if (mounted) {
        _alert('Si el email existe te llegará un código de 8 dígitos. Revisá spam.',
            success: true);
        setState(() => _paso = 2);
      }
    } catch (e) {
      _alert('No se pudo enviar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codigo.text.trim();
    if (codigo.length < 6) {
      _alert('Ingresá el código completo');
      return;
    }
    setState(() => _loading = true);
    try {
      await _sb.auth.verifyOTP(
        email: _email.text.trim(),
        token: codigo,
        type: OtpType.recovery,
      );
      if (mounted) setState(() => _paso = 3);
    } catch (e) {
      _alert('Código inválido o expirado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _validar(String s) {
    if (s.length < 8) return false;
    return RegExp(r'[a-zA-Z]').hasMatch(s) && RegExp(r'[0-9]').hasMatch(s);
  }

  Future<void> _actualizarPassword() async {
    final p = _nueva.text;
    final c = _confirmar.text;
    if (!_validar(p)) {
      _alert('La contraseña debe tener mínimo 8 caracteres, una letra y un número.');
      return;
    }
    if (p != c) {
      _alert('Las contraseñas no coinciden');
      return;
    }
    setState(() => _loading = true);
    try {
      await _sb.auth.updateUser(UserAttributes(password: p));
      // Sign out para forzar login con la nueva contraseña vía AuthGate
      await _sb.auth.signOut();
      if (mounted) {
        _alert('Contraseña actualizada. Iniciá sesión con la nueva.', success: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      _alert('No se pudo actualizar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _alert(String msg, {bool success = false}) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(success ? 'Listo' : 'Atención'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _pasoActual(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pasoActual() {
    if (_paso == 1) return _paso1();
    if (_paso == 2) return _paso2();
    return _paso3();
  }

  Widget _paso1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Paso 1 de 3',
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('¿Cuál es tu email?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'Te enviaremos un código de un solo uso para resetear la contraseña.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),
        _btn(label: 'Enviar código', onPressed: _enviarCodigo),
      ],
    );
  }

  Widget _paso2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Paso 2 de 3',
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Ingresá el código',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Revisá la casilla de ${_email.text.trim()} (y spam).',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codigo,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Código',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_outlined),
          ),
        ),
        const SizedBox(height: 20),
        _btn(label: 'Verificar código', onPressed: _verificarCodigo),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : _enviarCodigo,
          child: const Text('Reenviar código'),
        ),
      ],
    );
  }

  Widget _paso3() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Paso 3 de 3',
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Nueva contraseña',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'Mínimo 8 caracteres, con al menos una letra y un número.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nueva,
          obscureText: _ocultarNueva,
          decoration: InputDecoration(
            labelText: 'Nueva contraseña',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_ocultarNueva ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _ocultarNueva = !_ocultarNueva),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmar,
          obscureText: _ocultarConfirmar,
          decoration: InputDecoration(
            labelText: 'Confirmar contraseña',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_ocultarConfirmar ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _ocultarConfirmar = !_ocultarConfirmar),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _btn(label: 'Actualizar contraseña', onPressed: _actualizarPassword),
      ],
    );
  }

  Widget _btn({required String label, required Future<void> Function() onPressed}) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}
