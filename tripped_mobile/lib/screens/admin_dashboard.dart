import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/app_drawer.dart';
import '../widgets/branded_app_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabase = Supabase.instance.client;

  // Controllers for News & Search
  final _newsTitleController = TextEditingController();
  final _newsBodyController = TextEditingController();
  final _workerSearchController = TextEditingController();

  // State for Filters
  String _selectedNewsCategory = 'electricity';
  String _selectedStatusFilter = 'all';
  String _workerSearchQuery = "";

  @override
  void dispose() {
    _newsTitleController.dispose();
    _newsBodyController.dispose();
    _workerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: BrandedAppBar(
          screenName: "Admin Command Center",
          backgroundColor: Colors.indigo[900],
          // --- UPDATED: REPLACED LEADING WITH ACTIONS ---
          actions: [
            IconButton(
              tooltip: 'Back to Portal Home',
              icon: const Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/portal_home', (route) => false);
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.yellow,
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.campaign), text: "Live Feed"),
              Tab(icon: Icon(Icons.engineering), text: "Technicians"),
              Tab(icon: Icon(Icons.list_alt), text: "Fault Queue"),
              Tab(icon: Icon(Icons.post_add), text: "News Manager"),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: TabBarView(
          children: [
            _buildPublicViewTab(),
            _buildWorkersTab(),
            _buildAllFaultsTab(),
            _buildNewsManagerTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: LIVE FEED (Resident View) ---
  Widget _buildPublicViewTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('news_updates')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final news = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: news.length,
          itemBuilder: (context, index) {
            final item = news[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  item['category'] == 'water' ? Icons.water_drop : Icons.bolt,
                  color: Colors.indigo,
                ),
                title: Text(
                  item['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(item['body']),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 2: TECHNICIANS ---
  Widget _buildWorkersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _workerSearchController,
            onChanged: (val) =>
                setState(() => _workerSearchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search technicians...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
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
                .eq('role', 'technician'),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final techs = snapshot.data!
                  .where(
                    (t) => (t['full_name'] ?? "").toLowerCase().contains(
                      _workerSearchQuery,
                    ),
                  )
                  .toList();
              return ListView.builder(
                itemCount: techs.length,
                itemBuilder: (context, i) => ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(techs[i]['full_name'] ?? 'Unnamed Tech'),
                  subtitle: Text(techs[i]['email'] ?? ''),
                  onTap: () =>
                      _showTechTasks(techs[i]['id'], techs[i]['full_name']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 3: FAULT QUEUE ---
  Widget _buildAllFaultsTab() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            // --- FIXED SYNTAX ERROR HERE ---
            children: ['all', 'pending', 'in-progress', 'resolved'].map((
              status,
            ) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status.toUpperCase()),
                  selected: _selectedStatusFilter == status,
                  onSelected: (val) =>
                      setState(() => _selectedStatusFilter = status),
                  selectedColor: Colors.yellow[700],
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _selectedStatusFilter == 'all'
                ? _supabase
                      .from('faults')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: false)
                : _supabase
                      .from('faults')
                      .stream(primaryKey: ['id'])
                      .eq('status', _selectedStatusFilter)
                      .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final faults = snapshot.data!;
              return ListView.builder(
                itemCount: faults.length,
                itemBuilder: (context, i) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      faults[i]['location'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      faults[i]['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _statusChip(faults[i]['status']),
                    onTap: () => _showAssignDialog(faults[i]['id']),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 4: NEWS MANAGER ---
  Widget _buildNewsManagerTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _newsTitleController,
                decoration: const InputDecoration(
                  labelText: "Headline",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newsBodyController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedNewsCategory,
                      items: ['electricity', 'water', 'general']
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedNewsCategory = val!),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _postNews,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[900],
                      minimumSize: const Size(100, 55),
                    ),
                    child: const Text(
                      "RELEASE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase
                .from('news_updates')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final news = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: news.length,
                itemBuilder: (context, index) {
                  final item = news[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['category'] == 'water'
                            ? Icons.water_drop
                            : Icons.bolt,
                        color: Colors.indigo,
                      ),
                      title: Text(
                        item['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item['body'], maxLines: 1),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') _showEditNewsDialog(item);
                          if (val == 'delete') _deleteNewsItem(item['id']);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text("Edit"),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- LOGIC HELPERS ---

  Future<void> _postNews() async {
    if (_newsTitleController.text.isEmpty) return;
    await _supabase.from('news_updates').insert({
      'title': _newsTitleController.text,
      'body': _newsBodyController.text,
      'category': _selectedNewsCategory,
    });
    _newsTitleController.clear();
    _newsBodyController.clear();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("News Published!")));
    }
  }

  Future<void> _deleteNewsItem(String id) async {
    await _supabase.from('news_updates').delete().eq('id', id);
  }

  void _showEditNewsDialog(Map<String, dynamic> item) {
    final editTitle = TextEditingController(text: item['title']);
    final editBody = TextEditingController(text: item['body']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Update"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editTitle,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: editBody,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Body"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _supabase
                  .from('news_updates')
                  .update({'title': editTitle.text, 'body': editBody.text})
                  .eq('id', item['id']);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDialog(String faultId) async {
    final techs = await _supabase
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'technician');
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Assign Technician",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...techs.map(
            (t) => ListTile(
              title: Text(t['full_name'] ?? 'Unknown'),
              onTap: () async {
                await _supabase
                    .from('faults')
                    .update({
                      'assigned_tech_id': t['id'],
                      'status': 'in-progress',
                    })
                    .eq('id', faultId);
                if (mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTechTasks(String techId, String? name) async {
    final tasks = await _supabase
        .from('faults')
        .select()
        .eq('assigned_tech_id', techId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Jobs: ${name ?? 'Tech'}"),
        content: SizedBox(
          width: double.maxFinite,
          child: tasks.isEmpty
              ? const Text("No tasks.")
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) =>
                      ListTile(title: Text(tasks[i]['location'])),
                ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'resolved'
        ? Colors.green
        : (status == 'in-progress' ? Colors.orange : Colors.red);
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
    );
  }
}
