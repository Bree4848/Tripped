import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortalHome extends StatelessWidget {
  const PortalHome({super.key});

  // HELPER: Fetch the role directly from Supabase to ensure UI stays consistent
  Future<String> _getLiveRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'user';
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      return (data['role'] ?? 'user').toString().toLowerCase().trim();
    } catch (e) {
      return 'user';
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final String displayName =
        user?.userMetadata?['full_name'] ??
        user?.email?.split('@')[0] ??
        "User";

    return Scaffold(
      backgroundColor:
          Colors.grey[100], // Slightly darker grey for better card contrast
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFF1A237E), size: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TRIPPED",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Text(
                  "Utility Portal",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
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
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getLiveRole(),
        builder: (context, snapshot) {
          final cleanRole = snapshot.data ?? 'user';

          return RefreshIndicator(
            onRefresh: () async =>
                await Future.delayed(const Duration(seconds: 1)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Access Level: ${cleanRole.toUpperCase()}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Hello, $displayName",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- NEWSFEED SECTION ---
                  const Text(
                    "Community News",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('news_updates')
                        .stream(primaryKey: ['id'])
                        .order('created_at', ascending: false)
                        .limit(3),
                    builder: (context, newsSnapshot) {
                      if (newsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      }
                      if (!newsSnapshot.hasData || newsSnapshot.data!.isEmpty) {
                        return _buildNewsCard(
                          "System Stable",
                          "No active utility alerts at this time.",
                          Colors.green,
                          Icons.check_circle_outline,
                        );
                      }
                      return Column(
                        children: newsSnapshot.data!.map((news) {
                          final cat = news['category']
                              ?.toString()
                              .toLowerCase();
                          // Pick a high-contrast color for the indicator
                          final Color indicatorColor = (cat == 'water')
                              ? Colors.blue[700]!
                              : Colors.orange[800]!;

                          return _buildNewsCard(
                            news['title'] ?? "Notice",
                            news['body'] ?? "",
                            indicatorColor,
                            cat == 'water' ? Icons.water_drop : Icons.bolt,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // --- WORK MANAGEMENT (Admin/Tech Only) ---
                  if (cleanRole == 'admin' || cleanRole == 'technician') ...[
                    const Text(
                      "Work Management",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (cleanRole == 'admin')
                      _buildActionButton(
                        context,
                        "Admin Control Center",
                        "Manage system and staff",
                        Icons.admin_panel_settings_rounded,
                        Colors.purple[700]!,
                        () => Navigator.pushNamed(context, '/admin_dashboard'),
                      ),
                    if (cleanRole == 'technician')
                      _buildActionButton(
                        context,
                        "Technician Dashboard",
                        "View assigned repairs",
                        Icons.engineering_rounded,
                        Colors.orange[800]!,
                        () => Navigator.pushNamed(
                          context,
                          '/technician_dashboard',
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // --- RESIDENT SERVICES (User Only) ---
                  if (cleanRole == 'user') ...[
                    const Text(
                      "Resident Services",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildActionButton(
                      context,
                      "Report a New Fault",
                      "Log a power outage or leak",
                      Icons.add_alert_rounded,
                      Colors.blue[700]!,
                      () => Navigator.pushNamed(context, '/report_fault'),
                    ),
                    _buildActionButton(
                      context,
                      "My Fault History",
                      "View status of your reports",
                      Icons.history_rounded,
                      Colors.indigo[700]!,
                      () => Navigator.pushNamed(context, '/resident_history'),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // --- EMERGENCY SECTION (Everyone) ---
                  _buildActionButton(
                    context,
                    "Emergency Contacts",
                    "Direct dial for urgent services",
                    Icons.phone_in_talk_rounded,
                    Colors.red[700]!,
                    () => _showEmergencyPicker(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- REFINED NEWS CARD HELPER ---
  Widget _buildNewsCard(
    String title,
    String body,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // This creates a solid color bar on the left for quick visual category identification
        border: Border(left: BorderSide(color: accentColor, width: 6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A237E), // Navy blue for title
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Colors.grey[800], // Dark grey for body text contrast
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTION BUTTON HELPER ---
  Widget _buildActionButton(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          sub,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  // --- EMERGENCY PICKER HELPER ---
  void _showEmergencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Emergency Services",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.orange),
              title: const Text("Electrical: 0800 111 222"),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop, color: Colors.blue),
              title: const Text("Water: 0800 333 444"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
