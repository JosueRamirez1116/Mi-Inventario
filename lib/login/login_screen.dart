import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/registro/registro_screen.dart';

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
  bool _ocultarPassword = true;
  String? _error;

  // Colores base del tema (morado/índigo)
  static const Color _colorPrimario = Color(0xFF6C63FF);
  static const Color _colorPrimarioOscuro = Color(0xFF4A3FCF);
  static const Color _colorFondoClaro = Color(0xFFF3F1FF);

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
    } on FirebaseException catch (e) {
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
      case 'permission-denied':
        return 'No hay permisos para acceder a la base de datos.';
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Restablecer contraseña',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKeyDialogo,
                child: TextFormField(
                  controller: controladorCorreo,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'correo@ejemplo.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: _colorFondoClaro,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (valor) => (valor == null || !valor.contains('@'))
                      ? 'Ingresa un correo válido'
                      : null,
                ),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _colorPrimario,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: _colorPrimarioOscuro,
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

  InputDecoration _decoracionCampo({
    required String label,
    required IconData icono,
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono, color: _colorPrimario),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _colorPrimario, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _colorPrimarioOscuro,
              _colorPrimario,
              _colorFondoClaro,
            ],
            stops: [0.0, 0.28, 0.55],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícono con fondo circular
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        size: 56,
                        color: _colorPrimario,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'MiInventario',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestiona tu inventario fácilmente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tarjeta blanca con el formulario
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decoracionCampo(
                              label: 'Correo electrónico',
                              icono: Icons.email_outlined,
                            ),
                            validator: (valor) =>
                                (valor == null || !valor.contains('@'))
                                ? 'Ingresa un correo válido'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _ocultarPassword,
                            decoration: _decoracionCampo(
                              label: 'Contraseña',
                              icono: Icons.lock_outline,
                              sufijo: IconButton(
                                icon: Icon(
                                  _ocultarPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () => setState(
                                  () => _ocultarPassword = !_ocultarPassword,
                                ),
                              ),
                            ),
                            validator: (valor) =>
                                (valor == null || valor.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: _colorPrimario,
                              ),
                              onPressed:
                                  _cargando ? null : _mostrarDialogoRestablecer,
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          if (_error != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade400, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _colorPrimario,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: _colorPrimario.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _cargando ? null : _iniciarSesion,
                              child: _cargando
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Enlace de registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: _colorPrimarioOscuro,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegistroScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}