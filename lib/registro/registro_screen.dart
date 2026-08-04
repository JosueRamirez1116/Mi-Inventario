import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/registro/registro_negocio_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  DateTime? _fechaNacimiento;

  bool _cargando = false;
  bool _ocultarPassword = true;
  bool _ocultarConfirmPassword = true;
  String? _error;

  // Colores base del tema (mismos que login_screen.dart)
  static const Color _colorPrimario = Color(0xFF6C63FF);
  static const Color _colorPrimarioOscuro = Color(0xFF4A3FCF);
  static const Color _colorFondoClaro = Color(0xFFF3F1FF);

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _authService.registrarConPerfil(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        fechaNacimiento: _fechaNacimiento!,
        telefono: _telefonoController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegistroNegocioScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mensajeError(e.code, e.message));
    } on FirebaseException catch (e) {
      setState(() => _error = _mensajeError(e.code, e.message));
    } catch (_) {
      setState(() => _error = 'Ocurrio un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensajeError(String codigo, [String? mensaje]) {
    switch (codigo) {
      case 'email-already-in-use':
        return 'Este correo ya esta registrado.';
      case 'invalid-email':
        return 'El correo no tiene un formato valido.';
      case 'weak-password':
        return 'La contrasena es muy debil. Usa al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sin conexion a internet. Verifica tu red.';
      case 'permission-denied':
        return 'No hay permisos para guardar el usuario en la base de datos.';
      case 'missing-uid':
        return 'No se pudo crear el perfil del usuario. Intenta de nuevo.';
      default:
        final detalle = mensaje?.trim();
        if (detalle != null && detalle.isNotEmpty) {
          return 'Error ($codigo): $detalle';
        }
        return 'No se pudo crear la cuenta. Intenta de nuevo. [$codigo]';
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _colorPrimario,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
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

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
      prefixIcon: Icon(icono, color: _colorPrimario),
      suffixIcon: sufijo,
      filled: true,
      fillColor: _colorFondoClaro,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _colorPrimario, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondoClaro,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Crear cuenta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
            stops: [0.0, 0.18, 0.32],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Únete a MiInventario',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completa tus datos para crear tu cuenta',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Datos personales',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nombreController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoracionCampo(
                            label: 'Nombre',
                            icono: Icons.person_outline,
                          ),
                          validator: (valor) =>
                              (valor == null || valor.trim().isEmpty)
                              ? 'Ingresa tu nombre'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _apellidoController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoracionCampo(
                            label: 'Apellido',
                            icono: Icons.badge_outlined,
                          ),
                          validator: (valor) =>
                              (valor == null || valor.trim().isEmpty)
                              ? 'Ingresa tu apellido'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        FormField<DateTime>(
                          validator: (_) => _fechaNacimiento == null
                              ? 'Selecciona tu fecha de nacimiento'
                              : null,
                          builder: (campo) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _cargando
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
                                  sufijo: const Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: _colorPrimario,
                                  ),
                                ).copyWith(errorText: campo.errorText),
                                child: Text(
                                  _fechaNacimiento == null
                                      ? 'Selecciona una fecha'
                                      : _formatearFecha(_fechaNacimiento!),
                                  style: TextStyle(
                                    color: _fechaNacimiento == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Contacto',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: _decoracionCampo(
                            label: 'Número telefónico',
                            hint: '+521234567890',
                            icono: Icons.phone_outlined,
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
                        Text(
                          'Seguridad',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _ocultarConfirmPassword,
                          decoration: _decoracionCampo(
                            label: 'Confirmar contraseña',
                            icono: Icons.lock_outline,
                            sufijo: IconButton(
                              icon: Icon(
                                _ocultarConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () => setState(
                                () => _ocultarConfirmPassword =
                                    !_ocultarConfirmPassword,
                              ),
                            ),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.isEmpty) {
                              return 'Confirma tu contraseña';
                            }
                            if (valor != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
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
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorPrimario,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: _colorPrimario.withValues(
                                alpha: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _cargando ? null : _registrar,
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
                                    'Crear cuenta',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}