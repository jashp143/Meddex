import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'screens/home_screen.dart';
import 'screens/add_patient_screen.dart';
import 'screens/patient_detail_screen.dart';
import 'screens/add_visit_screen.dart';
import 'screens/search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/edit_patient_screen.dart';
import 'screens/patient_list_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/theme_controller.dart';
import 'utils/patient_controller.dart';
import 'utils/auth_controller.dart';
import 'utils/database_helper.dart';
import 'utils/storage_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage and request permissions
  final storageHelper = StorageHelper();
  await storageHelper.requestPermissions();

  // Initialize FFI for desktop/test platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database - get the instance to trigger initialization
  await DatabaseHelper().database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => PatientController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: const MedDexApp(),
    ),
  );
}

class MedDexApp extends StatelessWidget {
  const MedDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Get theme mode from ThemeController
    final themeController = Provider.of<ThemeController>(context);
    final authController = Provider.of<AuthController>(context);

    return MaterialApp(
      title: 'MedDex',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeController.themeMode,
      home: authController.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/patient/add': (context) => const AddPatientScreen(),
        '/patient/edit': (context) => const EditPatientScreen(),
        '/patient/detail': (context) => const PatientDetailScreen(),
        '/patients': (context) => const PatientListScreen(),
        '/visit/add': (context) => const AddVisitScreen(),
        '/search': (context) => const SearchScreen(),
        '/login': (context) => const LoginScreen(),
        '/appointments': (context) => const AppointmentsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
