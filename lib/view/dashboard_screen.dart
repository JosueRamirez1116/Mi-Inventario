
import 'package:flutter/material.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/categoria/categoria_screen.dart';
import 'package:mi_inventario/controller/dashboard_controller.dart';
import 'package:mi_inventario/model/dashboard_model.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();
  final TextEditingController _buscarController = TextEditingController();

  List<DashboardModel> opcionesFiltradas = [];

  @override
  void initState() {
    super.initState();
    opcionesFiltradas = _controller.opciones;
  }

  void buscarOpcion(String texto) {
    setState(() {
      if (texto.isEmpty) {
        opcionesFiltradas = _controller.opciones;
      } else {
        opcionesFiltradas = _controller.opciones.where((opcion) {
          return opcion.titulo
              .toLowerCase()
              .contains(texto.toLowerCase());
        }).toList();
      }
    });
  }

  void abrirOpcion(DashboardModel opcion) {
    final uid = widget.authService.usuarioActual?.uid ?? 'default';

    if (opcion.titulo == 'Categorías') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoriaScreen(
            negocioId: uid,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La pantalla de ${opcion.titulo} estará disponible próximamente',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 244, 250),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 83, 170),
        foregroundColor: Colors.white,
        title: const Text(
          'Inicio - Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: widget.authService.cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _buscarController,
              onChanged: buscarOpcion,
              decoration: InputDecoration(
                hintText: 'Buscar opción...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 22),

            Expanded(
              child: GridView.builder(
                itemCount: opcionesFiltradas.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final opcion = opcionesFiltradas[index];

                  return Card(
                    elevation: 5,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        abrirOpcion(opcion);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              opcion.icono,
                              size: 50,
                              color: const Color.fromARGB(
                                255,
                                30,
                                112,
                                198,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              opcion.titulo,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
