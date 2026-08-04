import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/productos_controller.dart';
import 'package:mi_inventario/model/productos_model.dart';
import 'package:mi_inventario/view/productos/agregar_productos_screen.dart';

/// Filtra una lista de productos (representados como mapas) por coincidencia
/// parcial en el nombre. Se mantiene aquí para compatibilidad con pruebas
/// existentes que validan esta lógica de forma aislada.
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
  static const Color _colorPrincipal = Color.fromARGB(255, 28, 83, 170);

  late final ProductosController _controller;
  final TextEditingController _busquedaController = TextEditingController();

  String _textoBusqueda = '';
  String _filtroCategoriaId = '';
  String _filtroNegocioId = '';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ProductosController>()) {
      _controller = Get.find<ProductosController>();
    } else {
      _controller = Get.put(ProductosController());
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _streamProductos {
    return FirebaseFirestore.instance
        .collection('productos')
        .where('estado', isEqualTo: 1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _streamCategorias {
    return FirebaseFirestore.instance
        .collection('categorias')
        .where('estado', isEqualTo: 1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _streamNegocios {
    return FirebaseFirestore.instance
        .collection('negocios')
        .where('estado', isEqualTo: 1)
        .snapshots();
  }

  Future<void> _abrirFormularioRegistro() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AgregarProductosScreen()),
    );
  }

  Future<void> _abrirFormularioEdicion(ProductosModel producto) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AgregarProductosScreen(producto: producto),
      ),
    );
  }

  Future<void> _confirmarEliminacion(ProductosModel producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text('¿Deseas eliminar "${producto.nombreProducto}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _controller.eliminarProducto(producto.id!);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado correctamente'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el producto: $error')),
      );
    }
  }

  Future<void> _mostrarDialogoMovimiento(ProductosModel producto) async {
    String tipoMovimiento = 'Entrada';
    final cantidadController = TextEditingController();
    bool guardando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar movimiento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey('mov-$tipoMovimiento'),
                    initialValue: tipoMovimiento,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'Entrada', child: Text('Entrada')),
                      DropdownMenuItem(value: 'Salida', child: Text('Salida')),
                    ],
                    onChanged: guardando
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() => tipoMovimiento = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cantidadController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      hintText: 'Ingresa una cantidad mayor a 0',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: guardando
                      ? null
                      : () async {
                          final cantidad = double.tryParse(
                            cantidadController.text.trim(),
                          );
                          if (cantidad == null || cantidad <= 0) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingresa una cantidad numérica mayor a 0',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => guardando = true);
                          try {
                            await _controller.registrarMovimiento(
                              producto: producto,
                              tipoMovimiento: tipoMovimiento,
                              cantidad: cantidad,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Movimiento $tipoMovimiento registrado',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (error) {
                            setDialogState(() => guardando = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('No se pudo guardar: $error')),
                            );
                          }
                        },
                  icon: const Icon(Icons.save),
                  label: guardando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    cantidadController.dispose();
  }

  Future<void> _mostrarDetalleProducto(
    ProductosModel producto,
    Map<String, String> categoriasPorId,
    Map<String, String> negociosPorId,
  ) async {
    final nombreCategoria = categoriasPorId[producto.idCategoria] ?? 'Sin categoría';
    final nombreNegocio = negociosPorId[producto.idNegocio] ?? 'Sin negocio';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(producto.nombreProducto),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _info('Código', producto.codigoProducto),
                _info('Categoría', nombreCategoria),
                _info('Negocio', nombreNegocio),
                _info('Stock actual', producto.stockActual.toStringAsFixed(2)),
                _info('Unidad', producto.unidadMedida),
                _info('Precio compra', producto.precioCompra.toStringAsFixed(2)),
                _info('Precio venta', producto.precioVenta.toStringAsFixed(2)),
                _info('Descripción', producto.descripcion),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _abrirFormularioEdicion(producto);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Modificar'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _mostrarDialogoMovimiento(producto);
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Entrada / Salida'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmarEliminacion(producto);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Widget _info(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$etiqueta: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoProducto(String fotoUrl) {
    if (fotoUrl.trim().isEmpty) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: Color(0xFFE2E8F0),
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE2E8F0),
      backgroundImage: NetworkImage(fotoUrl),
      onBackgroundImageError: (_, __) {},
      child: fotoUrl.isEmpty
          ? const Icon(Icons.broken_image, color: Colors.grey)
          : null,
    );
  }

  List<ProductosModel> _aplicarFiltros({
    required List<ProductosModel> productos,
    required Map<String, String> categoriasPorId,
  }) {
    final busqueda = _textoBusqueda.trim().toLowerCase();

    return productos.where((producto) {
      if (_filtroCategoriaId.isNotEmpty && producto.idCategoria != _filtroCategoriaId) {
        return false;
      }

      if (_filtroNegocioId.isNotEmpty && producto.idNegocio != _filtroNegocioId) {
        return false;
      }

      if (busqueda.isEmpty) {
        return true;
      }

      final categoriaNombre =
          (categoriasPorId[producto.idCategoria] ?? '').toLowerCase();

      final coincideCodigo = producto.codigoProducto.toLowerCase().contains(busqueda);
      final coincideNombre = producto.nombreProducto.toLowerCase().contains(busqueda);
      final coincideCategoria = categoriaNombre.contains(busqueda);

      return coincideCodigo || coincideNombre || coincideCategoria;
    }).toList();
  }

  void _limpiarFiltros() {
    setState(() {
      _textoBusqueda = '';
      _filtroCategoriaId = '';
      _filtroNegocioId = '';
      _busquedaController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 244, 250),
      appBar: AppBar(
        title: const Text('Consulta del Inventario'),
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Agregar producto',
            onPressed: _abrirFormularioRegistro,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _streamCategorias,
        builder: (context, categoriasSnapshot) {
          if (categoriasSnapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las categorías'),
            );
          }

          final categoriasDocs = categoriasSnapshot.data?.docs ?? [];
          final categoriasPorId = <String, String>{
            for (final categoria in categoriasDocs)
              categoria.id: (categoria.data()['nombre'] ?? '').toString(),
          };

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _streamNegocios,
            builder: (context, negociosSnapshot) {
              if (negociosSnapshot.hasError) {
                return const Center(
                  child: Text('No se pudieron cargar los negocios'),
                );
              }

              final negociosDocs = negociosSnapshot.data?.docs ?? [];
              final negociosPorId = <String, String>{
                for (final negocio in negociosDocs)
                  negocio.id: (negocio.data()['nombre'] ?? '').toString(),
              };

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _streamProductos,
                builder: (context, productosSnapshot) {
                  if (productosSnapshot.hasError) {
                    return const Center(
                      child: Text('No se pudieron cargar los productos'),
                    );
                  }

                  if (!productosSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final productos = productosSnapshot.data!.docs.map((doc) {
                    return ProductosModel.desdeMapa(doc.data(), doc.id);
                  }).toList()
                    ..sort(
                      (a, b) => a.nombreProducto.toLowerCase().compareTo(
                        b.nombreProducto.toLowerCase(),
                      ),
                    );

                  final productosFiltrados = _aplicarFiltros(
                    productos: productos,
                    categoriasPorId: categoriasPorId,
                  );

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          children: [
                            TextField(
                              controller: _busquedaController,
                              onChanged: (valor) {
                                setState(() => _textoBusqueda = valor);
                              },
                              decoration: InputDecoration(
                                labelText: 'Buscar por código, nombre o categoría',
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                suffixIcon: _textoBusqueda.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _textoBusqueda = '';
                                            _busquedaController.clear();
                                          });
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('cat-$_filtroCategoriaId'),
                                    initialValue: _filtroCategoriaId.isEmpty
                                        ? null
                                        : _filtroCategoriaId,
                                    decoration: const InputDecoration(
                                      labelText: 'Filtrar categoría',
                                      border: OutlineInputBorder(),
                                    ),
                                    isExpanded: true,
                                    items: categoriasDocs.map((doc) {
                                      final nombre =
                                          (doc.data()['nombre'] ?? '').toString();
                                      return DropdownMenuItem(
                                        value: doc.id,
                                        child: Text(
                                          nombre.isEmpty ? 'Sin nombre' : nombre,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _filtroCategoriaId = value ?? '');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('neg-$_filtroNegocioId'),
                                    initialValue: _filtroNegocioId.isEmpty
                                        ? null
                                        : _filtroNegocioId,
                                    decoration: const InputDecoration(
                                      labelText: 'Filtrar negocio',
                                      border: OutlineInputBorder(),
                                    ),
                                    isExpanded: true,
                                    items: negociosDocs.map((doc) {
                                      final nombre =
                                          (doc.data()['nombre'] ?? '').toString();
                                      return DropdownMenuItem(
                                        value: doc.id,
                                        child: Text(
                                          nombre.isEmpty ? 'Sin nombre' : nombre,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _filtroNegocioId = value ?? '');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: _limpiarFiltros,
                                icon: const Icon(Icons.filter_alt_off),
                                label: const Text('Eliminar todos los filtros'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: productosFiltrados.isEmpty
                            ? const Center(
                                child: Text('No hay productos para mostrar'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                                itemCount: productosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final producto = productosFiltrados[index];
                                  final nombreCategoria =
                                      categoriasPorId[producto.idCategoria] ??
                                      'Sin categoría';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: InkWell(
                                      onDoubleTap: () => _mostrarDetalleProducto(
                                        producto,
                                        categoriasPorId,
                                        negociosPorId,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            _buildFotoProducto(producto.fotoProducto),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    producto.nombreProducto,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('Stock: ${producto.stockActual}'),
                                                  Text('Categoría: $nombreCategoria'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormularioRegistro,
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
