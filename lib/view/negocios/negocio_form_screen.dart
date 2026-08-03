import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_inventario/controller/negocios_controller.dart';
import 'package:mi_inventario/model/negocio_model.dart';

class NegocioFormScreen extends StatefulWidget {
  const NegocioFormScreen({super.key, required this.controller, this.negocio});

  final NegociosController controller;
  final NegocioModel? negocio;

  @override
  State<NegocioFormScreen> createState() {
    return _NegocioFormScreenState();
  }
}

class _NegocioFormScreenState extends State<NegocioFormScreen> {
  static const Color _colorPrincipal = Color.fromARGB(255, 28, 83, 170);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;

  bool _guardando = false;

  bool get esEdicion => widget.negocio != null;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.negocio?.nombre ?? '',
    );

    _direccionController = TextEditingController(
      text: widget.negocio?.direccion ?? '',
    );

    _telefonoController = TextEditingController(
      text: widget.negocio?.telefono ?? '',
    );

    _correoController = TextEditingController(
      text: widget.negocio?.correo ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();

    super.dispose();
  }

  Future<void> _guardarNegocio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _guardando = true;
    });

    final negocio = NegocioModel(
      id: widget.negocio?.id ?? '',
      nombre: _nombreController.text.trim(),
      direccion: _direccionController.text.trim(),
      telefono: _telefonoController.text.trim(),
      correo: _correoController.text.trim(),
      estado: widget.negocio?.estado ?? 1,
      usuarioId: widget.negocio?.usuarioId ?? '',
    );

    try {
      if (esEdicion) {
        await widget.controller.actualizarNegocio(widget.negocio!.id, negocio);
      } else {
        await widget.controller.agregarNegocio(negocio);
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Firebase rechazó la operación'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el negocio: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  String? _validarNombre(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingrese el nombre del negocio';
    }

    if (valor.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    return null;
  }

  String? _validarDireccion(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingrese la dirección del negocio';
    }

    if (valor.trim().length < 5) {
      return 'Ingrese una dirección válida';
    }

    return null;
  }

  String? _validarTelefono(String? valor) {
    final telefono = valor?.trim() ?? '';

    if (telefono.isEmpty) {
      return 'Ingrese el número telefónico';
    }

    if (telefono.length != 8) {
      return 'El teléfono debe contener 8 dígitos';
    }

    return null;
  }

  String? _validarCorreo(String? valor) {
    final correo = valor?.trim() ?? '';

    if (correo.isEmpty) {
      return 'Ingrese el correo electrónico';
    }

    final expresionCorreo = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!expresionCorreo.hasMatch(correo)) {
      return 'Ingrese un correo electrónico válido';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 244, 250),
      appBar: AppBar(
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
        title: Text(esEdicion ? 'Editar negocio' : 'Registrar negocio'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 70,
                    color: _colorPrincipal,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    esEdicion ? 'Actualizar información' : 'Nuevo negocio',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Complete los datos solicitados.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 25),
                TextFormField(
                  controller: _nombreController,
                  validator: _validarNombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del negocio',
                    hintText: 'Ejemplo: Mi Tienda',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _direccionController,
                  validator: _validarDireccion,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    hintText: 'Ejemplo: Choloma, Cortés',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  validator: _validarTelefono,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Número telefónico',
                    hintText: 'Ejemplo: 98765432',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  validator: _validarCorreo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'Ejemplo: negocio@gmail.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarNegocio,
                    icon: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(esEdicion ? Icons.save : Icons.add_business),
                    label: Text(
                      _guardando
                          ? 'Guardando...'
                          : esEdicion
                          ? 'Actualizar negocio'
                          : 'Guardar negocio',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorPrincipal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
