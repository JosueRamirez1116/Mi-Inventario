import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';

class EditarNegocioScreen extends StatefulWidget {
  const EditarNegocioScreen({super.key});

  @override
  State<EditarNegocioScreen> createState() => _EditarNegocioScreenState();
}

class _EditarNegocioScreenState extends State<EditarNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreNegocioController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _cargando = true;
  bool _guardando = false;
  bool _eliminando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNegocio();
  }

  Future<void> _cargarNegocio() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await _authService.obtenerPerfilNegocio();
      if (data == null) {
        setState(() {
          _error = 'No se encontro informacion del negocio.';
          _cargando = false;
        });
        return;
      }

      _nombreNegocioController.text = (data['nombreNegocio'] ?? '').toString();
      _direccionController.text = (data['direccion'] ?? '').toString();
      _telefonoController.text = (data['telefono'] ?? '').toString();
      _correoController.text = (data['correo'] ?? '').toString();
    } catch (_) {
      setState(() => _error = 'No se pudo cargar el negocio.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'missing-uid':
        return 'No hay sesion activa para editar el negocio.';
      case 'permission-denied':
        return 'No tienes permisos para editar este negocio.';
      case 'network-request-failed':
        return 'Sin conexion a internet. Verifica tu red.';
      default:
        return 'No se pudo guardar el negocio. Intenta de nuevo.';
    }
  }

  Future<void> _confirmarYEliminarNegocio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar negocio'),
          content: const Text(
            'Esta accion marcara el negocio como eliminado. ¿Deseas continuar?',
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
      await _authService.eliminarNegocio();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negocio eliminado correctamente.')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } on FirebaseException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } catch (_) {
      setState(
        () => _error = 'No se pudo eliminar el negocio. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _authService.actualizarPerfilNegocio(
        nombreNegocio: _nombreNegocioController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negocio actualizado correctamente.')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } on FirebaseException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } on Exception catch (_) {
      setState(
        () => _error = 'No se pudo guardar el negocio. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
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
      appBar: AppBar(title: const Text('Editar negocio')),
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
                      TextFormField(
                        controller: _nombreNegocioController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del negocio',
                        ),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                            ? 'Ingresa el nombre del negocio'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _direccionController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Direccion',
                        ),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
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
                        validator: (valor) =>
                            (valor == null || !valor.contains('@'))
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
                            : const Text('Guardar negocio'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: (_guardando || _eliminando)
                            ? null
                            : _confirmarYEliminarNegocio,
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
                            : const Text('Eliminar negocio'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
