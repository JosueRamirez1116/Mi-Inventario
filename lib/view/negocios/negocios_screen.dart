import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/controller/negocios_controller.dart';
import 'package:mi_inventario/model/negocio_model.dart';
import 'package:mi_inventario/view/negocios/negocio_form_screen.dart';

class NegociosScreen extends StatefulWidget {
  const NegociosScreen({super.key});

  @override
  State<NegociosScreen> createState() {
    return _NegociosScreenState();
  }
}

class _NegociosScreenState extends State<NegociosScreen> {
  static const Color _colorPrincipal = Color.fromARGB(255, 28, 83, 170);

  late final NegociosController controller;

  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<NegociosController>()) {
      controller = Get.find<NegociosController>();
    } else {
      controller = Get.put(NegociosController());
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _abrirFormularioRegistro() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NegocioFormScreen(controller: controller),
      ),
    );

    if (!mounted || resultado != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Negocio registrado correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _abrirFormularioEdicion(NegocioModel negocio) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NegocioFormScreen(controller: controller, negocio: negocio),
      ),
    );

    if (!mounted || resultado != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Negocio actualizado correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _confirmarEliminacion(NegocioModel negocio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar negocio'),
          content: Text(
            '¿Desea eliminar el negocio '
            '"${negocio.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) {
      return;
    }

    try {
      await controller.eliminarNegocio(negocio.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Negocio eliminado correctamente'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el negocio: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limpiarBusqueda() {
    _busquedaController.clear();
    controller.buscarNegocio('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 244, 250),
      appBar: AppBar(
        title: const Text('Gestión de negocios'),
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _abrirFormularioRegistro,
            icon: const Icon(Icons.add),
            tooltip: 'Agregar negocio',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              onChanged: controller.buscarNegocio,
              decoration: InputDecoration(
                labelText: 'Buscar negocio',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _limpiarBusqueda,
                  icon: const Icon(Icons.close),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.cargando.value && controller.negocios.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.mensajeError.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.mensajeError.value,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: controller.escucharNegocios,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final negocios = controller.negociosFiltrados;

              if (negocios.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 70, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No hay negocios para mostrar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 80),
                itemCount: negocios.length,
                itemBuilder: (context, index) {
                  final negocio = negocios[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.store,
                                color: _colorPrincipal,
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  negocio.nombre,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 25),
                          _crearInformacion(
                            Icons.location_on,
                            'Dirección',
                            negocio.direccion,
                          ),
                          const SizedBox(height: 12),
                          _crearInformacion(
                            Icons.phone,
                            'Teléfono',
                            negocio.telefono,
                          ),
                          const SizedBox(height: 12),
                          _crearInformacion(
                            Icons.email,
                            'Correo',
                            negocio.correo,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _abrirFormularioEdicion(negocio);
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _colorPrincipal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _confirmarEliminacion(negocio);
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Eliminar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormularioRegistro,
        backgroundColor: _colorPrincipal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _crearInformacion(IconData icono, String titulo, String contenido) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: _colorPrincipal),
        const SizedBox(width: 8),
        Expanded(child: Text('$titulo: $contenido')),
      ],
    );
  }
}
