import 'package:flutter/material.dart';
import 'package:mi_inventario/Categorias/categoria_model.dart';
import 'package:mi_inventario/Categorias/categoria_service.dart';

class CategoriaScreen extends StatefulWidget {
  final String negocioId;

  const CategoriaScreen({super.key, required this.negocioId});

  @override
  State<CategoriaScreen> createState() => _CategoriaScreenState();
}

class _CategoriaScreenState extends State<CategoriaScreen> {
  final CategoriaService _service = CategoriaService();
  final TextEditingController _busquedaController = TextEditingController();

  List<CategoriaModel> _categoriasFiltradas = [];
  bool _modoBusqueda = false;

  List<Map<String, String>> _negociosUsuario = [];
  String? _negocioSeleccionadoId;

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
    try {
      final negocios = await _service.obtenerNegociosDelUsuario();

      if (!mounted) return;

      setState(() {
        _negociosUsuario = negocios;

        if (negocios.isNotEmpty) {
          final tieneSeleccionValida =
              _negocioSeleccionadoId != null &&
              negocios.any(
                (negocio) => negocio['id'] == _negocioSeleccionadoId,
              );

          if (!tieneSeleccionValida) {
            _negocioSeleccionadoId = negocios.first['id'];
          }
        } else {
          _negocioSeleccionadoId = null;
        }
      });
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _mostrarFormulario([CategoriaModel? categoria]) async {
    if (_negociosUsuario.isEmpty) {
      await _cargarNegociosDelUsuario();
    }

    if (!mounted) return;

    if (_negociosUsuario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero crea al menos un negocio para asignarle la categoría.',
          ),
        ),
      );
      return;
    }

    final esEdicion = categoria != null;

    final nombreController = TextEditingController(
      text: categoria?.nombre ?? '',
    );

    final descripcionController = TextEditingController(
      text: categoria?.descripcion ?? '',
    );

    final formKey = GlobalKey<FormState>();

    bool guardando = false;

    String? negocioSeleccionado = categoria?.negocioId.isNotEmpty == true
        ? categoria!.negocioId
        : _negocioSeleccionadoId;

    if (negocioSeleccionado == null ||
        !_negociosUsuario.any(
          (negocio) => negocio['id'] == negocioSeleccionado,
        )) {
      negocioSeleccionado = _negociosUsuario.first['id'];
    }

    await showDialog(
      context: context,
      barrierDismissible: !guardando,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialogo) {
            final colores = Theme.of(dialogContext).colorScheme;

            return AlertDialog(
              title: Text(esEdicion ? 'Editar categoria' : 'Nueva categoria'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: negocioSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Negocio',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        items: _negociosUsuario.map((negocio) {
                          return DropdownMenuItem<String>(
                            value: negocio['id'],
                            child: Text(negocio['nombre'] ?? 'Sin nombre'),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          setStateDialogo(() => negocioSeleccionado = valor);
                        },
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return 'Selecciona un negocio';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: nombreController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Ingresa un nombre';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: descripcionController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Ingresa una descripcion';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          if (negocioSeleccionado == null ||
                              negocioSeleccionado!.isEmpty) {
                            return;
                          }

                          setStateDialogo(() => guardando = true);

                          final negocioSeleccionadoDatos = _negociosUsuario
                              .firstWhere(
                                (negocio) =>
                                    negocio['id'] == negocioSeleccionado,
                                orElse: () => {'id': '', 'nombre': ''},
                              );

                          final modelo = CategoriaModel(
                            id: categoria?.id,
                            nombre: nombreController.text.trim(),
                            descripcion: descripcionController.text.trim(),
                            negocioId: negocioSeleccionado!,
                            negocioNombre:
                                negocioSeleccionadoDatos['nombre'] ?? '',
                            usuarioId: categoria?.usuarioId ?? '',
                          );

                          try {
                            if (esEdicion) {
                              await _service.modificarCategoria(modelo);
                            } else {
                              await _service.agregarCategoria(modelo);
                            }

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            setStateDialogo(() => guardando = false);

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    esEdicion
                                        ? 'No se pudo actualizar la categoria'
                                        : 'No se pudo crear la categoria',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: guardando
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colores.onPrimary,
                          ),
                        )
                      : Text(esEdicion ? 'Guardar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarEliminacion(CategoriaModel categoria) async {
    final colores = Theme.of(context).colorScheme;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar categoria'),
          content: Text('¿Deseas eliminar "${categoria.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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

    if (confirmar != true) return;

    try {
      await _service.eliminarCategoria(categoria.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${categoria.nombre}" eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la categoria')),
        );
      }
    }
  }

  Future<void> _buscar(String texto) async {
    setState(() => _modoBusqueda = true);

    if (texto.trim().isEmpty) {
      setState(() => _categoriasFiltradas = []);
      return;
    }

    try {
      final resultados = await _service.buscarPorNombre(
        widget.negocioId,
        texto.trim(),
      );

      if (mounted) {
        setState(() => _categoriasFiltradas = resultados);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _categoriasFiltradas = []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    final streamCategorias = _service.obtenerCategorias(widget.negocioId);

    final colorTextoAppBar =
        tema.appBarTheme.foregroundColor ?? colores.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: _modoBusqueda
            ? TextField(
                controller: _busquedaController,
                autofocus: true,
                style: TextStyle(color: colorTextoAppBar),
                cursorColor: colorTextoAppBar,
                decoration: InputDecoration(
                  hintText: 'Buscar categoria...',
                  hintStyle: TextStyle(
                    color: colorTextoAppBar.withValues(alpha: 0.7),
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _buscar,
              )
            : const Text('Categorias'),
        actions: [
          IconButton(
            icon: Icon(_modoBusqueda ? Icons.close : Icons.search),
            tooltip: _modoBusqueda ? 'Cerrar busqueda' : 'Buscar',
            onPressed: () {
              if (_modoBusqueda) {
                setState(() {
                  _modoBusqueda = false;
                  _busquedaController.clear();
                  _categoriasFiltradas = [];
                });
              } else {
                setState(() => _modoBusqueda = true);
              }
            },
          ),
        ],
      ),
      body: _modoBusqueda
          ? ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _categoriasFiltradas.length,
              itemBuilder: (context, index) {
                final categoria = _categoriasFiltradas[index];

                return _buildItemCategoria(categoria);
              },
            )
          : StreamBuilder<List<CategoriaModel>>(
              stream: streamCategorias,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colores.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar categorias',
                            style: tema.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final categorias = snapshot.data ?? [];

                if (categorias.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 64,
                            color: colores.onSurfaceVariant.withValues(
                              alpha: 0.65,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay categorias',
                            style: tema.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el boton + para crear una',
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: colores.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = categorias[index];

                    return _buildItemCategoria(categoria);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoria'),
      ),
    );
  }

  Widget _buildItemCategoria(CategoriaModel categoria) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return Dismissible(
      key: Key(categoria.id ?? categoria.nombre),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colores.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: colores.onError),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Eliminar categoria'),
              content: Text('¿Deseas eliminar "${categoria.nombre}"?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
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
      },
      onDismissed: (direction) async {
        try {
          await _service.eliminarCategoria(categoria.id!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${categoria.nombre}" eliminada')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo eliminar la categoria')),
            );
          }
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colores.primaryContainer,
          child: Icon(Icons.category, color: colores.primary),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoria.descripcion.isEmpty
                  ? 'Sin descripcion'
                  : categoria.descripcion,
            ),
            if (categoria.negocioNombre.isNotEmpty)
              Text(
                'Negocio: ${categoria.negocioNombre}',
                style: TextStyle(color: colores.onSurfaceVariant),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (valor) async {
            if (valor == 'editar') {
              _mostrarFormulario(categoria);
            } else if (valor == 'eliminar') {
              _confirmarEliminacion(categoria);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: colores.error),
                  const SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: colores.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
