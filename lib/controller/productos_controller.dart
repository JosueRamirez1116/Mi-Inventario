import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_inventario/model/productos_model.dart';

/// Controlador de la pantalla "Agregar producto".
///
/// Maneja el formulario, la validación y el guardado del producto
/// en Firestore. El escaneo de código de barra y la generación
/// automática del código de producto se agregarán más adelante.
class ProductosController extends GetxController {
  CollectionReference<Map<String, dynamic>> get _referenciaProductos =>
      FirebaseFirestore.instance.collection('productos');
  CollectionReference<Map<String, dynamic>> get _referenciaMovimientos =>
      FirebaseFirestore.instance.collection('movimientos');

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
  final RxList<Map<String, String>> negociosUsuario =
      <Map<String, String>>[].obs;
  final RxList<Map<String, String>> categoriasNegocio =
      <Map<String, String>>[].obs;
  final RxBool cargandoNegocios = false.obs;
  final RxBool cargandoCategorias = false.obs;
  final RxBool estaGuardando = false.obs;

  final ImagePicker _selectorImagen = ImagePicker();

  /// Imagen local recién elegida (cámara o galería), pendiente de subir.
  final Rx<File?> imagenSeleccionada = Rx<File?>(null);

  /// URL ya guardada en Firestore (modo edición) o resultante de una subida.
  final RxString fotoProductoUrl = ''.obs;
  final RxBool subiendoImagen = false.obs;

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
          final nombre =
              datos['nombre']?.toString() ??
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
        if (!categoriasNegocio.any(
          (categoria) => categoria['id'] == idCategoriaSeleccionada.value,
        )) {
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
    imagenSeleccionada.value = null;
    fotoProductoUrl.value = '';

    formularioKey.currentState?.reset();
  }

  /// Abre la cámara o la galería (según [origen]) para elegir la foto del
  /// producto. image_picker solicita el permiso nativo necesario por su
  /// cuenta; aquí solo se maneja el resultado y los casos de permiso denegado.
  Future<void> seleccionarImagenProducto(ImageSource origen) async {
    try {
      final XFile? archivo = await _selectorImagen.pickImage(
        source: origen,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (archivo == null) return;
      imagenSeleccionada.value = File(archivo.path);
    } on PlatformException catch (e) {
      final esCamara = origen == ImageSource.camera;
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        Get.snackbar(
          'Permiso requerido',
          esCamara
              ? 'Habilita el permiso de cámara para esta app en los ajustes del dispositivo'
              : 'Habilita el permiso de galería/fotos para esta app en los ajustes del dispositivo',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'No se pudo obtener la imagen: ${e.message}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo obtener la imagen: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Quita la foto local pendiente y/o la ya guardada, dejando el producto
  /// sin imagen. El guardado la eliminará de Storage si corresponde.
  void quitarFotoProducto() {
    imagenSeleccionada.value = null;
    fotoProductoUrl.value = '';
  }

  Future<String> _subirImagenProducto(File archivo, String uid) async {
    final extension = archivo.path.contains('.')
        ? archivo.path.split('.').last
        : 'jpg';
    final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final referencia = FirebaseStorage.instance.ref().child(
      'productos/$uid/$nombreArchivo',
    );
    await referencia.putFile(
      archivo,
      SettableMetadata(contentType: 'image/$extension'),
    );
    return referencia.getDownloadURL();
  }

  /// Valida el formulario y guarda el nuevo producto en Firestore.
  Future<void> guardarProducto({String? productoId}) async {
    if (!formularioKey.currentState!.validate()) return;
    if (idNegocioSeleccionado.value.isEmpty) {
      Get.snackbar('Datos inválidos', 'Selecciona un negocio antes de guardar');
      return;
    }
    if (idCategoriaSeleccionada.value.isEmpty) {
      Get.snackbar(
        'Datos inválidos',
        'Selecciona una categoría antes de guardar',
      );
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

    // Asegurarse de tener un código de producto. Si está vacío, generar uno incremental.
    if (controladorCodigoProducto.text.trim().isEmpty) {
      try {
        await asignarCodigoProductoIncremental();
      } catch (_) {
        // en caso de fallo, continuar y dejar el campo vacío (la validación puede manejarlo si es obligatorio)
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final urlAnterior = fotoProductoUrl.value;

    estaGuardando.value = true;
    try {
      String urlFoto = fotoProductoUrl.value;
      if (imagenSeleccionada.value != null) {
        subiendoImagen.value = true;
        try {
          urlFoto = await _subirImagenProducto(imagenSeleccionada.value!, uid);
        } finally {
          subiendoImagen.value = false;
        }
      }

      final nuevoProducto = ProductosModel(
        nombreProducto: controladorNombre.text.trim(),
        descripcion: controladorDescripcion.text.trim(),
        idCategoria: idCategoriaSeleccionada.value,
        idNegocio: idNegocioSeleccionado.value,
        usuarioId: uid,
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
        fotoProducto: urlFoto,
        codigoProducto: controladorCodigoProducto.text.trim(),
        fechaCreacion: DateTime.now(),
      );

      if (productoId == null) {
        await _referenciaProductos.add(nuevoProducto.aMapa());
      } else {
        await _referenciaProductos.doc(productoId).update({
          ...nuevoProducto.aMapa(),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
      }

      // Si se reemplazó o se quitó una foto anterior, se borra de Storage.
      // No es crítico para el guardado, así que un fallo aquí no interrumpe el flujo.
      if (urlAnterior.isNotEmpty && urlAnterior != urlFoto) {
        try {
          await FirebaseStorage.instance.refFromURL(urlAnterior).delete();
        } catch (_) {}
      }

      limpiarFormulario();
      Get.snackbar(
        productoId == null ? 'Producto agregado' : 'Producto actualizado',
        productoId == null
            ? 'El producto se guardó correctamente'
            : 'El producto se actualizó correctamente',
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

  /// Busca el código de producto más alto del usuario y asigna el siguiente
  /// valor de 5 dígitos en `controladorCodigoProducto`.
  Future<void> asignarCodigoProductoIncremental() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) throw Exception('Usuario no autenticado');

    final snapshot = await _referenciaProductos
        .where('usuarioId', isEqualTo: uid)
        .get();

    int maxCodigo = 0;
    for (final doc in snapshot.docs) {
      final datos = doc.data();
      final raw = (datos['codigoProducto'] ?? '').toString();
      // Extraer solo dígitos
      final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final value = int.tryParse(digitsOnly);
      if (value != null && value > maxCodigo) maxCodigo = value;
    }

    final siguiente = (maxCodigo + 1).clamp(0, 99999);
    final codigoFormateado = siguiente.toString().padLeft(5, '0');
    controladorCodigoProducto.text = codigoFormateado;
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

  /// Carga los datos de un producto existente en el formulario para su edición.
  Future<void> cargarProductoEnFormulario(ProductosModel producto) async {
    controladorNombre.text = producto.nombreProducto;
    controladorDescripcion.text = producto.descripcion;
    controladorCodigoBarra.text = producto.codigoBarra ?? '';
    controladorCodigoProducto.text = producto.codigoProducto;
    controladorStockMaximo.text = producto.stockMaximo.toString();
    controladorStockMinimo.text = producto.stockMinimo.toString();
    controladorUnidadMedida.text = producto.unidadMedida;
    controladorStockActual.text = producto.stockActual.toString();
    controladorPrecioCompra.text = producto.precioCompra.toString();
    controladorPrecioVenta.text = producto.precioVenta.toString();
    imagenSeleccionada.value = null;
    fotoProductoUrl.value = producto.fotoProducto;

    idNegocioSeleccionado.value = producto.idNegocio;
    await cargarCategoriasDelNegocio(producto.idNegocio);
    idCategoriaSeleccionada.value = producto.idCategoria;
  }

  Future<void> eliminarProducto(String productoId) async {
    await _referenciaProductos.doc(productoId).update({
      'estado': 0,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  /// Genera un código de barra
  Future<String> generarCodigoBarraEAN13Unico({
    int intentosMaximos = 20,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) throw Exception('Usuario no autenticado');

    int intentos = 0;
    while (intentos < intentosMaximos) {
      final base12 = List.generate(12, (_) => Random().nextInt(10)).join();
      final checksum = _calcularChecksumEAN13(base12);
      final codigo = '$base12$checksum';

      final consulta = await _referenciaProductos
          .where('usuarioId', isEqualTo: uid)
          .where('codigoBarra', isEqualTo: codigo)
          .get();

      if (consulta.docs.isEmpty) {
        return codigo;
      }

      intentos++;
    }

    throw Exception(
      'No se pudo generar un código único tras $intentosMaximos intentos',
    );
  }

  int _calcularChecksumEAN13(String base12) {
    if (base12.length != 12)
      throw ArgumentError('base12 debe tener 12 dígitos');
    final digits = base12.split('').map(int.parse).toList();
    int suma = 0;
    for (var i = 0; i < digits.length; i++) {
      // posiciones 1-based: impares *1, pares *3
      final posicion = i + 1;
      suma += digits[i] * (posicion % 2 == 1 ? 1 : 3);
    }
    final mod = suma % 10;
    return (10 - mod) % 10;
  }

  Future<void> registrarMovimiento({
    required ProductosModel producto,
    required String tipoMovimiento,
    required double cantidad,
    String? bodegaId,
    String? tercero,
    DateTime? fecha,
    String? observaciones,
  }) async {
    if (producto.id == null || producto.id!.isEmpty) {
      throw Exception('El producto no tiene un identificador válido');
    }

    final productoId = producto.id!;
    final docProducto = _referenciaProductos.doc(productoId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshotProducto = await transaction.get(docProducto);
      if (!snapshotProducto.exists) {
        throw Exception('El producto ya no existe');
      }

      final datosProducto = snapshotProducto.data() ?? <String, dynamic>{};
      final stockActual =
          (datosProducto['stockActual'] as num?)?.toDouble() ?? 0;

      if (tipoMovimiento == 'Salida' && cantidad > stockActual) {
        throw Exception(
          'No hay stock suficiente. Stock actual: ${stockActual.toStringAsFixed(2)}',
        );
      }

      final nuevoStock = tipoMovimiento == 'Entrada'
          ? stockActual + cantidad
          : stockActual - cantidad;

      transaction.update(docProducto, {
        'stockActual': nuevoStock,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      final docMovimiento = _referenciaMovimientos.doc();
      transaction.set(docMovimiento, {
        'idProducto': snapshotProducto.id,
        'nombreProducto': datosProducto['nombreProducto'] ?? '',
        'codigoProducto': datosProducto['codigoProducto'] ?? '',
        'idCategoria': datosProducto['idCategoria'] ?? '',
        'idNegocio': datosProducto['idNegocio'] ?? '',
        'usuarioId':
            datosProducto['usuarioId'] ??
            FirebaseAuth.instance.currentUser?.uid ??
            '',
        'tipoMovimiento': tipoMovimiento,
        'cantidad': cantidad,
        'stockAnterior': stockActual,
        'stockNuevo': nuevoStock,
        'estado': 1,
        'bodegaId': bodegaId ?? '',
        'tercero': tercero ?? '',
        'observaciones': observaciones ?? '',
        'fecha': fecha != null ? Timestamp.fromDate(fecha) : FieldValue.serverTimestamp(),
        'fechaMovimiento': FieldValue.serverTimestamp(),
      });
    });
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
