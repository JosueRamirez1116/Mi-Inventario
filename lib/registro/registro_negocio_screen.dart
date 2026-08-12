import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';

class RegistroNegocioScreen extends StatefulWidget {
  const RegistroNegocioScreen({super.key});

  @override
  State<RegistroNegocioScreen> createState() => _RegistroNegocioScreenState();
}

class _RegistroNegocioScreenState extends State<RegistroNegocioScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreNegocioController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _cargando = false;
  String? _error;

  Future<void> _guardarNegocio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final uid = _authService.usuarioActual?.uid;

      if (uid == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'missing-uid',
          message: 'No hay un usuario autenticado.',
        );
      }

      await FirebaseFirestore.instance.collection('negocios').doc(uid).set({
        'uid': uid,
        'usuarioId': uid,
        'nombreNegocio': _nombreNegocioController.text.trim(),
        'nombre': _nombreNegocioController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'correo': _correoController.text.trim(),
        'estado': 1,
        'creadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negocio registrado correctamente.')),
      );

      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      setState(() {
        _error = _mensajeError(e.code);
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo registrar el negocio. Intenta de nuevo.';
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
      case 'missing-uid':
        return 'No hay una sesion activa para registrar el negocio.';

      case 'permission-denied':
        return 'No tienes permisos para registrar el negocio.';

      case 'network-request-failed':
        return 'Sin conexion a internet. Verifica tu red.';

      default:
        return 'No se pudo registrar el negocio. Intenta de nuevo.';
    }
  }

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();

    super.dispose();
  }

  InputDecoration _decoracionCampo({
    required String label,
    required IconData icono,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icono),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de negocio')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 54,
                  color: colores.primary,
                ),

                const SizedBox(height: 12),

                Text(
                  'Registra tu negocio',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colores.onSurface,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Completa la información de tu negocio para continuar.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: colores.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Información del negocio',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colores.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nombreNegocioController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoracionCampo(
                            label: 'Nombre del negocio',
                            icono: Icons.store_outlined,
                          ),
                          validator: (valor) =>
                              valor == null || valor.trim().isEmpty
                              ? 'Ingresa el nombre del negocio'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _direccionController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoracionCampo(
                            label: 'Direccion',
                            icono: Icons.location_on_outlined,
                          ),
                          validator: (valor) =>
                              valor == null || valor.trim().isEmpty
                              ? 'Ingresa la direccion'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: _decoracionCampo(
                            label: 'Telefono',
                            hint: '+521234567890',
                            icono: Icons.phone_outlined,
                          ),
                          validator: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingresa el telefono del negocio';
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
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _decoracionCampo(
                            label: 'Correo electronico',
                            icono: Icons.email_outlined,
                          ),
                          validator: (valor) =>
                              valor == null || !valor.contains('@')
                              ? 'Ingresa un correo valido'
                              : null,
                        ),

                        const SizedBox(height: 20),

                        if (_error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colores.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colores.error.withValues(alpha: 0.35),
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
                                      color: colores.onErrorContainer,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _cargando ? null : _guardarNegocio,
                            icon: _cargando
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colores.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _cargando ? 'Guardando...' : 'Guardar negocio',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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
