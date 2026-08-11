import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_inventario/controller/productos_controller.dart';
import 'package:mi_inventario/model/productos_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pantalla para ingresar los datos de un nuevo producto.
class AgregarProductosScreen extends StatefulWidget {
  const AgregarProductosScreen({super.key, this.producto});

  final ProductosModel? producto;

  @override
  State<AgregarProductosScreen> createState() => _AgregarProductosScreenState();
}

class _AgregarProductosScreenState extends State<AgregarProductosScreen> {
  late final ProductosController controller;
  TextEditingController? _unidadAutocompleteController;
  VoidCallback? _unidadAutocompleteListener;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ProductosController>()) {
      controller = Get.find<ProductosController>();
    } else {
      controller = Get.put(ProductosController());
    }

    if (_esEdicion) {
      controller.cargarProductoEnFormulario(widget.producto!);
    } else {
      controller.limpiarFormulario();
    }
  }

  Future<void> _generarCodigo() async {
    try {
      final codigo = await controller.generarCodigoBarraEAN13Unico();
      controller.controladorCodigoBarra.text = codigo;
      Get.snackbar(
        'Código generado',
        'EAN-13: $codigo',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo generar código: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _mostrarSelectorFoto() async {
    final tieneFoto =
        controller.imagenSeleccionada.value != null ||
        controller.fotoProductoUrl.value.isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  controller.seleccionarImagenProducto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  controller.seleccionarImagenProducto(ImageSource.gallery);
                },
              ),
              if (tieneFoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Quitar foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    controller.quitarFotoProducto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _escanearCodigo() async {
    try {
      final resultado = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _MobileScannerPage()),
      );
      if (resultado != null && resultado.isNotEmpty) {
        controller.controladorCodigoBarra.text = resultado;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo escanear: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    // limpiar any autocomplete listener
    if (_unidadAutocompleteController != null &&
        _unidadAutocompleteListener != null) {
      _unidadAutocompleteController!.removeListener(
        _unidadAutocompleteListener!,
      );
    }
    _unidadAutocompleteController = null;
    _unidadAutocompleteListener = null;

    controller.limpiarFormulario();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const appBarColor = Color(0xFF4338CA);
    const fieldTextColor = Color(0xFF1E1B2E);
    const fieldFillColor = Color(0xFFF5F6FA);

    final fieldTextStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: fieldTextColor,
    );

    final sectionTitleStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: fieldTextColor,
    );

    InputDecoration inputDecoration({
      required String labelText,
      String? helperText,
    }) {
      return InputDecoration(
        labelText: labelText,
        helperText: helperText,
        labelStyle: fieldTextStyle,
        helperStyle: fieldTextStyle.copyWith(
          fontSize: 10,
          color: fieldTextColor.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: fieldFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: fieldTextColor.withAlpha((0.15 * 255).round()),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: appBarColor, width: 2),
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

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: sectionTitleStyle),
      );
    }

    Widget sectionCard(List<Widget> children) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar producto' : 'Agregar producto',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: const Icon(Icons.save),
              tooltip: _esEdicion ? 'Actualizar producto' : 'Guardar producto',
              onPressed: controller.estaGuardando.value
                  ? null
                  : () => controller.guardarProducto(
                      productoId: widget.producto?.id,
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: controller.formularioKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              sectionTitle('Negocio y categoría'),
              sectionCard([
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: controller.idNegocioSeleccionado.value.isEmpty
                        ? null
                        : controller.idNegocioSeleccionado.value,
                    decoration: inputDecoration(labelText: 'Negocio'),
                    items: controller.negociosUsuario.map((negocio) {
                      return DropdownMenuItem<String>(
                        value: negocio['id'],
                        child: Text(negocio['nombre'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (valor) async {
                      if (valor == null) return;
                      controller.idNegocioSeleccionado.value = valor;
                      await controller.cargarCategoriasDelNegocio(valor);
                    },
                    validator: (valor) => valor == null || valor.isEmpty
                        ? 'Selecciona un negocio'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue:
                        controller.idCategoriaSeleccionada.value.isEmpty
                        ? null
                        : controller.idCategoriaSeleccionada.value,
                    decoration: inputDecoration(labelText: 'Categoría'),
                    items: controller.categoriasNegocio.map((categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria['id'],
                        child: Text(categoria['nombre'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      if (valor != null) {
                        controller.idCategoriaSeleccionada.value = valor;
                      }
                    },
                    validator: (valor) => valor == null || valor.isEmpty
                        ? 'Selecciona una categoría'
                        : null,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              sectionTitle('Detalle del producto'),
              sectionCard([
                TextFormField(
                  controller: controller.controladorNombre,
                  style: fieldTextStyle,
                  decoration: inputDecoration(labelText: 'Nombre del producto'),
                  onChanged: (valor) {
                    // Si es creación y aún no hay código, asignar uno incremental cuando empiece a escribir nombre
                    if (!_esEdicion &&
                        controller.controladorCodigoProducto.text
                            .trim()
                            .isEmpty &&
                        valor.trim().isNotEmpty) {
                      controller.asignarCodigoProductoIncremental();
                    }
                  },
                  validator: controller.validarCampoObligatorio,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.controladorDescripcion,
                  style: fieldTextStyle,
                  decoration: inputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                  validator: controller.validarCampoObligatorio,
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final archivoLocal = controller.imagenSeleccionada.value;
                  final urlExistente = controller.fotoProductoUrl.value;
                  final tieneFoto =
                      archivoLocal != null || urlExistente.isNotEmpty;

                  Widget contenidoFoto;
                  if (archivoLocal != null) {
                    contenidoFoto = Image.file(archivoLocal, fit: BoxFit.cover);
                  } else if (urlExistente.isNotEmpty) {
                    contenidoFoto = Image.network(
                      urlExistente,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    );
                  } else {
                    contenidoFoto = const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.grey,
                    );
                  }

                  return Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: fieldFillColor,
                          alignment: Alignment.center,
                          child: contenidoFoto,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Foto del producto (opcional)',
                              style: fieldTextStyle,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: controller.subiendoImagen.value
                                  ? null
                                  : _mostrarSelectorFoto,
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: Text(
                                tieneFoto ? 'Cambiar foto' : 'Agregar foto',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.controladorCodigoProducto,
                  style: fieldTextStyle,
                  readOnly: true,
                  decoration: inputDecoration(labelText: 'Código de producto')
                      .copyWith(
                        helperText: 'Se asigna automáticamente (5 dígitos)',
                      ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: controller.controladorCodigoBarra,
                  style: fieldTextStyle,
                  decoration:
                      inputDecoration(
                        labelText: 'Código de barra (opcional)',
                      ).copyWith(
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.auto_awesome,
                                color: Colors.indigo,
                              ),
                              tooltip: 'Generar EAN-13',
                              onPressed: _generarCodigo,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.indigo,
                              ),
                              tooltip: 'Escanear código',
                              onPressed: _escanearCodigo,
                            ),
                          ],
                        ),
                      ),
                ),
              ]),
              const SizedBox(height: 16),
              sectionTitle('Inventario'),
              sectionCard([
                Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final commonUnits = <String>[
                            'unidad',
                            'pieza',
                            'kg',
                            'g',
                            'l',
                            'ml',
                            'm',
                            'cm',
                            'pack',
                            'caja',
                            'par',
                            'litro',
                            'mililitro',
                          ];

                          return FormField<String>(
                            initialValue:
                                controller.controladorUnidadMedida.text,
                            validator: (_) =>
                                controller.validarCampoObligatorio(
                                  controller.controladorUnidadMedida.text,
                                ),
                            builder: (state) {
                              return Autocomplete<String>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      final text = textEditingValue.text
                                          .toLowerCase();
                                      if (text.isEmpty) return commonUnits;
                                      return commonUnits.where(
                                        (u) => u.toLowerCase().contains(text),
                                      );
                                    },
                                onSelected: (selection) {
                                  controller.controladorUnidadMedida.text =
                                      selection;
                                  state.didChange(selection);
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      textEditingController,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      // Ensure controller and internal controller stay in sync
                                      textEditingController.text = controller
                                          .controladorUnidadMedida
                                          .text;
                                      textEditingController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: textEditingController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                      textEditingController.addListener(() {
                                        controller
                                                .controladorUnidadMedida
                                                .text =
                                            textEditingController.text;
                                        state.didChange(
                                          textEditingController.text,
                                        );
                                      });

                                      return TextFormField(
                                        controller: textEditingController,
                                        focusNode: focusNode,
                                        style: fieldTextStyle,
                                        decoration: inputDecoration(
                                          labelText: 'Unidad de medida',
                                        ),
                                        validator: (_) =>
                                            controller.validarCampoObligatorio(
                                              controller
                                                  .controladorUnidadMedida
                                                  .text,
                                            ),
                                      );
                                    },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controller.controladorStockActual,
                        style: fieldTextStyle,
                        decoration: inputDecoration(labelText: 'Stock actual'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: controller.validarCampoNumerico,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.controladorStockMaximo,
                        style: fieldTextStyle,
                        decoration: inputDecoration(labelText: 'Stock máximo'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: controller.validarCampoNumerico,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controller.controladorStockMinimo,
                        style: fieldTextStyle,
                        decoration: inputDecoration(labelText: 'Stock mínimo'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: controller.validarCampoNumerico,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              sectionTitle('Precio en Lps'),
              sectionCard([
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.controladorPrecioCompra,
                        style: fieldTextStyle,
                        decoration: inputDecoration(
                          labelText: 'Precio de compra',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: controller.validarCampoNumerico,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controller.controladorPrecioVenta,
                        style: fieldTextStyle,
                        decoration: inputDecoration(
                          labelText: 'Precio de venta',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: controller.validarCampoNumerico,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              Obx(
                () => ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appBarColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  icon: const Icon(Icons.save),
                  label: controller.estaGuardando.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar producto'),
                  onPressed: controller.estaGuardando.value
                      ? null
                      : () => controller.guardarProducto(
                          productoId: widget.producto?.id,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileScannerPage extends StatefulWidget {
  const _MobileScannerPage({Key? key}) : super(key: key);

  @override
  State<_MobileScannerPage> createState() => _MobileScannerPageState();
}

class _MobileScannerPageState extends State<_MobileScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código')),
      body: MobileScanner(
        controller: _cameraController,
        onDetect: (capture) {
          if (_detected) return;
          if (capture.barcodes.isEmpty) return;
          final barcode = capture.barcodes.first;
          final String? code = barcode.rawValue ?? barcode.displayValue;
          if (code == null || code.isEmpty) return;
          _detected = true;
          Navigator.of(context).pop(code);
        },
      ),
    );
  }
}
