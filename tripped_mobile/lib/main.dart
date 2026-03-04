import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Screens - Ensure these paths match your project structure
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/portal_home.dart';
import 'screens/admin_dashboard.dart';
import 'screens/technician_dashboard.dart';
import 'screens/report_fault_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/staff_overview.dart';
import 'screens/resident_history_screen.dart';
import 'screens/update_password_screen.dart';

// 1. Global Navigator Key for background redirection
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Could not load .env file: $e");
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 2. LISTEN FOR PASSWORD RECOVERY EVENTS
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // Handle recovery link click: navigate to Update Password screen
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/update_password',
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tripped',
      navigatorKey: navigatorKey, // Register the key here
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A237E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: Colors.yellow[700]!,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        '/update_password': (context) => const UpdatePasswordScreen(),

        // FIXED: Removed the 'role' argument logic.
        // PortalHome now fetches its own role via FutureBuilder to prevent "hiding" the admin link.
        '/portal_home': (context) => const PortalHome(),

        '/dashboard_screen': (context) => const DashboardScreen(),

        '/admin_dashboard': (context) => const AdminDashboard(),
        '/technician_dashboard': (context) => const TechnicianDashboard(),

        '/report_fault': (context) => const ReportFaultScreen(),
        '/resident_history': (context) => const ResidentHistoryScreen(),

        '/user_management': (context) => const UserManagementScreen(),
        '/staff_overview': (context) => const StaffOverviewScreen(),
      },
    );
  }
}
