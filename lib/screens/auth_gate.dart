import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/owner_service.dart';
import '../core/servicio_push_owner.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _check();
    OwnerService.instance.authStream.listen((_) => _check());
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    final user = OwnerService.instance.currentUser;
    if (user == null) {
      setState(() {
        _isOwner = false;
        _loading = false;
      });
      return;
    }
    final ok = await OwnerService.instance.verificarOwner();
    if (!mounted) return;
    setState(() {
      _isOwner = ok;
      _loading = false;
    });
    if (ok) {
      await ServicioPushOwner.instancia.sincronizarSiAutorizado();
    }
    if (!ok) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No autorizado: tu cuenta no es owner activa.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (OwnerService.instance.currentUser == null || !_isOwner) {
      return const LoginScreen();
    }
    return const HomeScreen();
  }
}
