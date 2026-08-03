import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/model/productos_model.dart';

/// Controlador de la pantalla "Agregar producto".
///
/// Maneja el formulario, la validación y el guardado del producto
/// en Firestore. El escaneo de código de barra y la generación
/// automática del código de producto se agregarán más adelante.
class ProductosController extends GetxController {
  CollectionReference<Map<String, dynamic>> get _referenciaProductos =>
      FirebaseFirestore.instance.collection('productos');

  final formularioKey = GlobalKey<FormState>();

  final controladorNombre = TextEditingController();
  final controladorDescripcion = TextEditingController();
  final controladorCodigoBarra = TextEditingController();
  final controladorCodigoProducto = TextEditingController();
  final controladorStockMaximo = TextEditingController();
  final controladorStockMinimo = TextEditingController();
  final controladorUnidadMedida = TextEditingController();
  final controladorStockActual = TextEditingController();
  final controladorPrecioCompra = TextEditingController();
  final controladorPrecioVenta = TextEditingController();

  final RxString idNegocioSeleccionado = ''.obs;
  final RxString idCategoriaSeleccionada = ''.obs;
  final RxList<Map<String, String>> negociosUsuario = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> categoriasNegocio = <Map<String, String>>[].obs;
  final RxBool cargandoNegocios = false.obs;
  final RxBool cargandoCategorias = false.obs;
  final RxBool estaGuardando = false.obs;

  @override
  void onInit() {
    super.onInit();
    cargarNegociosUsuario();
  }

  Future<void> cargarNegociosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    cargandoNegocios.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('negocios')
          .where('usuarioId', isEqualTo: uid)
          .where('estado', isEqualTo: 1)
          .get();

      negociosUsuario.assignAll(
        snapshot.docs.map((doc) {
          final datos = doc.data();
          final nombre = datos['nombre']?.toString() ??
              datos['nombreNegocio']?.toString() ??
              'Sin nombre';
          return {'id': doc.id, 'nombre': nombre};
        }).toList(),
      );

      if (negociosUsuario.isNotEmpty) {
        if (idNegocioSeleccionado.value.isEmpty) {
          idNegocioSeleccionado.value = negociosUsuario.first['id'] ?? '';
        }
        await cargarCategoriasDelNegocio(idNegocioSeleccionado.value);
      } else {
        idNegocioSeleccionado.value = '';
        idCategoriaSeleccionada.value = '';
        categoriasNegocio.clear();
      }
    } finally {
      cargandoNegocios.value = false;
    }
  }

  Future<void> cargarCategoriasDelNegocio(String negocioId) async {
    if (negocioId.isEmpty) {
      categoriasNegocio.clear();
      idCategoriaSeleccionada.value = '';
      return;
    }

    cargandoCategorias.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('categorias')
          .where('usuarioId', isEqualTo: uid)
          .where('negocioId', isEqualTo: negocioId)
          .where('estado', isEqualTo: 1)
          .get();

      categoriasNegocio.assignAll(
        snapshot.docs.map((doc) {
          final datos = doc.data();
          return {
            'id': doc.id,
            'nombre': datos['nombre']?.toString() ?? 'Sin nombre',
          };
        }).toList(),
      );

      if (categoriasNegocio.isNotEmpty) {
        if (!categoriasNegocio.any((categoria) => categoria['id'] == idCategoriaSeleccionada.value)) {
          idCategoriaSeleccionada.value = categoriasNegocio.first['id'] ?? '';
        }
      } else {
        idCategoriaSeleccionada.value = '';
      }
    } finally {
      cargandoCategorias.value = false;
    }
  }

  void limpiarFormulario() {
    controladorNombre.clear();
    controladorDescripcion.clear();
    controladorCodigoBarra.clear();
    controladorCodigoProducto.clear();
    controladorStockMaximo.clear();
    controladorStockMinimo.clear();
    controladorUnidadMedida.clear();
    controladorStockActual.clear();
    controladorPrecioCompra.clear();
    controladorPrecioVenta.clear();

    formularioKey.currentState?.reset();
  }

  /// Valida el formulario y guarda el nuevo producto en Firestore.
  Future<void> guardarProducto() async {
    if (!formularioKey.currentState!.validate()) return;
    if (idNegocioSeleccionado.value.isEmpty) {
      Get.snackbar('Datos inválidos', 'Selecciona un negocio antes de guardar');
      return;
    }
    if (idCategoriaSeleccionada.value.isEmpty) {
      Get.snackbar('Datos inválidos', 'Selecciona una categoría antes de guardar');
      return;
    }

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
        idCategoria: idCategoriaSeleccionada.value,
        idNegocio: idNegocioSeleccionado.value,
        usuarioId: FirebaseAuth.instance.currentUser?.uid ?? '',
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

      limpiarFormulario();
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
