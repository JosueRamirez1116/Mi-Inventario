import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/model/movimiento_model.dart';

class MovimientosController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _movimientosRef {
    return _firestore.collection('movimientos');
  }

  CollectionReference<Map<String, dynamic>> get _productosRef {
    return _firestore.collection('productos');
  }

  String? get _uidActual => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<MovimientoModel>> obtenerMovimientosActivos() {
    final uid = _uidActual;
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    return _movimientosRef
        .where('usuarioId', isEqualTo: uid)
        .where('estado', isEqualTo: 1)
        .snapshots()
        .map((snapshot) {
          final movimientos = snapshot.docs
              .map((doc) => MovimientoModel.fromMap(doc.id, doc.data()))
              .toList();

          movimientos.sort(
            (a, b) => b.fechaMovimiento.compareTo(a.fechaMovimiento),
          );

          return movimientos;
        });
  }

  Future<void> editarMovimiento({
    required MovimientoModel movimiento,
    required String nuevoTipoMovimiento,
    required double nuevaCantidad,
  }) async {
    final uid = _uidActual;
    if (uid == null || uid.isEmpty) {
      throw Exception('No hay un usuario autenticado');
    }

    if (nuevaCantidad <= 0) {
      throw Exception('La cantidad debe ser mayor a cero');
    }

    final movimientoDoc = _movimientosRef.doc(movimiento.id);
    final productoDoc = _productosRef.doc(movimiento.idProducto);

    await _firestore.runTransaction((transaction) async {
      final movimientoSnapshot = await transaction.get(movimientoDoc);
      if (!movimientoSnapshot.exists) {
        throw Exception('El movimiento ya no existe');
      }
      final datosMovimiento = movimientoSnapshot.data() ?? <String, dynamic>{};
      final usuarioMovimiento = (datosMovimiento['usuarioId'] ?? '').toString();
      if (usuarioMovimiento.isNotEmpty && usuarioMovimiento != uid) {
        throw Exception('No tienes permisos para editar este movimiento');
      }

      final productoSnapshot = await transaction.get(productoDoc);
      if (!productoSnapshot.exists) {
        throw Exception('No se encontró el producto asociado al movimiento');
      }

      final datosProducto = productoSnapshot.data() ?? <String, dynamic>{};
      final stockActual = (datosProducto['stockActual'] as num?)?.toDouble() ?? 0;

      final deltaAnterior = movimiento.tipoMovimiento == 'Entrada'
          ? movimiento.cantidad
          : -movimiento.cantidad;
      final deltaNuevo = nuevoTipoMovimiento == 'Entrada'
          ? nuevaCantidad
          : -nuevaCantidad;

      final stockSinMovimientoAnterior = stockActual - deltaAnterior;
      final stockActualizado = stockSinMovimientoAnterior + deltaNuevo;

      if (stockActualizado < 0) {
        throw Exception(
          'No hay stock suficiente para actualizar este movimiento.',
        );
      }

      transaction.update(productoDoc, {
        'stockActual': stockActualizado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      transaction.update(movimientoDoc, {
        'tipoMovimiento': nuevoTipoMovimiento,
        'cantidad': nuevaCantidad,
        'stockAnterior': stockSinMovimientoAnterior,
        'stockNuevo': stockActualizado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> eliminarMovimiento(MovimientoModel movimiento) async {
    final uid = _uidActual;
    if (uid == null || uid.isEmpty) {
      throw Exception('No hay un usuario autenticado');
    }

    final movimientoDoc = _movimientosRef.doc(movimiento.id);
    final productoDoc = _productosRef.doc(movimiento.idProducto);

    await _firestore.runTransaction((transaction) async {
      final movimientoSnapshot = await transaction.get(movimientoDoc);
      if (!movimientoSnapshot.exists) {
        throw Exception('El movimiento ya no existe');
      }
      final datosMovimiento = movimientoSnapshot.data() ?? <String, dynamic>{};
      final usuarioMovimiento = (datosMovimiento['usuarioId'] ?? '').toString();
      if (usuarioMovimiento.isNotEmpty && usuarioMovimiento != uid) {
        throw Exception('No tienes permisos para eliminar este movimiento');
      }

      final productoSnapshot = await transaction.get(productoDoc);
      if (!productoSnapshot.exists) {
        throw Exception('No se encontró el producto asociado al movimiento');
      }

      final datosProducto = productoSnapshot.data() ?? <String, dynamic>{};
      final stockActual = (datosProducto['stockActual'] as num?)?.toDouble() ?? 0;

      final deltaMovimiento = movimiento.tipoMovimiento == 'Entrada'
          ? movimiento.cantidad
          : -movimiento.cantidad;
      final stockActualizado = stockActual - deltaMovimiento;

      if (stockActualizado < 0) {
        throw Exception(
          'No se puede eliminar este movimiento porque dejaría el stock en negativo.',
        );
      }

      transaction.update(productoDoc, {
        'stockActual': stockActualizado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      transaction.update(movimientoDoc, {
        'estado': 0,
        'fechaEliminacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    });
  }
}
