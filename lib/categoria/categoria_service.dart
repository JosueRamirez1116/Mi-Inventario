import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/categoria_model.dart';

class CategoriaService {
  final CollectionReference _categoriasRef =
      FirebaseFirestore.instance.collection('categorias');

  // ---------- AGREGAR ----------
  Future<void> agregarCategoria(CategoriaModel categoria) async {
    await _categoriasRef.add(categoria.toMap());
  }

  // ---------- MODIFICAR ----------
  Future<void> modificarCategoria(CategoriaModel categoria) async {
    if (categoria.id == null) return;
    await _categoriasRef.doc(categoria.id).update(categoria.toMap());
  }

  // ---------- ELIMINAR (borrado lógico, estado = 0) ----------
  Future<void> eliminarCategoria(String id) async {
    await _categoriasRef.doc(id).update({'estado': 0});
  }

  // ---------- LISTAR (solo activas, filtradas por negocio) ----------
  Stream<List<CategoriaModel>> obtenerCategorias(String negocioId) {
    return _categoriasRef
        .where('negocioId', isEqualTo: negocioId)
        .where('estado', isEqualTo: 1)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoriaModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ---------- BUSCAR POR NOMBRE ----------
  // Firestore no soporta "contains" nativo, así que traemos las activas
  // del negocio y filtramos localmente (suficiente para un catálogo de categorías,
  // que normalmente no tiene miles de registros).
  Future<List<CategoriaModel>> buscarPorNombre(
      String negocioId, String texto) async {
    final snapshot = await _categoriasRef
        .where('negocioId', isEqualTo: negocioId)
        .where('estado', isEqualTo: 1)
        .get();

    final categorias = snapshot.docs
        .map((doc) =>
            CategoriaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    if (texto.isEmpty) return categorias;

    return categorias
        .where((c) => c.nombre.toLowerCase().contains(texto.toLowerCase()))
        .toList();
  }
}