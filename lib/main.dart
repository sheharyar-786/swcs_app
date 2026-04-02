import 'package:flutter/material.dart';
// --- NEW: Firebase Core Import ---
import 'package:firebase_core/firebase_core.dart';

// Import paths based on your lib folder structure
import 'auth/login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/analytics_screen.dart';
import 'admin/schedule_list_screen.dart';
import 'admin/add_schedule_screen.dart';
import 'admin/driver_approval_screen.dart';
import 'driver/driver_dashboard.dart';
import 'civillian/civillian_dashboard.dart';

// --- UPDATED: Main function with Firebase Initialization ---
void main() async {
  // Flutter engine initialization ensure karta hai
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase ko app start hone se pehle initialize karna lazmi hai
  await Firebase.initializeApp();

  runApp(const SmartWasteApp());
}

class SmartWasteApp extends StatelessWidget {
  const SmartWasteApp({super.key});

  // --- Unified Eco-Friendly Palette ---
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color warningYellow = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWCS - Smart Waste Collection',
      debugShowCheckedModeBanner: false,

      // Global Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: leafGreen,
        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSeed(
          seedColor: leafGreen,
          primary: leafGreen,
          secondary: deepForest,
          surface: Colors.white,
          background: softMint,
        ),

        // Cartoon Style Card Theme
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Modern Rounded Corners
            side: BorderSide(color: leafGreen.withOpacity(0.1)),
          ),
        ),

        // Primary Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: leafGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          ),
        ),

        // Global AppBar Style
        appBarTheme: const AppBarTheme(
          backgroundColor: leafGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      // Route Navigation
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AuthPage(),
        '/adminDashboard': (context) => const AdminPage(),
        '/driverDashboard': (context) => const DriverDashboard(),
        '/civilianDashboard': (context) => const CivillianPage(),
        '/analytics': (context) => const AnalyticsPage(),
        '/scheduleList': (context) => const ScheduleManagementPage(),
        '/addSchedule': (context) => const AddScheduleScreen(),
        '/driverApproval': (context) => const DriverApprovalScreen(),
      },
    );
  }
}
