import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/model/productos_model.dart';

/// Controlador de la pantalla "Agregar producto".
///
/// Maneja el formulario, la validación y el guardado del producto
/// en Firestore. El escaneo de código de barra y la generación
/// automática del código de producto se agregarán más adelante.
class ProductosController extends GetxController {
  final CollectionReference<Map<String, dynamic>> _referenciaProductos =
      FirebaseFirestore.instance.collection('productos');

  final formularioKey = GlobalKey<FormState>();

  final controladorNombre = TextEditingController();
  final controladorDescripcion = TextEditingController();
  final controladorIdCategoria = TextEditingController();
  final controladorIdNegocio = TextEditingController();
  final controladorCodigoBarra = TextEditingController();
  final controladorCodigoProducto = TextEditingController();
  final controladorStockMaximo = TextEditingController();
  final controladorStockMinimo = TextEditingController();
  final controladorUnidadMedida = TextEditingController();
  final controladorStockActual = TextEditingController();
  final controladorPrecioCompra = TextEditingController();
  final controladorPrecioVenta = TextEditingController();

  final RxBool estaGuardando = false.obs;

  /// Valida el formulario y guarda el nuevo producto en Firestore.
  Future<void> guardarProducto() async {
    if (!formularioKey.currentState!.validate()) return;

    final stockMaximo = double.parse(controladorStockMaximo.text.trim());
    final stockMinimo = double.parse(controladorStockMinimo.text.trim());
    if (stockMinimo > stockMaximo) {
      Get.snackbar(
        'Datos inválidos',
        'El stock mínimo no puede ser mayor que el stock máximo',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    estaGuardando.value = true;
    try {
      final nuevoProducto = ProductosModel(
        nombreProducto: controladorNombre.text.trim(),
        descripcion: controladorDescripcion.text.trim(),
        idCategoria: controladorIdCategoria.text.trim(),
        idNegocio: controladorIdNegocio.text.trim(),
        codigoBarra: controladorCodigoBarra.text.trim().isEmpty
            ? null
            : controladorCodigoBarra.text.trim(),
        estado: 1,
        stockMaximo: stockMaximo,
        stockMinimo: stockMinimo,
        unidadMedida: controladorUnidadMedida.text.trim(),
        stockActual: double.parse(controladorStockActual.text.trim()),
        precioCompra: double.parse(controladorPrecioCompra.text.trim()),
        precioVenta: double.parse(controladorPrecioVenta.text.trim()),
        fotoProducto: '',
        codigoProducto: controladorCodigoProducto.text.trim(),
        fechaCreacion: DateTime.now(),
      );

      await _referenciaProductos.add(nuevoProducto.aMapa());

      Get.back(result: true);
      Get.snackbar(
        'Producto agregado',
        'El producto se guardó correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
      );
    } catch (error) {
      Get.snackbar(
        'Error',
        'No se pudo guardar el producto: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      estaGuardando.value = false;
    }
  }

  String? validarCampoObligatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  String? validarCampoNumerico(String? valor) {
    final errorObligatorio = validarCampoObligatorio(valor);
    if (errorObligatorio != null) return errorObligatorio;
    if (double.tryParse(valor!.trim()) == null) {
      return 'Ingrese un número válido';
    }
    return null;
  }

  @override
  void onClose() {
    controladorNombre.dispose();
    controladorDescripcion.dispose();
    controladorIdCategoria.dispose();
    controladorIdNegocio.dispose();
    controladorCodigoBarra.dispose();
    controladorCodigoProducto.dispose();
    controladorStockMaximo.dispose();
    controladorStockMinimo.dispose();
    controladorUnidadMedida.dispose();
    controladorStockActual.dispose();
    controladorPrecioCompra.dispose();
    controladorPrecioVenta.dispose();
    super.onClose();
  }
}
