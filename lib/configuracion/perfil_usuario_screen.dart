import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/configuracion/editar_negocio_screen.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _cargando = true;
  bool _guardando = false;
  bool _eliminando = false;
  String? _error;
  DateTime? _fechaNacimiento;
  int _estado = 1;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await _authService.obtenerPerfilUsuario();
      if (data == null) {
        setState(() {
          _error = 'No se encontro informacion del perfil.';
          _cargando = false;
        });
        return;
      }

      _nombreController.text = (data['nombre'] ?? '').toString();
      _apellidoController.text = (data['apellido'] ?? '').toString();
      _telefonoController.text = (data['telefono'] ?? '').toString();
      _estado = (data['estado'] ?? 1) as int;

      final fecha = data['fechaNacimiento'];
      if (fecha is Timestamp) {
        _fechaNacimiento = fecha.toDate();
      }
    } catch (_) {
      setState(() {
        _error = 'No se pudo cargar el perfil.';
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final ahora = DateTime.now();
    final fechaInicial = _fechaNacimiento ?? DateTime(2000, 1, 1);

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(ahora.year - 10, ahora.month, ahora.day),
      helpText: 'Selecciona tu fecha de nacimiento',
    );

    if (seleccionada != null && mounted) {
      setState(() => _fechaNacimiento = seleccionada);
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }

  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'missing-uid':
        return 'No hay sesion activa para actualizar el perfil.';
      case 'not-found':
        return 'No se encontro el documento del perfil. Intenta guardar de nuevo.';
      case 'permission-denied':
        return 'No tienes permisos para editar este perfil.';
      case 'network-request-failed':
        return 'Sin conexion a internet. Verifica tu red.';
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesion y luego intenta eliminar la cuenta.';
      case 'user-token-expired':
      case 'invalid-user-token':
        return 'La sesion expiro. Inicia sesion nuevamente.';
      default:
        return 'No se pudo actualizar el perfil. Intenta de nuevo.';
    }
  }

  Future<void> _confirmarYEliminarCuenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: const Text(
            'Esta accion marcara tu cuenta como eliminada y tratara de borrarla de autenticacion. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() {
      _eliminando = true;
      _error = null;
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
        await _pedirContrasenaYReautenticar();
        return;
      }
      setState(() => _error = _mensajeError(e.code));
    } on FirebaseException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } catch (_) {
      setState(
        () => _error = 'No se pudo eliminar la cuenta. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  Future<void> _pedirContrasenaYReautenticar() async {
    final contrasenaController = TextEditingController();
    bool procesando = false;

    final reautenticar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reautenticar cuenta'),
              content: TextField(
                controller: contrasenaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Ingresa tu contraseña actual',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: procesando
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: procesando
                      ? null
                      : () async {
                          if (contrasenaController.text.trim().isEmpty) {
                            return;
                          }
                          setDialogState(() => procesando = true);
                          try {
                            await _authService.reautenticarConContrasena(
                              email: _authService.usuarioActual?.email ?? '',
                              password: contrasenaController.text.trim(),
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => procesando = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(_mensajeError(e.code))),
                              );
                            }
                          }
                        },
                  child: procesando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
    if (reautenticar != true) return;

    if (!mounted) return;
    setState(() => _eliminando = true);

    try {
      await _authService.eliminarCuentaUsuario();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada correctamente.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } on FirebaseException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } catch (_) {
      setState(
        () => _error = 'No se pudo eliminar la cuenta. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      setState(() => _error = 'Selecciona tu fecha de nacimiento.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _authService.actualizarPerfilUsuario(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        fechaNacimiento: _fechaNacimiento!,
        telefono: _telefonoController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } on FirebaseException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } catch (_) {
      setState(() => _error = 'Ocurrio un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.usuarioActual?.email ?? 'Sin correo';

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion de perfil')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Correo: $email'),
                      const SizedBox(height: 8),
                      Text('Estado: ${_estado == 1 ? 'Activo' : 'Eliminado'}'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                            ? 'Ingresa tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidoController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                        ),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                            ? 'Ingresa tu apellido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      FormField<DateTime>(
                        validator: (_) => _fechaNacimiento == null
                            ? 'Selecciona tu fecha de nacimiento'
                            : null,
                        builder: (campo) {
                          return InkWell(
                            onTap: _guardando
                                ? null
                                : () async {
                                    await _seleccionarFechaNacimiento();
                                    campo.didChange(_fechaNacimiento);
                                  },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Fecha de nacimiento',
                                hintText: 'DD/MM/AAAA',
                                suffixIcon: const Icon(Icons.calendar_today),
                                errorText: campo.errorText,
                              ),
                              child: Text(
                                _fechaNacimiento == null
                                    ? 'Selecciona una fecha'
                                    : _formatearFecha(_fechaNacimiento!),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numero telefonico',
                          hintText: '+521234567890',
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Ingresa tu numero telefonico';
                          }
                          if (!valor.trim().startsWith('+') ||
                              valor.trim().length < 11) {
                            return 'Usa formato internacional. Ejemplo: +521234567890';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: (_guardando || _eliminando)
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const EditarNegocioScreen(),
                                  ),
                                );
                              },
                        child: const Text('Editar negocio'),
                      ),
                      const SizedBox(height: 12),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: (_guardando || _eliminando)
                            ? null
                            : _guardarCambios,
                        child: _guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: (_guardando || _eliminando)
                            ? null
                            : _confirmarYEliminarCuenta,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: _eliminando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Eliminar cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
