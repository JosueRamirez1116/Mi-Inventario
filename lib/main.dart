import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/controller/productos_controller.dart';
import 'package:mi_inventario/login/login_screen.dart';
import 'package:mi_inventario/categoria/categoria_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Permite arrancar la app incluso si Firebase aun no esta configurado.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  Get.put(ProductosController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mi Inventario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen(authService: _auth);
        }
        return LoginScreen();
        //return const AgregarProductosScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final email = authService.usuarioActual?.email ?? 'Usuario';
    final uid = authService.usuarioActual?.uid ?? 'default';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Inventario'),
        actions: [
          IconButton(
            onPressed: authService.cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 72),
              const SizedBox(height: 16),
              Text(
                'Sesion iniciada: $email',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoriaScreen(negocioId: uid),
                    ),
                  );
                },
                icon: const Icon(Icons.category),
                label: const Text('Gestionar categorias'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoriaScreen extends StatelessWidget {
  const CategoriaScreen({super.key, required this.negocioId});

  final String negocioId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: Center(
        child: Text(
          'Negocio ID: $negocioId',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
