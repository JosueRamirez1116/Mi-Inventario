import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/productos_controller.dart';
import 'package:mi_inventario/model/productos_model.dart';
import 'package:mi_inventario/view/productos/agregar_productos_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  late final ProductosController _controller;

  final TextEditingController _busquedaController = TextEditingController();

  // Los controladores del formulario de movimientos pertenecen a la pantalla:
  // showModalBottomSheet completa su Future al llamar a pop(), antes de que
  // termine la animación de cierre, así que liberarlos ahí dejaría a los campos
  // del sheet usando controladores ya desechados durante esa animación.
  final TextEditingController _cantidadMovimientoController =
      TextEditingController();

  final TextEditingController _observacionesMovimientoController =
      TextEditingController();

  String _textoBusqueda = '';
  String _filtroCategoriaId = '';
  String _filtroNegocioId = '';

  String? get _uidActual => FirebaseAuth.instance.currentUser?.uid;

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
    _cantidadMovimientoController.dispose();
    _observacionesMovimientoController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _streamProductos {
    final uid = _uidActual;

    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('productos')
        .where('usuarioId', isEqualTo: uid)
        .where('estado', isEqualTo: 1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _streamCategorias {
    final uid = _uidActual;

    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('categorias')
        .where('usuarioId', isEqualTo: uid)
        .where('estado', isEqualTo: 1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _streamNegocios {
    final uid = _uidActual;

    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('negocios')
        .where('usuarioId', isEqualTo: uid)
        .where('estado', isEqualTo: 1)
        .snapshots();
  }

  Future<void> _abrirFormularioRegistro() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AgregarProductosScreen()),
    );
  }

  Future<void> _escanearYBuscar() async {
    try {
      final codigo = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _InventarioScannerPage()),
      );

      if (codigo != null && codigo.isNotEmpty) {
        setState(() {
          _textoBusqueda = codigo;
          _busquedaController.text = codigo;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al escanear: $e')));
    }
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
    final colores = Theme.of(context).colorScheme;

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
              style: FilledButton.styleFrom(
                backgroundColor: colores.error,
                foregroundColor: colores.onError,
              ),
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
        SnackBar(
          content: Text(
            'Producto eliminado correctamente',
            style: TextStyle(color: colores.onError),
          ),
          backgroundColor: colores.error,
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

  Future<void> _abrirFormularioMovimiento(
    ProductosModel producto,
    String tipo,
  ) async {
    final esEntrada = tipo == 'Entrada';

    final coloresPantalla = Theme.of(context).colorScheme;

    final colorAccion = esEntrada
        ? coloresPantalla.tertiary
        : coloresPantalla.error;

    final colorTextoAccion = esEntrada
        ? coloresPantalla.onTertiary
        : coloresPantalla.onError;

    _cantidadMovimientoController.clear();
    _observacionesMovimientoController.clear();

    DateTime fecha = DateTime.now();
    bool guardando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colores = Theme.of(context).colorScheme;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colores.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border(top: BorderSide(color: colores.outline)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colores.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        esEntrada ? 'Registrar Entrada' : 'Registrar Salida',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorAccion,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        producto.nombreProducto,
                        style: TextStyle(color: colores.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cantidadMovimientoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final seleccionada = await showDatePicker(
                            context: context,
                            initialDate: fecha,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (seleccionada != null) {
                            setSheetState(() => fecha = seleccionada);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            '${fecha.day.toString().padLeft(2, '0')}/'
                            '${fecha.month.toString().padLeft(2, '0')}/'
                            '${fecha.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _observacionesMovimientoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: guardando
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colores.error,
                                side: BorderSide(color: colores.error),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: guardando
                                  ? null
                                  : () async {
                                      final cantidad = double.tryParse(
                                        _cantidadMovimientoController.text
                                            .trim(),
                                      );

                                      if (cantidad == null || cantidad <= 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ingresa una cantidad numérica mayor a 0',
                                            ),
                                          ),
                                        );

                                        return;
                                      }

                                      setSheetState(() => guardando = true);

                                      try {
                                        await _controller.registrarMovimiento(
                                          producto: producto,
                                          tipoMovimiento: tipo,
                                          cantidad: cantidad,
                                          fecha: fecha,
                                          observaciones:
                                              _observacionesMovimientoController
                                                  .text
                                                  .trim(),
                                        );

                                        if (!sheetContext.mounted) {
                                          return;
                                        }

                                        Navigator.of(sheetContext).pop();

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              esEntrada
                                                  ? 'Entrada registrada'
                                                  : 'Salida registrada',
                                              style: TextStyle(
                                                color: colores.onTertiary,
                                              ),
                                            ),
                                            backgroundColor: colores.tertiary,
                                          ),
                                        );
                                      } catch (error) {
                                        setSheetState(() => guardando = false);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'No se pudo guardar: $error',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: colorAccion,
                                foregroundColor: colorTextoAccion,
                              ),
                              child: guardando
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorTextoAccion,
                                      ),
                                    )
                                  : const Text('Registrar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDetalleProducto(
    ProductosModel producto,
    Map<String, String> categoriasPorId,
    Map<String, String> negociosPorId,
  ) async {
    final nombreCategoria =
        categoriasPorId[producto.idCategoria] ?? 'Sin categoría';

    final nombreNegocio = negociosPorId[producto.idNegocio] ?? 'Sin negocio';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final colores = Theme.of(context).colorScheme;

            return Container(
              decoration: BoxDecoration(
                color: colores.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: colores.outline)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colores.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colores.outline),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildFotoProducto(producto.fotoProducto),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            producto.nombreProducto,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colores.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _info('Código', producto.codigoProducto),
                          _info('Categoría', nombreCategoria),
                          _info('Negocio', nombreNegocio),
                          _info(
                            'Stock actual',
                            producto.stockActual.toStringAsFixed(2),
                          ),
                          _info('Unidad', producto.unidadMedida),
                          _info(
                            'Precio compra',
                            producto.precioCompra.toStringAsFixed(2),
                          ),
                          _info(
                            'Precio venta',
                            producto.precioVenta.toStringAsFixed(2),
                          ),
                          _info('Descripción', producto.descripcion),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: colores.primary,
                              foregroundColor: colores.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();

                              _abrirFormularioEdicion(producto);
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Modificar'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                },
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Cerrar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: colores.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();

                                  _confirmarEliminacion(producto);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: const Text('Eliminar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: colores.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _info(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
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
    final colores = Theme.of(context).colorScheme;

    if (fotoUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: colores.surfaceContainerHighest,
        child: Icon(Icons.image_not_supported, color: colores.onSurfaceVariant),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: colores.surfaceContainerHighest,
      backgroundImage: NetworkImage(fotoUrl),
      onBackgroundImageError: (_, __) {},
      child: fotoUrl.isEmpty
          ? Icon(Icons.broken_image, color: colores.onSurfaceVariant)
          : null,
    );
  }

  List<ProductosModel> _aplicarFiltros({
    required List<ProductosModel> productos,
    required Map<String, String> categoriasPorId,
  }) {
    final busqueda = _textoBusqueda.trim().toLowerCase();

    return productos.where((producto) {
      if (_filtroCategoriaId.isNotEmpty &&
          producto.idCategoria != _filtroCategoriaId) {
        return false;
      }

      if (_filtroNegocioId.isNotEmpty &&
          producto.idNegocio != _filtroNegocioId) {
        return false;
      }

      if (busqueda.isEmpty) {
        return true;
      }

      final categoriaNombre = (categoriasPorId[producto.idCategoria] ?? '')
          .toLowerCase();

      final coincideCodigo = producto.codigoProducto.toLowerCase().contains(
        busqueda,
      );

      final coincideCodigoBarra = (producto.codigoBarra ?? '')
          .toLowerCase()
          .contains(busqueda);

      final coincideNombre = producto.nombreProducto.toLowerCase().contains(
        busqueda,
      );

      final coincideCategoria = categoriaNombre.contains(busqueda);

      return coincideCodigo ||
          coincideCodigoBarra ||
          coincideNombre ||
          coincideCategoria;
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
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
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

              final categoriasVisibles = _filtroNegocioId.isEmpty
                  ? categoriasDocs
                  : categoriasDocs.where((doc) {
                      final negocioIdCategoria = (doc.data()['negocioId'] ?? '')
                          .toString();

                      return negocioIdCategoria == _filtroNegocioId;
                    }).toList();

              if (_filtroCategoriaId.isNotEmpty &&
                  !categoriasVisibles.any(
                    (doc) => doc.id == _filtroCategoriaId,
                  )) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }

                  setState(() => _filtroCategoriaId = '');
                });
              }

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

                  final productos =
                      productosSnapshot.data!.docs.map((doc) {
                        return ProductosModel.desdeMapa(doc.data(), doc.id);
                      }).toList()..sort(
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
                                labelText:
                                    'Buscar por código, nombre, categoría o código de barra',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _textoBusqueda.isEmpty
                                    ? IconButton(
                                        onPressed: _escanearYBuscar,
                                        icon: Icon(
                                          Icons.qr_code_scanner,
                                          color: colores.primary,
                                        ),
                                        tooltip: 'Escanear código',
                                      )
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
                                    key: ValueKey('neg-$_filtroNegocioId'),
                                    initialValue: _filtroNegocioId.isEmpty
                                        ? null
                                        : _filtroNegocioId,
                                    decoration: const InputDecoration(
                                      labelText: 'Filtrar negocio',
                                      prefixIcon: Icon(
                                        Icons.storefront_outlined,
                                      ),
                                    ),
                                    isExpanded: true,
                                    items: negociosDocs.map((doc) {
                                      final nombre =
                                          (doc.data()['nombre'] ?? '')
                                              .toString();

                                      return DropdownMenuItem<String>(
                                        value: doc.id,
                                        child: Text(
                                          nombre.isEmpty
                                              ? 'Sin nombre'
                                              : nombre,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _filtroNegocioId = value ?? '';
                                        _filtroCategoriaId = '';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('cat-$_filtroCategoriaId'),
                                    initialValue: _filtroCategoriaId.isEmpty
                                        ? null
                                        : _filtroCategoriaId,
                                    decoration: const InputDecoration(
                                      labelText: 'Filtrar categoría',
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    isExpanded: true,
                                    items: categoriasVisibles.map((doc) {
                                      final nombre =
                                          (doc.data()['nombre'] ?? '')
                                              .toString();

                                      return DropdownMenuItem<String>(
                                        value: doc.id,
                                        child: Text(
                                          nombre.isEmpty
                                              ? 'Sin nombre'
                                              : nombre,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(
                                        () => _filtroCategoriaId = value ?? '',
                                      );
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
                                label: const Text('Eliminar filtros'),
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
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  4,
                                  12,
                                  12,
                                ),
                                itemCount: productosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final producto = productosFiltrados[index];

                                  final nombreCategoria =
                                      categoriasPorId[producto.idCategoria] ??
                                      'Sin categoría';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onDoubleTap: () =>
                                          _mostrarDetalleProducto(
                                            producto,
                                            categoriasPorId,
                                            negociosPorId,
                                          ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            _buildFotoProducto(
                                              producto.fotoProducto,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    producto.nombreProducto,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Stock: ${producto.stockActual}',
                                                  ),
                                                  Text(
                                                    'Categoría: $nombreCategoria',
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _AccionProducto(
                                              icono: Icons.edit_outlined,
                                              color: colores.primary,
                                              etiqueta: 'Modificar',
                                              relleno: false,
                                              onTap: () =>
                                                  _abrirFormularioEdicion(
                                                    producto,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            _AccionProducto(
                                              icono: Icons.add,
                                              color: colores.tertiary,
                                              colorContenido:
                                                  colores.onTertiary,
                                              etiqueta: 'Ingreso',
                                              relleno: true,
                                              onTap: () =>
                                                  _abrirFormularioMovimiento(
                                                    producto,
                                                    'Entrada',
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            _AccionProducto(
                                              icono: Icons.remove,
                                              color: colores.error,
                                              colorContenido: colores.onError,
                                              etiqueta: 'Salida',
                                              relleno: true,
                                              onTap: () =>
                                                  _abrirFormularioMovimiento(
                                                    producto,
                                                    'Salida',
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
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AccionProducto extends StatelessWidget {
  const _AccionProducto({
    required this.icono,
    required this.color,
    required this.etiqueta,
    required this.onTap,
    this.relleno = true,
    this.colorContenido,
  });

  final IconData icono;
  final Color color;
  final String etiqueta;
  final bool relleno;
  final Color? colorContenido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: relleno ? color : Colors.transparent,
              border: relleno ? null : Border.all(color: color, width: 1.4),
            ),
            child: Icon(
              icono,
              size: 18,
              color: relleno ? (colorContenido ?? color) : color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(etiqueta, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _InventarioScannerPage extends StatefulWidget {
  const _InventarioScannerPage();

  @override
  State<_InventarioScannerPage> createState() => _InventarioScannerPageState();
}

class _InventarioScannerPageState extends State<_InventarioScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController();

  bool _detected = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código')),
      body: MobileScanner(
        controller: _cameraController,
        onDetect: (capture) {
          if (_detected) return;

          if (capture.barcodes.isEmpty) {
            return;
          }

          final barcode = capture.barcodes.first;

          final String? code = barcode.rawValue ?? barcode.displayValue;

          if (code == null || code.isEmpty) {
            return;
          }

          _detected = true;

          Navigator.of(context).pop(code);
        },
      ),
    );
  }
}
