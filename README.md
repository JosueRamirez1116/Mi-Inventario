# 📦 Mi Inventario

Aplicación móvil desarrollada en **Flutter** para la gestión de inventario de un negocio: productos, categorías, stock, movimientos de entrada/salida y reportes exportables. Backend 100% en la nube con **Firebase** (Authentication, Firestore y Storage).

> Proyecto Final — Programación Móvil II

## ✨ Funcionalidades

- **Autenticación**: registro e inicio de sesión con email/contraseña, restablecimiento de contraseña, eliminación de cuenta.
- **Negocios**: alta, edición y eliminación del negocio del usuario (un usuario puede tener uno o varios).
- **Categorías**: organización de productos por categoría dentro de cada negocio.
- **Productos e inventario**: alta/edición con foto, código interno autogenerado y código de barras EAN-13 (generado o escaneado con la cámara), control de stock mínimo/máximo, precios de compra y venta.
- **Movimientos de stock**: registro de entradas y salidas, con historial editable/eliminable y recálculo automático del stock afectado.
- **Reportes**: filtrado por negocio, categoría, producto y rango de fechas, exportables a **PDF** y **Excel**.
- **Configuración**: perfil de usuario, edición del negocio, modo oscuro.

## 🛠️ Stack tecnológico

| Área                      | Tecnología                           |
| -------------------------- | ------------------------------------- |
| Framework                  | Flutter (Dart)                        |
| Manejo de estado / DI      | [GetX](https://pub.dev/packages/get)   |
| Autenticación             | Firebase Authentication               |
| Base de datos              | Cloud Firestore                       |
| Almacenamiento de archivos | Firebase Storage                      |
| Escaneo de códigos        | mobile_scanner                        |
| Selección de imágenes    | image_picker                          |
| Reportes                   | pdf, excel, path_provider, open_filex |

## 🏗️ Arquitectura

El proyecto sigue un patrón **MVC ligero + GetX**:

- **Model** (`lib/model/`): entidades de datos (`NegocioModel`, `ProductosModel`, `CategoriaModel`, `MovimientoModel`, etc.) con serialización hacia/desde Firestore.
- **Controller** (`lib/controller/`): `GetxController`s (Negocios, Productos, Movimientos, Reportes) con el estado reactivo y la lógica de acceso a datos.
- **View** (`lib/view/`, `lib/login/`, `lib/registro/`, `lib/configuracion/`): pantallas que consumen los controllers vía `Obx`/`StreamBuilder`.

> El módulo `lib/Categorias/` es la excepción: usa `StatefulWidget` + `setState` en vez de GetX.

Toda la persistencia es contra Firebase (sin backend propio ni base de datos local). Ver el PDF de documentación para el detalle completo de cada método, el diagrama de flujo de datos y las colecciones de Firestore.

## 📂 Estructura de carpetas

```
lib/
├── main.dart                # Punto de entrada (AuthGate → Login/Dashboard)
├── firebase_options.dart    # Configuración de Firebase (generada por FlutterFire)
├── auth/services/           # AuthService (login, registro, perfil)
├── model/                   # Modelos de datos (Negocio, Producto, Movimiento, ...)
├── controller/               # Controllers GetX (Negocios, Productos, Movimientos, Reportes)
├── Categorias/               # Módulo de categorías (modelo, servicio y pantalla)
├── login/, registro/         # Pantallas de autenticación y onboarding
├── configuracion/             # Perfil de usuario, edición de negocio, ajustes
├── theme/                     # Tema visual claro/oscuro (Material 3)
└── view/                      # Pantallas principales: dashboard, productos, inventario,
                                #   negocios, movimientos, reportes
```

## 🚀 Instalación y ejecución

1. Instalar [Flutter SDK](https://flutter.dev) (versión `^3.12.0` o superior).
2. Instalar las dependencias:
   ```bash
   flutter pub get
   ```
3. Configurar Firebase para el proyecto (ya incluido en `lib/firebase_options.dart` / `google-services.json`). Si necesitas apuntar a tu propio proyecto de Firebase, vuelve a generarlo con:
   ```bash
   flutterfire configure
   ```
4. Ejecutar la app:
   ```bash
   flutter run
   ```

## 🧪 Tests

```bash
flutter test
```

Incluye pruebas de modelos (`negocio_model_test.dart`, `productos_model_test.dart`) y de la pantalla de inventario.


*Proyecto desarrollado como trabajo final del curso de Programación Móvil II.*
