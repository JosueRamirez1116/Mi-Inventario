import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mi_inventario/firebase_options.dart';
import 'package:mi_inventario/view/negocios/negocios_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const NegociosApp());
  } catch (error) {
    runApp(ErrorFirebaseApp(mensaje: error.toString()));
  }
}

class NegociosApp extends StatelessWidget {
  const NegociosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gestión de negocios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 28, 83, 170),
        ),
      ),
      home: const NegociosScreen(),
    );
  }
}

class ErrorFirebaseApp extends StatelessWidget {
  const ErrorFirebaseApp({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 70, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo iniciar Firebase',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(mensaje, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
