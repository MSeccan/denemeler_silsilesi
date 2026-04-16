import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_expert_request_page.dart';
import 'user_management_page.dart';
import 'system_reports_page.dart';
import 'main.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {

  int pendingRequests = 0;
  int totalUsers = 0;
  int activeExperts = 0;
  int reports = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final usersSnapshot =
    await FirebaseFirestore.instance.collection("users").get();

    final users = usersSnapshot.docs;

    totalUsers = users.length;

    pendingRequests = users.where((u) =>
    (u.data()['role'] == "gynecologist" ||
        u.data()['role'] == "dietitian") &&
        (u.data()['isApproved'] == false)).length;

    activeExperts = users.where((u) =>
    (u.data()['role'] == "gynecologist" ||
        u.data()['role'] == "dietitian") &&
        (u.data()['isApproved'] == true)).length;

    reports = 0;

    setState(() {
      loading = false;
    });
  }

  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleLoaderPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOut(context),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings,
                        color: Theme.of(context).colorScheme.primary, size: 30),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome Admin 👑",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text("System monitoring & approvals",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                _statCard(
                  title: "Pending\nRequests",
                  value: pendingRequests.toString(),
                  icon: Icons.pending_actions,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminExpertRequestsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _statCard(
                  title: "Total\nUsers",
                  value: totalUsers.toString(),
                  icon: Icons.people,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _statCard(
                  title: "Active\nExperts",
                  value: activeExperts.toString(),
                  icon: Icons.medical_services,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
                const SizedBox(width: 12),
                _statCard(
                  title: "System\nReports",
                  value: reports.toString(),
                  icon: Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SystemReportsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              "Admin Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 12),

            _adminActionCard(
              title: "Expert Applications",
              subtitle: "Approve or reject expert requests",
              icon: Icons.health_and_safety,
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminExpertRequestsPage(),
                  ),
                );
              },
            ),

            _adminActionCard(
              title: "User Management",
              subtitle: "View all users",
              icon: Icons.people_outline,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}