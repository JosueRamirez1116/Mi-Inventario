import 'package:flutter/material.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/controller/dashboard_controller.dart';
import 'package:mi_inventario/model/dashboard_model.dart';
import 'package:mi_inventario/view/productos/agregar_productos_screen.dart';

class CategoriaScreen extends StatelessWidget {
  const CategoriaScreen({
    super.key,
    required this.negocioId,
  });

  final String negocioId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: const Center(
        child: Text('Pantalla de categorías'),
      ),
    );
  }
}

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

  List<DashboardModel> opciones = [];

  @override
  void initState() {
    super.initState();
    opciones = _controller.opciones;
  }

 void abrirOpcion(DashboardModel opcion) {
  final uid = widget.authService.usuarioActual?.uid ?? 'default';

  switch (opcion.titulo) {
    case 'Productos':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AgregarProductosScreen(),
        ),
      );
      break;
    case 'Categorias':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoriaScreen(
            negocioId: uid,
          ),
        ),
      );
      break;

    default:
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 244, 250),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 83, 170),
        foregroundColor: Colors.white,
        title: const Text(
          'Inicio - Mi Inventario',
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
        child: GridView.builder(
          itemCount: opciones.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final opcion = opciones[index];

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
    );
  }
}