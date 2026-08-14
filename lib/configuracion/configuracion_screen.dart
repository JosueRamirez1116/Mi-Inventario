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
    final colores = Theme.of(context).colorScheme;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colores.error),
              const SizedBox(width: 10),
              const Text('Eliminar cuenta'),
            ],
          ),
          content: const Text(
            'Al continuar, tu cuenta será eliminada y ya no podrás acceder a ella.\n\n'
            'Esta acción no se puede deshacer.\n\n'
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
                backgroundColor: colores.error,
                foregroundColor: colores.onError,
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
            final colores = Theme.of(context).colorScheme;

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
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colores.onPrimary,
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
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return Scaffold(
      appBar: AppBar(
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
              
              _tituloSeccion(context, 'CUENTA'),

              const SizedBox(height: 10),

              _crearOpcion(
                context: context,
                icono: Icons.person_outline,
                titulo: 'Perfil de usuario',
                descripcion: 'Consulta y edita tu información personal',
                onTap: _abrirPerfil,
              ),

              const SizedBox(height: 24),

              _tituloSeccion(context, 'APARIENCIA'),

              const SizedBox(height: 10),

              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colores.primaryContainer,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _modoOscuro ? Icons.dark_mode : Icons.light_mode,
                          color: colores.primary,
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
                                color: colores.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _modoOscuro
                                  ? 'Nocturno Boutique activado'
                                  : 'Índigo Corporativo activado',
                              style: TextStyle(
                                fontSize: 13,
                                color: colores.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Switch(value: _modoOscuro, onChanged: _cambiarModoOscuro),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _tituloSeccion(context, 'SEGURIDAD'),

              const SizedBox(height: 10),

              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _eliminando ? null : _confirmarEliminarCuenta,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colores.errorContainer,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: _eliminando
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colores.error,
                                  ),
                                )
                              : Icon(
                                  Icons.person_off_outlined,
                                  color: colores.error,
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
                                  color: colores.error,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Desactivar la cuenta y eliminar el acceso',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colores.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!_eliminando)
                          Icon(
                            Icons.chevron_right,
                            color: colores.onSurfaceVariant,
                          ),
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

  Widget _tituloSeccion(BuildContext context, String titulo) {
    final colores = Theme.of(context).colorScheme;

    return Text(
      titulo,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: colores.onSurfaceVariant,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _crearOpcion({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colores.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icono, color: colores.primary),
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
                        color: colores.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: colores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: colores.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
