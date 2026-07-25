import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/productos_controller.dart';

/// Pantalla para ingresar los datos de un nuevo producto.
class AgregarProductosScreen extends GetView<ProductosController> {
  const AgregarProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: SafeArea(
        child: Form(
          key: controller.formularioKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: controller.controladorNombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                ),
                validator: controller.validarCampoObligatorio,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.controladorDescripcion,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: controller.validarCampoObligatorio,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.controladorCodigoProducto,
                decoration: const InputDecoration(
                  labelText: 'Código de producto',
                  helperText: 'Temporal: se ingresa manualmente por ahora',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.controladorIdCategoria,
                decoration: const InputDecoration(
                  labelText: 'ID de categoría',
                  helperText: 'Temporal: se ingresa manualmente por ahora',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.controladorIdNegocio,
                decoration: const InputDecoration(
                  labelText: 'ID de negocio',
                  helperText: 'Temporal: se ingresa manualmente por ahora',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.controladorCodigoBarra,
                decoration: const InputDecoration(
                  labelText: 'Código de barra (opcional)',
                  helperText: 'Por ahora se ingresa manual, luego se escanea',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.controladorUnidadMedida,
                decoration: const InputDecoration(
                  labelText: 'Unidad de medida',
                ),
                validator: controller.validarCampoObligatorio,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.controladorStockActual,
                      decoration: const InputDecoration(
                        labelText: 'Stock actual',
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
                      controller: controller.controladorStockMinimo,
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: controller.validarCampoNumerico,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.controladorStockMaximo,
                decoration: const InputDecoration(labelText: 'Stock máximo'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: controller.validarCampoNumerico,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.controladorPrecioCompra,
                      decoration: const InputDecoration(
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
                      decoration: const InputDecoration(
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
              const SizedBox(height: 24),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.estaGuardando.value
                      ? null
                      : controller.guardarProducto,
                  child: controller.estaGuardando.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
