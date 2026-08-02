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
      setState(() => _error = _mensajeError(e.code));
    } catch (_) {
      setState(
        () => _error = 'No se pudo registrar el negocio. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
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

  @override
  Widget build(BuildContext context) {
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
                TextFormField(
                  controller: _nombreNegocioController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del negocio',
                  ),
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Ingresa el nombre del negocio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _direccionController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Direccion'),
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Ingresa la direccion'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefono',
                    hintText: '+521234567890',
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
                  decoration: const InputDecoration(
                    labelText: 'Correo electronico',
                  ),
                  validator: (valor) => (valor == null || !valor.contains('@'))
                      ? 'Ingresa un correo valido'
                      : null,
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
                  onPressed: _cargando ? null : _guardarNegocio,
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar negocio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
