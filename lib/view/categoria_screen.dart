import 'package:flutter/material.dart';
import 'package:mi_inventario/model/categoria_model.dart';
import 'package:mi_inventario/view/categoria_service.dart';

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

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _mostrarFormulario([CategoriaModel? categoria]) async {
    final esEdicion = categoria != null;
    final nombreController = TextEditingController(text: categoria?.nombre ?? '');
    final descripcionController = TextEditingController(text: categoria?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: !guardando,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialogo) {
            return AlertDialog(
              title: Text(esEdicion ? 'Editar categoria' : 'Nueva categoria'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                  onPressed: guardando ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setStateDialogo(() => guardando = true);

                          final modelo = CategoriaModel(
                            id: categoria?.id,
                            nombre: nombreController.text.trim(),
                            descripcion: descripcionController.text.trim(),
                            negocioId: widget.negocioId,
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
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar categoria'),
          content: Text('¿Deseas eliminar "${categoria.nombre}"?'),
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
      final resultados = await _service.buscarPorNombre(widget.negocioId, texto.trim());
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
    final streamCategorias = _service.obtenerCategorias(widget.negocioId);

    return Scaffold(
      appBar: AppBar(
        title: _modoBusqueda
            ? TextField(
                controller: _busquedaController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar categoria...',
                  border: InputBorder.none,
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
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar categorias',
                            style: Theme.of(context).textTheme.titleMedium,
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
                          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay categorias',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el boton + para crear una',
                            style: Theme.of(context).textTheme.bodyMedium,
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
    return Dismissible(
      key: Key(categoria.id ?? categoria.nombre),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
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
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.category, color: Colors.white),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(categoria.descripcion.isEmpty ? 'Sin descripcion' : categoria.descripcion),
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
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
