import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/registro/registro_screen.dart';
import 'package:mi_inventario/theme/app_theme.dart';

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

  static const Color _colorPrimario = Color(0xFF6C63FF);

  static const Color _colorPrimarioOscuro = Color(0xFF4A3FCF);

  static const Color _colorFondoClaro = Color(0xFFF3F1FF);

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      setState(() {
        _error = _mensajeError(e.code);
      });
    } on FirebaseException catch (e) {
      setState(() {
        _error = _mensajeError(e.code);
      });
    } catch (_) {
      setState(() {
        _error = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

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
            final tema = Theme.of(dialogContext);

            final colores = tema.colorScheme;

            final esOscuro = tema.brightness == Brightness.dark;

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
                  style: TextStyle(color: colores.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'correo@ejemplo.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: esOscuro ? AppTheme.oro : _colorPrimario,
                    ),
                    filled: true,
                    fillColor: esOscuro
                        ? AppTheme.superficieOscura
                        : _colorFondoClaro,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: esOscuro
                          ? const BorderSide(color: AppTheme.bordeOscuro)
                          : BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: esOscuro
                          ? const BorderSide(color: AppTheme.bordeOscuro)
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: esOscuro ? AppTheme.oro : _colorPrimario,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (valor) => valor == null || !valor.contains('@')
                      ? 'Ingresa un correo válido'
                      : null,
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: esOscuro ? AppTheme.oro : _colorPrimario,
                    foregroundColor: esOscuro
                        ? AppTheme.fondoOscuro
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: enviando
                      ? null
                      : () async {
                          if (!formKeyDialogo.currentState!.validate()) {
                            return;
                          }

                          setStateDialogo(() {
                            enviando = true;
                          });

                          try {
                            await _authService.restablecerContrasena(
                              controladorCorreo.text.trim(),
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (mounted) {
                              final temaActual = Theme.of(context);

                              final oscuro =
                                  temaActual.brightness == Brightness.dark;

                              final colorSnack = oscuro
                                  ? AppTheme.oro
                                  : _colorPrimarioOscuro;

                              final colorTexto = oscuro
                                  ? AppTheme.fondoOscuro
                                  : Colors.white;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: colorSnack,
                                  content: Text(
                                    'Te enviamos un enlace para restablecer '
                                    'tu contraseña. Revisa tu correo.',
                                    style: TextStyle(color: colorTexto),
                                  ),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setStateDialogo(() {
                              enviando = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(_mensajeError(e.code))),
                              );
                            }
                          }
                        },
                  child: enviando
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: esOscuro
                                ? AppTheme.fondoOscuro
                                : Colors.white,
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

    controladorCorreo.dispose();
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
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    final esOscuro = tema.brightness == Brightness.dark;

    final colorPrincipal = esOscuro ? AppTheme.oro : _colorPrimario;

    final colorCampo = esOscuro ? AppTheme.superficieOscura : Colors.white;

    final colorBorde = esOscuro ? AppTheme.bordeOscuro : Colors.grey.shade300;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: esOscuro ? AppTheme.textoSecundarioOscuro : null,
      ),
      prefixIcon: Icon(icono, color: colorPrincipal),
      suffixIcon: sufijo,
      filled: true,
      fillColor: colorCampo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorBorde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorBorde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorPrincipal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colores.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colores.error, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    final esOscuro = tema.brightness == Brightness.dark;

    final coloresGradiente = esOscuro
        ? const [
            AppTheme.fondoOscuro,
            AppTheme.superficieOscura,
            AppTheme.fondoOscuro,
          ]
        : const [_colorPrimarioOscuro, _colorPrimario, _colorFondoClaro];

    final colorLogo = esOscuro ? AppTheme.superficieOscura : Colors.white;

    final colorIconoLogo = esOscuro ? AppTheme.oro : _colorPrimario;

    final colorTitulo = esOscuro ? AppTheme.textoOscuro : Colors.white;

    final colorSubtitulo = esOscuro
        ? AppTheme.textoSecundarioOscuro
        : Colors.white.withValues(alpha: 0.85);

    final colorTarjeta = esOscuro ? AppTheme.superficieOscura : Colors.white;

    final colorPrincipal = esOscuro ? AppTheme.oro : _colorPrimario;

    final colorBotonTexto = esOscuro ? AppTheme.fondoOscuro : Colors.white;

    final colorTextoInferior = esOscuro
        ? AppTheme.textoSecundarioOscuro
        : Colors.grey.shade800;

    final colorRegistro = esOscuro ? AppTheme.oro : _colorPrimarioOscuro;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: coloresGradiente,
            stops: const [0.0, 0.28, 0.55],
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorLogo,
                        shape: BoxShape.circle,
                        border: esOscuro
                            ? Border.all(color: AppTheme.bordeOscuro)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: esOscuro
                                ? AppTheme.oro.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        size: 56,
                        color: colorIconoLogo,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'MiInventario',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorTitulo,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Gestiona tu inventario fácilmente',
                      style: TextStyle(fontSize: 14, color: colorSubtitulo),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorTarjeta,
                        borderRadius: BorderRadius.circular(24),
                        border: esOscuro
                            ? Border.all(color: AppTheme.bordeOscuro)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: esOscuro
                                ? AppTheme.oro.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08),
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
                            style: TextStyle(color: colores.onSurface),
                            decoration: _decoracionCampo(
                              label: 'Correo electrónico',
                              icono: Icons.email_outlined,
                            ),
                            validator: (valor) =>
                                valor == null || !valor.contains('@')
                                ? 'Ingresa un correo válido'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _ocultarPassword,
                            style: TextStyle(color: colores.onSurface),
                            decoration: _decoracionCampo(
                              label: 'Contraseña',
                              icono: Icons.lock_outline,
                              sufijo: IconButton(
                                icon: Icon(
                                  _ocultarPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: esOscuro
                                      ? AppTheme.textoSecundarioOscuro
                                      : Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _ocultarPassword = !_ocultarPassword,
                                  );
                                },
                              ),
                            ),
                            validator: (valor) =>
                                valor == null || valor.length < 6
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: colorPrincipal,
                              ),
                              onPressed: _cargando
                                  ? null
                                  : _mostrarDialogoRestablecer,
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
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: esOscuro
                                    ? colores.errorContainer
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: esOscuro
                                      ? colores.error.withValues(alpha: 0.35)
                                      : Colors.red.shade100,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colores.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: esOscuro
                                            ? colores.onErrorContainer
                                            : Colors.red.shade700,
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
                                backgroundColor: colorPrincipal,
                                foregroundColor: colorBotonTexto,
                                elevation: esOscuro ? 1 : 4,
                                shadowColor: colorPrincipal.withValues(
                                  alpha: esOscuro ? 0.30 : 0.50,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _cargando ? null : _iniciarSesion,
                              child: _cargando
                                  ? SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: colorBotonTexto,
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(
                            color: colorTextoInferior,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: colorRegistro,
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
