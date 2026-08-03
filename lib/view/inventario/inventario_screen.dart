import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

List<Map<String, dynamic>> filtrarProductosPorNombre(
  List<Map<String, dynamic>> productos,
  String texto,
) {
  if (texto.trim().isEmpty) {
    return productos;
  }

  final busqueda = texto.toLowerCase().trim();
  return productos.where((producto) {
    final nombre = (producto['nombreProducto'] ?? '').toString().toLowerCase();
    return nombre.contains(busqueda);
  }).toList();
}

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  final Color _appBarColor = const Color(0xFF4338CA);

  List<Map<String, String>> _negociosUsuario = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _productosFiltrados = [];
  String? _negocioSeleccionadoId;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNegociosDelUsuario();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarNegociosDelUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        setState(() => _cargando = false);
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('negocios')
          .where('usuarioId', isEqualTo: uid)
          .where('estado', isEqualTo: 1)
          .get();

      final negocios = snapshot.docs.map((doc) {
        final datos = doc.data();
        final nombre =
            datos['nombre']?.toString() ??
            datos['nombreNegocio']?.toString() ??
            'Sin nombre';
        return {'id': doc.id, 'nombre': nombre};
      }).toList();

      if (!mounted) return;

      setState(() {
        _negociosUsuario = negocios
            .map(
              (negocio) => {
                'id': negocio['id'] ?? '',
                'nombre': negocio['nombre'] ?? 'Sin nombre',
              },
            )
            .toList();

        if (_negociosUsuario.isNotEmpty) {
          if (_negocioSeleccionadoId == null ||
              !_negociosUsuario.any(
                (negocio) => negocio['id'] == _negocioSeleccionadoId,
              )) {
            _negocioSeleccionadoId = _negociosUsuario.first['id'];
          }
        } else {
          _negocioSeleccionadoId = null;
        }
      });

      if (_negocioSeleccionadoId != null &&
          _negocioSeleccionadoId!.isNotEmpty) {
        await _cargarProductosDelNegocio(_negocioSeleccionadoId!);
      } else {
        if (mounted) {
          setState(() {
            _productos = [];
            _productosFiltrados = [];
            _cargando = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _cargarProductosDelNegocio(String negocioId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        setState(() {
          _productos = [];
          _productosFiltrados = [];
          _cargando = false;
        });
      }
      return;
    }

    setState(() => _cargando = true);

    try {
      final productosSnapshot = await FirebaseFirestore.instance
          .collection('productos')
          .where('usuarioId', isEqualTo: uid)
          .where('idNegocio', isEqualTo: negocioId)
          .where('estado', isEqualTo: 1)
          .get();

      final categoriasSnapshot = await FirebaseFirestore.instance
          .collection('categorias')
          .where('usuarioId', isEqualTo: uid)
          .where('estado', isEqualTo: 1)
          .get();

      final categoriasPorId = <String, String>{};
      for (final doc in categoriasSnapshot.docs) {
        final datos = doc.data();
        categoriasPorId[doc.id] =
            datos['nombre']?.toString() ?? 'Sin categoría';
      }

      final productos = productosSnapshot.docs.map((doc) {
        final datos = doc.data();
        final categoriaId = datos['idCategoria']?.toString() ?? '';
        return {
          'id': doc.id,
          'nombreProducto': datos['nombreProducto']?.toString() ?? 'Sin nombre',
          'stockActual': (datos['stockActual'] ?? 0).toDouble(),
          'idCategoria': categoriaId,
          'categoriaNombre': categoriasPorId[categoriaId] ?? 'Sin categoría',
          'fotoProducto': datos['fotoProducto']?.toString() ?? '',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _productos = productos;
        _productosFiltrados = filtrarProductosPorNombre(
          productos,
          _busquedaController.text,
        );
        _cargando = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _productos = [];
          _productosFiltrados = [];
          _cargando = false;
        });
      }
    }
  }

  void _aplicarFiltro(String texto) {
    setState(() {
      _productosFiltrados = filtrarProductosPorNombre(_productos, texto);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FA),
      appBar: AppBar(
        title: const Text(
          'Inventario',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: _appBarColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona una tienda',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _negocioSeleccionadoId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _appBarColor, width: 2),
                      ),
                    ),
                    items: _negociosUsuario.map((negocio) {
                      return DropdownMenuItem<String>(
                        value: negocio['id'],
                        child: Text(negocio['nombre'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (valor) async {
                      if (valor == null) return;
                      setState(() => _negocioSeleccionadoId = valor);
                      await _cargarProductosDelNegocio(valor);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _busquedaController,
                    onChanged: _aplicarFiltro,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _appBarColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _negociosUsuario.isEmpty
                  ? _buildEstadoVacio(
                      'Aún no hay tiendas registradas para este usuario.',
                    )
                  : _productosFiltrados.isEmpty
                  ? _buildEstadoVacio(
                      'No se encontraron productos para esta tienda.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _productosFiltrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final producto = _productosFiltrados[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Image.network(
                                      producto['fotoProducto']
                                                  ?.toString()
                                                  .isNotEmpty ==
                                              true
                                          ? producto['fotoProducto'].toString()
                                          : 'https://placehold.co/120x120/png?text=Producto',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: const Color(0xFFEEF2FF),
                                              child: const Icon(
                                                Icons.inventory_2_outlined,
                                                color: Color(0xFF4338CA),
                                                size: 28,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        producto['nombreProducto']
                                                ?.toString() ??
                                            'Sin nombre',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stock actual: ${producto['stockActual']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Categoría: ${producto['categoriaNombre']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVacio(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
