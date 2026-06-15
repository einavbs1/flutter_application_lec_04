import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _isLoading = true;
  List<BookedOrder> _upcomingOrders = [];
  List<BookedOrder> _historyOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  bool _isPastOrder(BookedOrder order) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(order.date.year, order.date.month, order.date.day);
    if (orderDate.isBefore(today)) return true;
    
    if (orderDate.isAtSameMomentAs(today)) {
      final parts = order.timeWindow.split(' - ');
      if (parts.length == 2) {
        final endPart = parts[1].trim(); // e.g. "16:00"
        final timeParts = endPart.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final endDateTime = DateTime(order.date.year, order.date.month, order.date.day, hour, minute);
          return endDateTime.isBefore(now);
        }
      }
    }
    return false;
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    // Dynamic database fetch from AppState/Firestore
    final allOrders = await AppState().fetchOrders();

    final upcoming = <BookedOrder>[];
    final history = <BookedOrder>[];

    for (final order in allOrders) {
      if (order.status == 'completed') {
        history.add(order);
      } else {
        upcoming.add(order);
      }
    }

    if (mounted) {
      setState(() {
        _upcomingOrders = upcoming;
        _historyOrders = history;
        _isLoading = false;
      });
    }
  }

  void _confirmCancelOrder(BuildContext context, BookedOrder order) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 12),
              Text(
                'Cancel Service',
                style: TextStyle(
                  color: Color(0xFF3F3D56),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to cancel your booking for ${order.serviceName} scheduled on ${DateFormat('MMM d, yyyy').format(order.date)}?',
            style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Keep Booking',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog

                // Show spinner
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                    ),
                  ),
                );

                try {
                  await AppState().deleteOrder(order.id);
                  if (mounted) {
                    Navigator.pop(context); // Close spinner
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${order.serviceName} booking cancelled successfully'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    _loadOrders(); // Reload from database
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close spinner
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to cancel booking: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmMarkAsCompleted(BuildContext context, BookedOrder order) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 28),
              SizedBox(width: 12),
              Text(
                'Complete Service',
                style: TextStyle(
                  color: Color(0xFF3F3D56),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to mark this booking for ${order.serviceName} as completed? If you move it to history but it is not actually done, no one will contact you to complete it.',
            style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Keep Active',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close warning dialog
                _markAsCompleted(context, order); // Perform firestore status change
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Yes, Completed', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAsCompleted(BuildContext context, BookedOrder order) async {
    // Show spinner inside nested navigator for safety
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
        ),
      ),
    );

    try {
      await AppState().completeOrder(order.id);
      if (mounted) {
        Navigator.pop(context); // Close spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${order.serviceName} marked as completed!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        _loadOrders(); // Reload from database
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete service: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Intercept navigation to hide back button when viewed as tab in shell, but allow popping if pushed
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180.0,
                pinned: true,
                automaticallyImplyLeading: canPop, // Dynamic back button support
                backgroundColor: const Color(0xFF3F3D56),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 60),
                  title: const Text(
                    'MY ORDERS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      fontSize: 16,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4CAF50), Color(0xFF3F3D56)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 80,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                bottom: TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 3.5,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  tabs: [
                    Tab(text: "UPCOMING (${_upcomingOrders.length})"),
                    Tab(text: "HISTORY (${_historyOrders.length})"),
                  ],
                ),
              ),
            ];
          },
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                )
              : TabBarView(
                  children: [
                    _buildOrdersList(_upcomingOrders, isUpcoming: true),
                    _buildOrdersList(_historyOrders, isUpcoming: false),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<BookedOrder> list, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_busy_outlined : Icons.history_toggle_off_rounded, 
              size: 64, 
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming appointments' : 'No order history found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: const Color(0xFF4CAF50),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final order = list[index];
          return _buildOrderTile(order, isUpcoming: isUpcoming);
        },
      ),
    );
  }

  Widget _buildOrderTile(BookedOrder order, {required bool isUpcoming}) {
    final isLate = isUpcoming && _isPastOrder(order);
    
    final statusColor = isUpcoming 
        ? (isLate ? const Color(0xFFFBC02D) : Colors.green) 
        : Colors.grey[500]!;
    
    final statusLabel = isUpcoming 
        ? (isLate ? 'LATE' : 'ACTIVE') 
        : 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Styled Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (isUpcoming ? order.color : Colors.grey[300]!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                order.icon, 
                color: isUpcoming ? order.color : Colors.grey[500], 
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.serviceName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUpcoming ? const Color(0xFF3F3D56) : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(order.date),
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        order.timeWindow,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge & Action Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                if (isUpcoming) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _confirmMarkAsCompleted(context, order),
                        icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                        tooltip: 'Complete Service',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _confirmCancelOrder(context, order),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 22),
                        tooltip: 'Cancel Service',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
