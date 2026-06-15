import 'package:flutter/material.dart';
import 'service_details_screen.dart';

class ServiceItem {
  final String name;
  final IconData icon;
  final Color color;

  ServiceItem({required this.name, required this.icon, required this.color});
}

class OrderServiceScreen extends StatefulWidget {
  const OrderServiceScreen({super.key});

  @override
  State<OrderServiceScreen> createState() => _OrderServiceScreenState();
}

class _OrderServiceScreenState extends State<OrderServiceScreen> {
  int? _selectedIndex;

  final List<ServiceItem> _services = [
    ServiceItem(name: 'Cleaning', icon: Icons.cleaning_services_rounded, color: const Color(0xFF6C63FF)),
    ServiceItem(name: 'Plumber', icon: Icons.plumbing_rounded, color: const Color(0xFFE91E63)),
    ServiceItem(name: 'Electrician', icon: Icons.electrical_services_rounded, color: const Color(0xFFFF9800)),
    ServiceItem(name: 'Painter', icon: Icons.format_paint_rounded, color: const Color(0xFF00BCD4)),
    ServiceItem(name: 'Carpenter', icon: Icons.handyman_rounded, color: const Color(0xFF4CAF50)),
    ServiceItem(name: 'Gardener', icon: Icons.local_florist_rounded, color: const Color(0xFF9C27B0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF3F3D56),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 20),
              title: const Text(
                'SERVICES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF9800), Color(0xFF3F3D56)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.build_circle_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),

          // Centered Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 30),
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
                          'Which service\ndo you need?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F3D56),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Select a professional to help you with your task.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                        const SizedBox(height: 32),
                        
                        // Grid of Services
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(index);
                          },
                        ),
                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Sleek Continue Button
      floatingActionButton: AnimatedOpacity(
        opacity: _selectedIndex != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: _selectedIndex != null 
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(service: _services[_selectedIndex!]),
                    ),
                  );
                }
              : null,
          backgroundColor: _selectedIndex != null ? _services[_selectedIndex!].color : Colors.grey,
          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          label: const Text(
            'CONTINUE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(int index) {
    final item = _services[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? item.color : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? item.color.withOpacity(0.2) 
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: const Color(0xFF3F3D56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
