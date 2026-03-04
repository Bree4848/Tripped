import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  State<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // We are using a standard AppBar here to ensure the Drawer trigger works perfectly
      appBar: AppBar(
        title: const Text(
          "My Active Jobs",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // HOME BUTTON: Replaces the need for a back button
          IconButton(
            tooltip: 'Go to Portal',
            icon: const Icon(Icons.home_rounded, size: 26),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/portal_home');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // This will now show the Hamburger icon because 'leading' is empty
      drawer: const AppDrawer(),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('faults')
            .stream(primaryKey: ['id'])
            .eq('assigned_tech_id', user?.id ?? '')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final myJobs = snapshot.data ?? [];

          if (myJobs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myJobs.length,
            itemBuilder: (context, index) {
              final job = myJobs[index];
              return _buildJobCard(job);
            },
          );
        },
      ),
    );
  }

  // --- HELPERS (Kept exactly as you had them) ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No active assignments",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text("Updates appear here automatically."),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    String status = job['status'] ?? 'pending';
    bool isResolved = status == 'resolved';
    bool isInProgress = status == 'in-progress';

    final DateTime createdAt = DateTime.parse(job['created_at']);
    final String formattedDate = DateFormat(
      'MMM dd, yyyy • HH:mm',
    ).format(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isResolved ? Colors.green[50] : Colors.orange[50],
          child: Icon(
            job['category'] == 'electricity' ? Icons.bolt : Icons.water_drop,
            color: isResolved ? Colors.green : Colors.orange[800],
          ),
        ),
        title: Text(
          job['location'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(formattedDate, style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  "Issue Detail:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(job['description'] ?? "No description provided."),
                const SizedBox(height: 20),
                if (!isResolved)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!isInProgress)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _updateJobStatus(job['id'], 'in-progress'),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("START WORK"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[900],
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _updateJobStatus(job['id'], 'resolved'),
                        icon: const Icon(Icons.check),
                        label: const Text("MARK FIXED"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                else
                  const Center(
                    child: Chip(
                      label: Text("COMPLETED"),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
    try {
      await _supabase
          .from('faults')
          .update({'status': newStatus})
          .eq('id', jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Job marked as ${newStatus.replaceAll('-', ' ')}"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}
