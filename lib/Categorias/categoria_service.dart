import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'categoria_model.dart';

class CategoriaService {
  final CollectionReference _categoriasRef = FirebaseFirestore.instance
      .collection('categorias');

  String? _uidActual() => FirebaseAuth.instance.currentUser?.uid;

  Future<List<Map<String, String>>> obtenerNegociosDelUsuario() async {
    final uid = _uidActual();
    if (uid == null || uid.isEmpty) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('negocios')
        .where('usuarioId', isEqualTo: uid)
        .where('estado', isEqualTo: 1)
        .get();

    return snapshot.docs.map((doc) {
      final datos = doc.data();
      final nombre =
          datos['nombre']?.toString() ??
          datos['nombreNegocio']?.toString() ??
          'Sin nombre';

      return {'id': doc.id, 'nombre': nombre};
    }).toList();
  }

  // ---------- AGREGAR ----------
  Future<void> agregarCategoria(CategoriaModel categoria) async {
    final uid = _uidActual();
    final datos = categoria.toMap();
    datos['negocioId'] = categoria.negocioId;
    datos['negocioNombre'] = categoria.negocioNombre;
    datos['usuarioId'] = uid ?? '';
    await _categoriasRef.add(datos);
  }

  // ---------- MODIFICAR ----------
  Future<void> modificarCategoria(CategoriaModel categoria) async {
    if (categoria.id == null) return;
    final uid = _uidActual();
    final datos = categoria.toMap();
    datos['negocioId'] = categoria.negocioId;
    datos['negocioNombre'] = categoria.negocioNombre;
    datos['usuarioId'] = uid ?? categoria.usuarioId;
    await _categoriasRef.doc(categoria.id).update(datos);
  }

  // ---------- ELIMINAR (borrado lógico, estado = 0) ----------
  Future<void> eliminarCategoria(String id) async {
    await _categoriasRef.doc(id).update({'estado': 0});
  }

  // ---------- LISTAR (solo activas, filtradas por usuario) ----------
  Stream<List<CategoriaModel>> obtenerCategorias(String negocioId) {
    final uid = _uidActual();
    if (uid == null || uid.isEmpty) {
      return Stream.value(const []);
    }

    return _categoriasRef
        .where('usuarioId', isEqualTo: uid)
        .where('estado', isEqualTo: 1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CategoriaModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ---------- BUSCAR POR NOMBRE ----------
  Future<List<CategoriaModel>> buscarPorNombre(
    String negocioId,
    String texto,
  ) async {
    final uid = _uidActual();
    if (uid == null || uid.isEmpty) return [];

    final snapshot = await _categoriasRef
        .where('usuarioId', isEqualTo: uid)
        .where('estado', isEqualTo: 1)
        .get();

    final categorias = snapshot.docs
        .map(
          (doc) => CategoriaModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();

    if (texto.isEmpty) return categorias;

    return categorias
        .where((c) => c.nombre.toLowerCase().contains(texto.toLowerCase()))
        .toList();
  }
}
