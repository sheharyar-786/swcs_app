import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler (Must be a top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // Flutter engine initialization ensure karta hai
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase ko app start hone se pehle initialize karna lazmi hai
  await Firebase.initializeApp();

  // Initialize Notifications
  await NotificationService.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const SmartWasteApp());
}

// --- Session & Role Gate ---
class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        if (snapshot.hasData) {
          return _RoleFetcher(user: snapshot.data!);
        }

        return const AuthPage();
      },
    );
  }
}

class _RoleFetcher extends StatelessWidget {
  final User user;
  const _RoleFetcher({required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('users/${user.uid}').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final role = snapshot.data!.child('role').value.toString();
          if (role == 'admin') return const AdminMainShell();
          if (role == 'manager') return const AdminPage();
          if (role == 'driver') return const DriverDashboard();
          return const CivillianPage();
        }

        // Fallback for drivers in verified_drivers node
        return FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance
              .ref('verified_drivers/${user.uid}')
              .get(),
          builder: (context, driverSnap) {
            if (driverSnap.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }
            if (driverSnap.hasData && driverSnap.data!.exists) {
              return const DriverDashboard();
            }
            // If role not found, logout or show login
            return const AuthPage();
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A714E), Color(0xFF1B5E20)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                "Initializing Mission Hub...",
                style: TextStyle(color: Colors.white70, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 25,
                ),
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
          home: const SessionGate(),
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
