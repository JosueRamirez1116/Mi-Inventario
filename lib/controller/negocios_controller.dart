import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/model/negocio_model.dart';

class NegociosController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<NegocioModel> negocios = <NegocioModel>[].obs;

  final RxString textoBusqueda = ''.obs;
  final RxBool cargando = true.obs;
  final RxString mensajeError = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcion;

  CollectionReference<Map<String, dynamic>> get _coleccionNegocios {
    return _firestore.collection('negocios');
  }

  @override
  void onInit() {
    super.onInit();
    escucharNegocios();
  }

  void escucharNegocios() {
    cargando.value = true;
    mensajeError.value = '';

    _suscripcion?.cancel();

    _suscripcion = _coleccionNegocios.snapshots().listen(
      (snapshot) {
        final lista = snapshot.docs.map((documento) {
          return NegocioModel.fromMap(documento.id, documento.data());
        }).toList();

        lista.sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );

        negocios.assignAll(lista);
        cargando.value = false;
        mensajeError.value = '';
      },
      onError: (Object error, StackTrace stackTrace) {
        cargando.value = false;
        mensajeError.value = 'No se pudieron cargar los negocios';

        debugPrint('Error al cargar negocios: $error');

        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  List<NegocioModel> get negociosFiltrados {
    final busqueda = textoBusqueda.value.toLowerCase().trim();

    return negocios.where((negocio) {
      final estaActivo = negocio.estado == 1;

      final coincideBusqueda =
          busqueda.isEmpty ||
          negocio.nombre.toLowerCase().contains(busqueda) ||
          negocio.direccion.toLowerCase().contains(busqueda) ||
          negocio.telefono.toLowerCase().contains(busqueda) ||
          negocio.correo.toLowerCase().contains(busqueda);

      return estaActivo && coincideBusqueda;
    }).toList();
  }

  void buscarNegocio(String texto) {
    textoBusqueda.value = texto;
  }

  Future<void> agregarNegocio(NegocioModel negocio) async {
    final datos = <String, dynamic>{
      ...negocio.toMap(),
      'estado': 1,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };

    await _coleccionNegocios.add(datos);
  }

  Future<void> actualizarNegocio(
    String id,
    NegocioModel negocioActualizado,
  ) async {
    final datos = <String, dynamic>{
      ...negocioActualizado.toMap(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };

    await _coleccionNegocios.doc(id).update(datos);
  }

  Future<void> eliminarNegocio(String id) async {
    await _coleccionNegocios.doc(id).update({
      'estado': 0,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  @override
  void onClose() {
    _suscripcion?.cancel();
    super.onClose();
  }
}
