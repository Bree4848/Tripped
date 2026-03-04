import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Start the redirection logic as soon as the gatekeeper loads
    _checkRoleAndNavigate();
  }

  Future<void> _checkRoleAndNavigate() async {
    try {
      final user = _supabase.auth.currentUser;

      // 1. If no session exists, send back to Login
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // 2. Fetch the role from the 'profiles' table in Supabase
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      // Normalize the string (lowercase and trim to prevent typos)
      final String role = (data['role'] ?? 'resident')
          .toString()
          .toLowerCase()
          .trim();

      if (!mounted) return;

      // 3. --- THE REDIRECT FIX ---
      // Instead of if/else branching to different dashboards,
      // we send EVERYONE to the Portal Home Newsfeed.
      // We pass the 'role' as an argument so PortalHome knows what buttons to show.
      Navigator.pushReplacementNamed(
        context,
        '/portal_home',
        arguments: {'role': role},
      );
    } catch (e) {
      debugPrint("Gatekeeper Error: $e");
      // If there's an error (like a network issue or missing profile), fallback to login
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Branded Loading Screen while the app decides where to send the user
    const themeDarkBlue = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(themeDarkBlue),
            ),
            const SizedBox(height: 24),
            // Placeholder for your app logo
            const Icon(Icons.bolt_rounded, size: 80, color: themeDarkBlue),
            const SizedBox(height: 16),
            const Text(
              "Verifying Credentials...",
              style: TextStyle(
                color: Colors.grey,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
