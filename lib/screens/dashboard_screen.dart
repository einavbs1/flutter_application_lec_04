import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'download_screen.dart';
import 'order_service_screen.dart';
import 'my_orders_screen.dart';
import 'resume_screen.dart';
import 'home_page.dart';
import '../app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          // Premium Header with Logout
           SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false, // Disables back button
            backgroundColor: const Color(0xFF3F3D56),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pushReplacement(
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 20),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'DASHBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome, ${AppState().customDisplayName.isNotEmpty ? AppState().customDisplayName : displayName}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.dashboard_customize_outlined,
                    size: 90,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),
          
          // Centered Actions
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F3D56),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Order Service Card
                        _buildActionCard(
                          context,
                          title: 'Order Service',
                          subtitle: 'Request professional assistance or repairs.',
                          icon: Icons.build_circle_outlined,
                          color: const Color(0xFFFF9800),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OrderServiceScreen()),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // My Orders Card
                        _buildActionCard(
                          context,
                          title: 'My Orders',
                          subtitle: 'Track your upcoming and past services.',
                          icon: Icons.assignment_turned_in_outlined,
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Download Center Card
                        _buildActionCard(
                          context,
                          title: 'Download Center',
                          subtitle: 'Browse and manage your available content library.',
                          icon: Icons.cloud_download_outlined,
                          color: const Color(0xFF6C63FF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DownloadScreen()),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Resume Center Card
                        user == null
                            ? _buildActionCard(
                                context,
                                title: 'Resume Center',
                                subtitle: 'Upload and manage your PDF resumes.',
                                icon: Icons.description_outlined,
                                color: const Color(0xFF3F3D56),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ResumeScreen()),
                                  );
                                },
                              )
                            : StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('resumes')
                                    .orderBy('timestamp', descending: true)
                                    .limit(1)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  String subtitle = 'Upload and manage your PDF resumes.';
                                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                    final doc = snapshot.data!.docs.first;
                                    final timestamp = doc['timestamp'] as Timestamp?;
                                    if (timestamp != null) {
                                      final date = timestamp.toDate();
                                      final formatted = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                                      subtitle = 'Last uploaded: $formatted';
                                    }
                                  }
                                  return _buildActionCard(
                                    context,
                                    title: 'Resume Center',
                                    subtitle: subtitle,
                                    icon: Icons.description_outlined,
                                    color: const Color(0xFF3F3D56),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ResumeScreen()),
                                      );
                                    },
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F3D56),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
