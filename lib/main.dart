import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/auth/services/auth_service.dart';
import 'package:mi_inventario/login/login_screen.dart';
import 'package:mi_inventario/view/dashboard_screen.dart';
import 'package:mi_inventario/configuracion/perfil_usuario_screen.dart';
import 'package:mi_inventario/Categorias/categoria_screen.dart'
    as categorias_screen;
import 'package:mi_inventario/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mi Inventario',
      debugShowCheckedModeBanner: false,

      // Modo claro: Índigo Corporativo
      theme: AppTheme.claro,

      // Modo oscuro: Nocturno Boutique
      darkTheme: AppTheme.oscuro,

      // La aplicación inicia en modo claro.
      // ConfiguracionScreen cambia el tema usando Get.changeThemeMode().
      themeMode: ThemeMode.light,

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
          return DashboardScreen(authService: _auth);
        }

        return LoginScreen();
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PerfilUsuarioScreen()),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
          ),
          IconButton(
            onPressed: authService.cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
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
                'Sesión iniciada: $email',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          categorias_screen.CategoriaScreen(negocioId: uid),
                    ),
                  );
                },
                icon: const Icon(Icons.category),
                label: const Text('Gestionar categorías'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
