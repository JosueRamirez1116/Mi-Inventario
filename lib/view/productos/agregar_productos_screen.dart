import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/productos_controller.dart';

/// Pantalla para ingresar los datos de un nuevo producto.
class AgregarProductosScreen extends GetView<ProductosController> {
  const AgregarProductosScreen({super.key});

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
          color: fieldTextColor.withOpacity(0.7),
        ),
        filled: true,
        fillColor: fieldFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: fieldTextColor.withOpacity(0.15)),
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
        title: const Text(
          'Agregar producto',
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
              tooltip: 'Guardar producto',
              onPressed: controller.estaGuardando.value
                  ? null
                  : controller.guardarProducto,
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
              sectionTitle('Negocio'),
              sectionCard([
                TextFormField(
                  controller: controller.controladorIdNegocio,
                  style: fieldTextStyle,
                  decoration: inputDecoration(labelText: 'ID de negocio'),
                ),
              ]),
              const SizedBox(height: 16),
              sectionTitle('Detalle del producto'),
              sectionCard([
                TextFormField(
                  controller: controller.controladorNombre,
                  style: fieldTextStyle,
                  decoration: inputDecoration(labelText: 'Nombre del producto'),
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
                TextFormField(
                  controller: controller.controladorCodigoProducto,
                  style: fieldTextStyle,
                  decoration: inputDecoration(labelText: 'Código de producto'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.controladorIdCategoria,
                  style: fieldTextStyle,
                  decoration: inputDecoration(labelText: 'ID de categoría'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.controladorCodigoBarra,
                  style: fieldTextStyle,
                  decoration: inputDecoration(
                    labelText: 'Código de barra (opcional)',
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              sectionTitle('Inventario'),
              sectionCard([
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.controladorUnidadMedida,
                        style: fieldTextStyle,
                        decoration: inputDecoration(
                          labelText: 'Unidad de medida',
                        ),
                        validator: controller.validarCampoObligatorio,
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
              sectionTitle('Precio Lps'),
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
                      : controller.guardarProducto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
