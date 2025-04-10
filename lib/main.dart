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

class MedDexApp extends StatefulWidget {
  const MedDexApp({super.key});

  @override
  State<MedDexApp> createState() => _MedDexAppState();
}

class _MedDexAppState extends State<MedDexApp> with WidgetsBindingObserver {
  late AuthController _authController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authController = Provider.of<AuthController>(context, listen: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app is paused (inactive or in background), log out to require PIN on resume
    if (state == AppLifecycleState.paused) {
      _authController.logout();
    }
  }

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
          seedColor: const Color(0xFF5C6BC0), // Indigo
          brightness: Brightness.light,
          primary: const Color(0xFF5C6BC0), // Indigo
          secondary: const Color(0xFF7986CB), // Indigo 300
          tertiary: const Color(0xFF9FA8DA), // Indigo 200
          surface: Colors.white,
          background: const Color(0xFFF5F5F5),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white.withOpacity(0.8),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF5C6BC0), // Indigo
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF5C6BC0), // Indigo
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5C6BC0)), // Indigo
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7986CB), // Indigo 300
          brightness: Brightness.dark,
          primary: const Color(0xFF7986CB), // Indigo 300
          secondary: const Color(0xFF9FA8DA), // Indigo 200
          tertiary: const Color(0xFF3949AB), // Indigo 700
          surface: const Color(0xFF121212),
          background: const Color(0xFF1E1E1E),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF2D2D2D).withOpacity(0.8),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF9FA8DA), // Indigo 200
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF7986CB), // Indigo 300
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF9FA8DA)), // Indigo 200
          ),
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
