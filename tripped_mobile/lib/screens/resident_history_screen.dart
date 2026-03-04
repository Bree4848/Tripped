import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_drawer.dart';

class ResidentHistoryScreen extends StatefulWidget {
  const ResidentHistoryScreen({super.key});

  @override
  State<ResidentHistoryScreen> createState() => _ResidentHistoryScreenState();
}

class _ResidentHistoryScreenState extends State<ResidentHistoryScreen> {
  final _supabase = Supabase.instance.client;
  String _filterStatus = 'all';

  // --- CSV EXPORT LOGIC (Kept exactly as requested) ---
  Future<void> _exportToCSV(List<Map<String, dynamic>> data) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add([
        "Date",
        "Location",
        "Category",
        "Status",
        "Description",
        "Resident ID",
      ]);

      for (var fault in data) {
        rows.add([
          fault['created_at'],
          fault['location'],
          fault['category'],
          fault['status'],
          fault['description'],
          fault['resident_id'],
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path =
          "${directory.path}/tripped_report_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([
        XFile(path),
      ], text: 'Resident Fault Report Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // The drawer will now show the hamburger icon because we aren't overriding 'leading'
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          "Resident History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          // HOME BUTTON: Allows quick return to Portal Home
          IconButton(
            tooltip: "Go to Portal",
            icon: const Icon(Icons.home_rounded),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/portal_home'),
          ),
          // EXPORT BUTTON
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('faults').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              return IconButton(
                tooltip: "Export to CSV",
                icon: const Icon(Icons.file_download_outlined),
                onPressed: () {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    _exportToCSV(snapshot.data!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No data available to export"),
                      ),
                    );
                  }
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('faults')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No fault records found."));
                }

                final allFaults = snapshot.data!;
                final filteredFaults = _filterStatus == 'all'
                    ? allFaults
                    : allFaults
                          .where((f) => f['status'] == _filterStatus)
                          .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredFaults.length,
                  itemBuilder: (context, index) {
                    final fault = filteredFaults[index];
                    return _buildHistoryCard(fault);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS (Kept exactly as requested) ---

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: ['all', 'pending', 'in-progress', 'resolved'].map((status) {
          final isSelected = _filterStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
              selected: isSelected,
              onSelected: (val) => setState(() => _filterStatus = status),
              selectedColor: Colors.yellow[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[700],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> fault) {
    final DateTime createdAt = DateTime.parse(fault['created_at']);
    final String formattedDate = DateFormat(
      'MMM dd, yyyy • HH:mm',
    ).format(createdAt);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[50],
          child: Icon(
            fault['category'] == 'electricity' ? Icons.bolt : Icons.water_drop,
            color: Colors.indigo[900],
            size: 20,
          ),
        ),
        title: Text(
          fault['location'] ?? "Unknown Location",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(formattedDate, style: const TextStyle(fontSize: 12)),
        trailing: _statusBadge(fault['status'] ?? 'pending'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _infoRow(
                  Icons.notes,
                  "Description",
                  fault['description'] ?? "No details",
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.fingerprint,
                  "Record ID",
                  fault['id'].toString().substring(0, 8),
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.engineering_outlined,
                  "Technician",
                  fault['assigned_tech_id'] ?? "Unassigned",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.indigo[900]),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in-progress':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
