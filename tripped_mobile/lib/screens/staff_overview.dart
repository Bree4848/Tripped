import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/app_drawer.dart';
import '../widgets/branded_app_bar.dart';

class StaffOverviewScreen extends StatefulWidget {
  const StaffOverviewScreen({super.key});

  @override
  State<StaffOverviewScreen> createState() => _StaffOverviewScreenState();
}

class _StaffOverviewScreenState extends State<StaffOverviewScreen> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = ""; // Stores the current search text

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: BrandedAppBar(
        screenName: "Team Performance",
        backgroundColor: Colors.indigo[900],
        // --- ADDED BACK BUTTON ---
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // SEARCH SECTION
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search technicians...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // LIST SECTION
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('profiles')
                  .stream(primaryKey: ['id'])
                  .eq('role', 'technician'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter the list based on the search query
                final allTechs = snapshot.data ?? [];
                final techs = allTechs.where((tech) {
                  final name = (tech['full_name'] ?? "").toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (techs.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? "No technicians found"
                          : "No matches for '$_searchQuery'",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: techs.length + 1, // +1 for the header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsHeader(allTechs.length),
                          const SizedBox(height: 24),
                          const Text(
                            "Staff List & Efficiency",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }
                    return _buildTechPerformanceCard(techs[index - 1]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(int totalTechs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo[800],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Total Staff", totalTechs.toString(), Icons.engineering),
          const VerticalDivider(color: Colors.white24, thickness: 1),
          _statItem("Fleet Status", "Active", Icons.check_circle),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.yellow, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTechPerformanceCard(Map<String, dynamic> tech) {
    return FutureBuilder<Map<String, int>>(
      future: _getJobCounts(tech['id']),
      builder: (context, countSnapshot) {
        final active = countSnapshot.data?['active'] ?? 0;
        final resolved = countSnapshot.data?['resolved'] ?? 0;

        // --- WORKLOAD ALERT LOGIC ---
        final bool isOverloaded = active >= 5;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isOverloaded
                ? const BorderSide(color: Colors.redAccent, width: 1.5)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isOverloaded
                    ? Colors.red[100]
                    : Colors.indigo[100],
                child: Text(
                  (tech['full_name'] ?? "T")[0].toUpperCase(),
                  style: TextStyle(
                    color: isOverloaded ? Colors.red : Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    tech['full_name'] ?? "Unnamed Technician",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOverloaded ? Colors.red[900] : Colors.black87,
                    ),
                  ),
                  if (isOverloaded)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                tech['email'] ?? "No email",
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniStat(
                    "ACTIVE",
                    active,
                    isOverloaded ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 15),
                  _miniStat("DONE", resolved, Colors.green),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<Map<String, int>> _getJobCounts(String techId) async {
    try {
      final response = await _supabase
          .from('faults')
          .select('status')
          .eq('assigned_tech_id', techId);

      final List tasks = response as List;
      int active = tasks.where((t) => t['status'] != 'resolved').length;
      int resolved = tasks.where((t) => t['status'] == 'resolved').length;

      return {'active': active, 'resolved': resolved};
    } catch (e) {
      return {'active': 0, 'resolved': 0};
    }
  }
}
