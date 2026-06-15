import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_service_screen.dart'; // For ServiceItem
import '../app_state.dart';
import 'my_orders_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceItem service;
  const ServiceDetailsScreen({super.key, required this.service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  DateTime? _selectedDate;
  String? _selectedWindow;
  bool _isSubmitting = false;

  final List<String> _timeWindows = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    '18:00 - 20:00',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.service.color,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF3F3D56),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedWindow == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final newOrder = BookedOrder(
      id: '', // Handled dynamically in Firestore
      serviceName: widget.service.name,
      icon: widget.service.icon,
      color: widget.service.color,
      date: _selectedDate!,
      timeWindow: _selectedWindow!,
    );

    try {
      await AppState().saveOrder(newOrder);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            backgroundColor: const Color(0xFF3F3D56),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'BOOK ${widget.service.name.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [widget.service.color, const Color(0xFF3F3D56)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.service.icon,
                    size: 70,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
            ),
          ),
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
                          'Select Date & Time',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F3D56),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Date Selection Card
                        _buildSectionHeader('Available Date'),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedDate != null ? widget.service.color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: widget.service.color),
                                const SizedBox(width: 16),
                                Text(
                                  _selectedDate == null 
                                      ? 'Tap to select a date' 
                                      : DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedDate == null ? Colors.grey : const Color(0xFF3F3D56),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Time Window Selection
                        _buildSectionHeader('Available Windows'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _timeWindows.map((window) {
                            final isSelected = _selectedWindow == window;
                            return InkWell(
                              onTap: () => setState(() => _selectedWindow = window),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? widget.service.color : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  window,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF3F3D56),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Confirm Button
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: (_selectedDate != null && _selectedWindow != null && !_isSubmitting) 
                                ? _confirmBooking 
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.service.color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'CONFIRM BOOKING',
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                          ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey[500],
        letterSpacing: 1.5,
      ),
    );
  }
}
