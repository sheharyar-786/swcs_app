import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// --- Firebase Core Import ---
import 'package:firebase_core/firebase_core.dart';

// Import paths based on your finalized folder structure
import 'auth/login_screen.dart'; // Ensure this matches your AuthPage file name
import 'manager/manager_dashboard.dart';
import 'manager/analytics_screen.dart';
import 'manager/schedule_list_screen.dart';
import 'manager/add_schedule_screen.dart';
import 'manager/driver_approval_screen.dart';
import 'driver/driver_dashboard.dart';
import 'civillian/civillian_dashboard.dart';

// --- Admin Imports ---
import 'admin/dashboard/admin_main_shell.dart';

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
  static const Color leafGreen = Color(0xFF0A714E);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF8FAF9);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
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
          brightness: Brightness.light,
        ),

        // Premium Card Theme
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: leafGreen.withValues(alpha: 0.1)),
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

      // --- Route Navigation ---
      initialRoute: '/login',
      routes: {
        // 1. Auth Route
        '/login': (context) => const AuthPage(),

        // 2. Admin Route (Only Shell needed)
        // Shary, humne sub-routes (/adminApprovals etc.) yahan se hata diye hain
        // kyunke AdminMainShell unhe internaly handle kar raha hai.
        '/adminDashboard': (context) => const AdminMainShell(),

        // 3. Driver & Civilian Routes
        '/driverDashboard': (context) => const DriverDashboard(),
        '/civilianDashboard': (context) => const CivillianPage(),

        // 4. Manager Routes
        '/managerDashboard': (context) =>
            const AdminPage(), // Added for completeness
        '/analytics': (context) => const AnalyticsPage(),
        '/scheduleList': (context) => const ScheduleManagementPage(),
        '/addSchedule': (context) => const AddScheduleScreen(),
        '/driverApproval': (context) => const DriverApprovalScreen(),
      },
    );
      },
    );
  }
}
