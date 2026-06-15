import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookedOrder {
  final String id;
  final String serviceName;
  final IconData icon;
  final Color color;
  final DateTime date;
  final String timeWindow;
  final String status; // 'active' or 'completed'

  BookedOrder({
    required this.id,
    required this.serviceName,
    required this.icon,
    required this.color,
    required this.date,
    required this.timeWindow,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceName': serviceName,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'date': Timestamp.fromDate(date),
      'timeWindow': timeWindow,
      'status': status,
    };
  }

  factory BookedOrder.fromMap(String docId, Map<String, dynamic> map) {
    return BookedOrder(
      id: docId,
      serviceName: map['serviceName'] ?? '',
      icon: IconData(map['iconCodePoint'] ?? Icons.home_repair_service.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] ?? 0xFF6C63FF),
      date: (map['date'] as Timestamp).toDate(),
      timeWindow: map['timeWindow'] ?? '',
      status: map['status'] ?? 'active',
    );
  }
}

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Profile data
  String customDisplayName = '';
  String profileImageUrl = 'https://ui-avatars.com/api/?name=User&background=6C63FF&color=fff';

  // Firebase integration
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // Local copy of active orders
  List<BookedOrder> orders = [];

  // Fetch orders from Firestore
  Future<List<BookedOrder>> fetchOrders() async {
    final uid = currentUid;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('orders')
          .orderBy('date', descending: true)
          .get();

      orders = snapshot.docs.map((doc) {
        return BookedOrder.fromMap(doc.id, doc.data());
      }).toList();

      return orders;
    } catch (e) {
      debugPrint('Error fetching orders from Firestore: $e');
      return [];
    }
  }

  // Save new order to Firestore
  Future<void> saveOrder(BookedOrder order) async {
    final uid = currentUid;
    if (uid == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(order.id.isEmpty ? null : order.id);

      await docRef.set(order.toMap());
      
      // Update local memory list
      final newOrder = BookedOrder(
        id: docRef.id,
        serviceName: order.serviceName,
        icon: order.icon,
        color: order.color,
        date: order.date,
        timeWindow: order.timeWindow,
        status: order.status,
      );
      
      // Replace or add
      final index = orders.indexWhere((o) => o.id == newOrder.id);
      if (index != -1) {
        orders[index] = newOrder;
      } else {
        orders.add(newOrder);
      }
    } catch (e) {
      debugPrint('Error saving order to Firestore: $e');
      rethrow;
    }
  }

  // Complete an order in Firestore
  Future<void> completeOrder(String orderId) async {
    final uid = currentUid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(orderId)
          .update({'status': 'completed'});

      // Update local cache
      final index = orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final old = orders[index];
        orders[index] = BookedOrder(
          id: old.id,
          serviceName: old.serviceName,
          icon: old.icon,
          color: old.color,
          date: old.date,
          timeWindow: old.timeWindow,
          status: 'completed',
        );
      }
    } catch (e) {
      debugPrint('Error completing order: $e');
      rethrow;
    }
  }

  // Remove order from Firestore
  Future<void> deleteOrder(String orderId) async {
    final uid = currentUid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(orderId)
          .delete();

      orders.removeWhere((o) => o.id == orderId);
    } catch (e) {
      debugPrint('Error deleting order from Firestore: $e');
      rethrow;
    }
  }
}
