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
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
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
                      onTap: _cargando
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electronico',
                  ),
                  validator: (valor) => (valor == null || !valor.contains('@'))
                      ? 'Ingresa un correo valido'
                      : null,
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contrasena'),
                  validator: (valor) => (valor == null || valor.length < 6)
                      ? 'Minimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contrasena',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Confirma tu contrasena';
                    }
                    if (valor != _passwordController.text) {
                      return 'Las contrasenas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
