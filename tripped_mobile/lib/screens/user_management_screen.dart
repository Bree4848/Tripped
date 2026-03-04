import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/branded_app_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = "";

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User updated to $newRole")));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(
        screenName: "User Permissions",
        backgroundColor: Color(0xFF1A237E),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search users by name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('profiles')
                  .stream(primaryKey: ['id'])
                  .order('full_name'),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!
                    .where(
                      (u) => (u['full_name'] ?? "").toLowerCase().contains(
                        _searchQuery,
                      ),
                    )
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final String currentRole = user['role'] ?? 'resident';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: currentRole == 'admin'
                            ? Colors.red[100]
                            : Colors.blue[100],
                        child: Icon(
                          currentRole == 'admin'
                              ? Icons.security
                              : Icons.person,
                          color: currentRole == 'admin'
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                      title: Text(user['full_name'] ?? "No Name"),
                      subtitle: Text(
                        "Current Role: ${currentRole.toUpperCase()}",
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (newRole) =>
                            _updateUserRole(user['id'], newRole),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'admin',
                            child: Text("Make Admin"),
                          ),
                          const PopupMenuItem(
                            value: 'technician',
                            child: Text("Make Technician"),
                          ),
                          const PopupMenuItem(
                            value: 'resident',
                            child: Text("Make Resident"),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
