import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/model/negocio_model.dart';

class NegociosController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<NegocioModel> negocios = <NegocioModel>[].obs;

  final RxString textoBusqueda = ''.obs;
  final RxBool cargando = true.obs;
  final RxString mensajeError = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcion;

  StreamSubscription<User?>? _suscripcionAuth;

  String? _uidEnEscucha;

  CollectionReference<Map<String, dynamic>> get _coleccionNegocios {
    return _firestore.collection('negocios');
  }

  @override
  void onInit() {
    super.onInit();

    _uidEnEscucha = _auth.currentUser?.uid;

    escucharNegocios();

    _suscripcionAuth = _auth.authStateChanges().listen((usuario) {
      final nuevoUid = usuario?.uid;

      if (nuevoUid != _uidEnEscucha) {
        _uidEnEscucha = nuevoUid;

        escucharNegocios();
      }
    });
  }

  void escucharNegocios() {
    cargando.value = true;
    mensajeError.value = '';

    _suscripcion?.cancel();

    negocios.clear();

    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      cargando.value = false;
      mensajeError.value = 'No hay un usuario autenticado';
      return;
    }

    _uidEnEscucha = uid;

    _suscripcion = _coleccionNegocios
        .where('usuarioId', isEqualTo: uid)
        .snapshots()
        .listen(
          (snapshot) {
            final lista = snapshot.docs.map((documento) {
              return NegocioModel.fromMap(documento.id, documento.data());
            }).toList();

            lista.sort(
              (a, b) =>
                  a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
            );

            negocios.assignAll(lista);

            cargando.value = false;
            mensajeError.value = '';
          },
          onError: (Object error, StackTrace stackTrace) {
            cargando.value = false;

            mensajeError.value = 'No se pudieron cargar los negocios';

            negocios.clear();

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
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No hay un usuario autenticado.',
      );
    }

    final datos = <String, dynamic>{
      ...negocio.toMap(),
      'usuarioId': uid,
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
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No hay un usuario autenticado.',
      );
    }

    final referencia = _coleccionNegocios.doc(id);

    final documento = await referencia.get();

    if (!documento.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'El negocio no existe.',
      );
    }

    final datosActuales = documento.data();

    final propietario =
        (datosActuales?['usuarioId'] ?? datosActuales?['uid'] ?? '').toString();

    if (propietario != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'No tienes permiso para modificar este negocio.',
      );
    }

    final datos = <String, dynamic>{
      ...negocioActualizado.toMap(),
      'usuarioId': uid,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };

    await referencia.update(datos);
  }

  Future<void> eliminarNegocio(String id) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw FirebaseAuthException(
        code: 'missing-uid',
        message: 'No hay un usuario autenticado.',
      );
    }

    final referencia = _coleccionNegocios.doc(id);

    final documento = await referencia.get();

    if (!documento.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'El negocio no existe.',
      );
    }

    final datos = documento.data();

    final propietario = (datos?['usuarioId'] ?? datos?['uid'] ?? '').toString();

    if (propietario != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'No tienes permiso para eliminar este negocio.',
      );
    }

    await referencia.update({
      'estado': 0,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  @override
  void onClose() {
    _suscripcion?.cancel();
    _suscripcionAuth?.cancel();

    super.onClose();
  }
}
