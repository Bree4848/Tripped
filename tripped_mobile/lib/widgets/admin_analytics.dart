import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalytics extends StatelessWidget {
  const AdminAnalytics({super.key});

  Future<Map<String, int>> _getStats() async {
    final supabase = Supabase.instance.client;

    // Fetch all fault statuses
    final response = await supabase.from('faults').select('status');

    int pending = 0;
    int inProgress = 0;
    int resolved = 0;

    for (var item in response) {
      final status = item['status'];
      if (status == 'pending')
        pending++;
      else if (status == 'in-progress')
        inProgress++;
      else if (status == 'resolved')
        resolved++;
    }

    return {
      'pending': pending,
      'in-progress': inProgress,
      'resolved': resolved,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );

        final data = snapshot.data!;
        final total = data.values.fold(0, (sum, item) => sum + item);

        if (total == 0) return const Center(child: Text("No data to display"));

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "System Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: data['pending']!.toDouble(),
                          title: '${data['pending']}',
                          color: Colors.red,
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: data['in-progress']!.toDouble(),
                          title: '${data['in-progress']}',
                          color: Colors.orange,
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: data['resolved']!.toDouble(),
                          title: '${data['resolved']}',
                          color: Colors.green,
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLegend(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem("Pending", Colors.red),
        _legendItem("In-Progress", Colors.orange),
        _legendItem("Resolved", Colors.green),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
