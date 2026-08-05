import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/configuracion/perfil_usuario_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  static const Color _colorPrincipal = Color.fromARGB(255, 28, 83, 170);

  final AuthService _authService = AuthService();

  bool _modoOscuro = Get.isDarkMode;
  bool _eliminando = false;

  void _cambiarModoOscuro(bool valor) {
    setState(() {
      _modoOscuro = valor;
    });

    Get.changeThemeMode(valor ? ThemeMode.dark : ThemeMode.light);
  }

  void _abrirPerfil() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PerfilUsuarioScreen()));
  }

  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'requires-recent-login':
        return 'Por seguridad debes confirmar tu contraseña.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contraseña ingresada es incorrecta.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      case 'permission-denied':
        return 'No tienes permisos para realizar esta acción.';
      case 'missing-uid':
        return 'No hay una sesión activa.';
      default:
        return 'No se pudo eliminar la cuenta. Intenta nuevamente.';
    }
  }

  Future<void> _confirmarEliminarCuenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Eliminar cuenta'),
            ],
          ),
          content: const Text(
            'Al continuar, tu usuario será marcado como eliminado '
            'en la base de datos con estado 0 y tu cuenta será '
            'eliminada de Firebase Authentication.\n\n'
            'Tus datos permanecerán registrados en Firestore.\n\n'
            '¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar cuenta'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    await _eliminarCuenta();
  }

  Future<void> _eliminarCuenta() async {
    setState(() {
      _eliminando = true;
    });

    try {
      await _authService.eliminarCuentaUsuario();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada correctamente.')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (!mounted) return;

        setState(() {
          _eliminando = false;
        });

        await _pedirContrasena();
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mensajeError(e.code))));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la cuenta. Intenta nuevamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _eliminando = false;
        });
      }
    }
  }

  Future<void> _pedirContrasena() async {
    final contrasenaController = TextEditingController();

    bool procesando = false;

    final reautenticado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirmar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Por seguridad, Firebase necesita '
                    'confirmar tu identidad antes de '
                    'eliminar la cuenta.',
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: contrasenaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: procesando
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _colorPrincipal,
                  ),
                  onPressed: procesando
                      ? null
                      : () async {
                          final contrasena = contrasenaController.text.trim();

                          if (contrasena.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Ingresa tu contraseña.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            procesando = true;
                          });

                          try {
                            await _authService.reautenticarConContrasena(
                              email: _authService.usuarioActual?.email ?? '',
                              password: contrasena,
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              procesando = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(_mensajeError(e.code))),
                              );
                            }
                          }
                        },
                  child: procesando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    contrasenaController.dispose();

    if (reautenticado == true) {
      await _eliminarCuenta();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    final colorTarjeta = esOscuro ? const Color(0xFF242424) : Colors.white;

    final colorTexto = esOscuro ? Colors.white : const Color(0xFF303030);

    final colorSecundario = esOscuro ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: esOscuro
          ? const Color(0xFF121212)
          : const Color.fromARGB(255, 248, 244, 250),
      appBar: AppBar(
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorTarjeta,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: _colorPrincipal,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mi configuración',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Administra tu cuenta y preferencias',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Text(
                'CUENTA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorSecundario,
                  letterSpacing: 0.6,
                ),
              ),

              const SizedBox(height: 10),

              _crearOpcion(
                colorTarjeta: colorTarjeta,
                colorTexto: colorTexto,
                colorSecundario: colorSecundario,
                icono: Icons.person_outline,
                titulo: 'Perfil de usuario',
                descripcion: 'Consulta y edita tu información personal',
                onTap: _abrirPerfil,
              ),

              const SizedBox(height: 24),

              Text(
                'APARIENCIA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorSecundario,
                  letterSpacing: 0.6,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorTarjeta,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _modoOscuro ? Icons.dark_mode : Icons.light_mode,
                        color: _colorPrincipal,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modo oscuro',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorTexto,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _modoOscuro
                                ? 'Modo oscuro activado'
                                : 'Modo claro activado',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: _modoOscuro,
                      activeThumbColor: _colorPrincipal,
                      onChanged: _cambiarModoOscuro,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'SEGURIDAD',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorSecundario,
                  letterSpacing: 0.6,
                ),
              ),

              const SizedBox(height: 10),

              Material(
                color: colorTarjeta,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _eliminando ? null : _confirmarEliminarCuenta,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: _eliminando
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_off_outlined,
                                  color: Colors.red,
                                ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Eliminar cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Desactivar la cuenta y eliminar el acceso',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!_eliminando)
                          const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearOpcion({
    required Color colorTarjeta,
    required Color colorTexto,
    required Color colorSecundario,
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colorTarjeta,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icono, color: _colorPrincipal),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorTexto,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descripcion,
                      style: TextStyle(fontSize: 13, color: colorSecundario),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
