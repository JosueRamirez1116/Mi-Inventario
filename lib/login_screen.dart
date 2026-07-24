import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_inventario/auth_service.dart';
import 'package:mi_inventario/registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _cargando = false;
  String? _error;

  // Nota: al iniciar sesión con éxito no navegamos manualmente a Home.
  // main.dart escucha authStateChanges y cambia de pantalla automáticamente.
  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _authService.iniciarSesion(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } catch (e) {
      setState(() => _error = 'Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Traduce los códigos de FirebaseAuthException a mensajes en español
  /// que un usuario final pueda entender.
  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta de nuevo en unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      default:
        return 'No se pudo iniciar sesión. Intenta de nuevo.';
    }
  }

  /// Diálogo para pedir el correo y enviar el enlace de restablecimiento
  /// de contraseña (propuesta actualizada, punto 4).
  Future<void> _mostrarDialogoRestablecer() async {
    final controladorCorreo = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKeyDialogo = GlobalKey<FormState>();
    bool enviando = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialogo) {
            return AlertDialog(
              title: const Text('Restablecer contraseña'),
              content: Form(
                key: formKeyDialogo,
                child: TextFormField(
                  controller: controladorCorreo,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'correo@ejemplo.com',
                  ),
                  validator: (valor) => (valor == null || !valor.contains('@'))
                      ? 'Ingresa un correo válido'
                      : null,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          if (!formKeyDialogo.currentState!.validate()) return;
                          setStateDialogo(() => enviando = true);
                          try {
                            await _authService.restablecerContrasena(
                              controladorCorreo.text.trim(),
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Te enviamos un enlace para restablecer '
                                    'tu contraseña. Revisa tu correo.',
                                  ),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setStateDialogo(() => enviando = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(_mensajeError(e.code))),
                              );
                            }
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar enlace'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'MiInventario',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                    validator: (valor) =>
                        (valor == null || !valor.contains('@'))
                        ? 'Ingresa un correo válido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (valor) => (valor == null || valor.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _cargando ? null : _mostrarDialogoRestablecer,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _iniciarSesion,
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegistroScreen(),
                        ),
                      );
                    },
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
