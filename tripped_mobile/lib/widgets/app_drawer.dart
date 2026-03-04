import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/admin_dashboard.dart'; // Ensure this path matches your project structure

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Helper to fetch the user role from Supabase profiles table
  Future<String> _getUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'user';

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      // Normalize the string to prevent hidden spaces or capitalization issues
      return (data['role'] ?? 'user').toString().toLowerCase().trim();
    } catch (e) {
      debugPrint("Error fetching role: $e");
      return 'user';
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Drawer(
      child: FutureBuilder<String>(
        future: _getUserRole(),
        builder: (context, snapshot) {
          // If the data is still loading, we show a 'user' default or a loader
          final role = snapshot.data ?? 'user';

          return Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.indigo[900]),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.indigo),
                ),
                accountName: Text(
                  "ROLE: ${role.toUpperCase()}",
                  style: const TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(supabase.auth.currentUser?.email ?? ""),
              ),

              // --- COMMON ITEMS (Visible to everyone) ---
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Home Dashboard"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    '/dashboard_gatekeeper',
                  );
                },
              ),

              // --- ADMIN ONLY ITEMS ---
              if (role == 'admin') ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    "ADMIN MANAGEMENT",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // This is the link that takes you BACK to the Admin Dashboard
                ListTile(
                  leading: const Icon(
                    Icons.dashboard_customize,
                    color: Colors.orangeAccent,
                  ),
                  title: const Text(
                    "Admin Control Center",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboard(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.manage_accounts,
                    color: Colors.indigo,
                  ),
                  title: const Text("User Permissions"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/user_management');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.engineering_outlined),
                  title: const Text("Staff Overview"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/staff_overview');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_edu),
                  title: const Text("All Resident History"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/resident_history');
                  },
                ),
              ],

              // --- TECHNICIAN ONLY ITEMS ---
              if (role == 'technician') ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.build_circle_outlined),
                  title: const Text("My Assignments"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/technician_dashboard');
                  },
                ),
              ],

              // --- RESIDENT (USER) ONLY ITEMS ---
              if (role == 'user') ...[
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: const Text("Report New Fault"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/report_fault');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text("My History"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/resident_history');
                  },
                ),
              ],

              const Spacer(),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmLogout(context, supabase),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, SupabaseClient supabase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
