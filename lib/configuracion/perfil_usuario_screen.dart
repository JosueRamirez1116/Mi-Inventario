import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';

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
          _error = 'No se encontró información del perfil.';
        });
        return;
      }

      _nombreController.text = (data['nombre'] ?? '').toString();

      _apellidoController.text = (data['apellido'] ?? '').toString();

      _telefonoController.text = (data['telefono'] ?? '').toString();

      _estado = (data['estado'] as num?)?.toInt() ?? 1;

      final fecha = data['fechaNacimiento'];

      if (fecha is Timestamp) {
        _fechaNacimiento = fecha.toDate();
      }
    } catch (_) {
      setState(() {
        _error = 'No se pudo cargar la información del perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
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
      setState(() {
        _fechaNacimiento = seleccionada;
      });
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
        return 'No hay una sesión activa.';

      case 'not-found':
        return 'No se encontró el perfil del usuario.';

      case 'permission-denied':
        return 'No tienes permisos para editar este perfil.';

      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';

      case 'user-token-expired':
      case 'invalid-user-token':
        return 'La sesión expiró. Inicia sesión nuevamente.';

      default:
        return 'No se pudo actualizar el perfil. Intenta nuevamente.';
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaNacimiento == null) {
      setState(() {
        _error = 'Selecciona tu fecha de nacimiento.';
      });

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
      if (!mounted) return;

      setState(() {
        _error = _mensajeError(e.code);
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _mensajeError(e.code);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Ocurrió un error inesperado. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  InputDecoration _decoracionCampo({
    required String label,
    required IconData icono,
    String? hint,
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icono),
      suffixIcon: sufijo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
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
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    final email = _authService.usuarioActual?.email ?? 'Sin correo';

    final colorEstado = _estado == 1 ? colores.tertiary : colores.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil de usuario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: colores.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: colores.primary,
                                  size: 34,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_nombreController.text} '
                                      '${_apellidoController.text}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colores.onSurface,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colores.onSurfaceVariant,
                                      ),
                                    ),

                                    const SizedBox(height: 7),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorEstado.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _estado == 1 ? 'Activo' : 'Eliminado',
                                        style: TextStyle(
                                          color: colorEstado,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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

                      const SizedBox(height: 24),

                      Text(
                        'INFORMACIÓN PERSONAL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colores.onSurfaceVariant,
                          letterSpacing: 0.6,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nombreController,
                                textCapitalization: TextCapitalization.words,
                                decoration: _decoracionCampo(
                                  label: 'Nombre',
                                  icono: Icons.person_outline,
                                ),
                                validator: (valor) {
                                  if (valor == null || valor.trim().isEmpty) {
                                    return 'Ingresa tu nombre';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _apellidoController,
                                textCapitalization: TextCapitalization.words,
                                decoration: _decoracionCampo(
                                  label: 'Apellido',
                                  icono: Icons.badge_outlined,
                                ),
                                validator: (valor) {
                                  if (valor == null || valor.trim().isEmpty) {
                                    return 'Ingresa tu apellido';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              FormField<DateTime>(
                                validator: (_) {
                                  if (_fechaNacimiento == null) {
                                    return 'Selecciona tu fecha de nacimiento';
                                  }

                                  return null;
                                },
                                builder: (campo) {
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: _guardando
                                        ? null
                                        : () async {
                                            await _seleccionarFechaNacimiento();

                                            campo.didChange(_fechaNacimiento);
                                          },
                                    child: InputDecorator(
                                      decoration: _decoracionCampo(
                                        label: 'Fecha de nacimiento',
                                        hint: 'DD/MM/AAAA',
                                        icono: Icons.cake_outlined,
                                        sufijo: Icon(
                                          Icons.calendar_today_outlined,
                                          color: colores.primary,
                                          size: 20,
                                        ),
                                      ).copyWith(errorText: campo.errorText),
                                      child: Text(
                                        _fechaNacimiento == null
                                            ? 'Selecciona una fecha'
                                            : _formatearFecha(
                                                _fechaNacimiento!,
                                              ),
                                        style: TextStyle(
                                          color: _fechaNacimiento == null
                                              ? colores.onSurfaceVariant
                                              : colores.onSurface,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _telefonoController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+]'),
                                  ),
                                ],
                                decoration: _decoracionCampo(
                                  label: 'Número telefónico',
                                  hint: '+50499999999',
                                  icono: Icons.phone_outlined,
                                ),
                                validator: (valor) {
                                  final telefono = valor?.trim() ?? '';

                                  if (telefono.isEmpty) {
                                    return 'Ingresa tu número telefónico';
                                  }

                                  if (!telefono.startsWith('+')) {
                                    return 'Incluye el código de país. Ejemplo: +50499999999';
                                  }

                                  if (telefono.length < 11) {
                                    return 'Ingresa un número telefónico válido';
                                  }

                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colores.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colores.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: colores.error),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: colores.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _guardando ? null : _guardarCambios,
                          icon: _guardando
                              ? const SizedBox.shrink()
                              : const Icon(Icons.save_outlined),
                          label: _guardando
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colores.onPrimary,
                                  ),
                                )
                              : const Text(
                                  'Guardar cambios',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
