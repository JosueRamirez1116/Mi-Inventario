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

      final colores = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Firebase rechazó la operación',
            style: TextStyle(color: colores.onError),
          ),
          backgroundColor: colores.error,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final colores = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el negocio: $error',
            style: TextStyle(color: colores.onError),
          ),
          backgroundColor: colores.error,
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

  InputDecoration _decoracionCampo({
    required String label,
    required String hint,
    required IconData icono,
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
      appBar: AppBar(
        title: Text(
          esEdicion ? 'Editar negocio' : 'Registrar negocio',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: colores.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 44,
                            color: colores.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          esEdicion
                              ? 'Actualizar información'
                              : 'Nuevo negocio',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colores.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          esEdicion
                              ? 'Modifique los datos que desea actualizar.'
                              : 'Complete los datos solicitados.',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodyMedium?.copyWith(
                            color: colores.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'INFORMACIÓN DEL NEGOCIO',
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
                          validator: _validarNombre,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoracionCampo(
                            label: 'Nombre del negocio',
                            hint: 'Ejemplo: Mi Tienda',
                            icono: Icons.store,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _direccionController,
                          validator: _validarDireccion,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 2,
                          decoration: _decoracionCampo(
                            label: 'Dirección',
                            hint: 'Ejemplo: Choloma, Cortés',
                            icono: Icons.location_on,
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
                          decoration: _decoracionCampo(
                            label: 'Número telefónico',
                            hint: 'Ejemplo: 98765432',
                            icono: Icons.phone,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _correoController,
                          validator: _validarCorreo,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _decoracionCampo(
                            label: 'Correo electrónico',
                            hint: 'Ejemplo: negocio@gmail.com',
                            icono: Icons.email,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarNegocio,
                    icon: _guardando
                        ? const SizedBox.shrink()
                        : Icon(esEdicion ? Icons.save : Icons.add_business),
                    label: _guardando
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colores.onPrimary,
                            ),
                          )
                        : Text(
                            esEdicion
                                ? 'Actualizar negocio'
                                : 'Guardar negocio',
                            style: const TextStyle(
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
