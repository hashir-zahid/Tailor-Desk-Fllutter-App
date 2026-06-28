// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class RecentOrderItem extends StatelessWidget {
  final String orderId;
  final String customer;
  final String amount;
  final String status;
  final String avatarText;
  final VoidCallback? onTap;

  const RecentOrderItem({
    super.key,
    required this.orderId,
    required this.customer,
    required this.amount,
    required this.status,
    required this.avatarText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _getAvatarColor(avatarText),
        child: Text(
          avatarText,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        customer,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        orderId,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.neutral.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Rs. $amount',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String text) {
    final colors = [
      const Color(0xFF1A2A4A),
      const Color(0xFF2E3F6E),
      const Color(0xFF1E4D6B),
      const Color(0xFF3B2E6E),
      const Color(0xFF1A4A3A),
      const Color(0xFF4A2E1A),
      const Color(0xFF2E1A4A),
      const Color(0xFF4A1A2E),
    ];
    return colors[text.codeUnitAt(0) % colors.length];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.withValues(alpha: 0.15);
      case 'pending':
        return Colors.orange.withValues(alpha: 0.15);
      case 'processing':
        return Colors.blue.withValues(alpha: 0.15);
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.15);
      default:
        return AppColors.neutral.withValues(alpha: 0.1);
    }
  }
}

// ── Recent Orders List (Fetches from Firestore) ──
class RecentOrdersList extends StatefulWidget {
  final Function(Map<String, dynamic>)? onOrderTap;

  const RecentOrdersList({
    super.key,
    this.onOrderTap,
  });

  @override
  State<RecentOrdersList> createState() => _RecentOrdersListState();
}

class _RecentOrdersListState extends State<RecentOrdersList> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? get _tailorId => TailorAuth.getCurrentTailorId();

  @override
  void initState() {
    super.initState();
    _loadRecentOrders();
  }

  Future<void> _loadRecentOrders() async {
    if (_tailorId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get measurements where isCompleted == false AND isBill == false
      final snapshot = await FirebaseFirestore.instance
          .collection("measurements")
          .where("tailor_id", isEqualTo: _tailorId)
          .where("isCompleted", isEqualTo: false)
          .where("isBill", isEqualTo: false)
          .limit(5)
          .get();

      print('Found ${snapshot.docs.length} pending orders');

      List<Map<String, dynamic>> tempOrders = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final customerId = data['customer_id'];

        if (customerId == null) continue;

        // Get customer details
        final customerDoc = await FirebaseFirestore.instance
            .collection("customers")
            .doc(customerId)
            .get();

        if (customerDoc.exists) {
          final customerData = customerDoc.data();
          final customerName = customerData?['name'] ?? 'Unknown';
          final price = data['price'] ?? 0.0;

          tempOrders.add({
            'id': 'Order #${doc.id.substring(0, 6).toUpperCase()}',
            'customer': customerName,
            'amount': price.toStringAsFixed(0),
            'status': 'Pending',
            'avatar': customerName.substring(0, 1).toUpperCase(),
            'measurementId': doc.id,
            'customerId': customerId,
            'created_at': data['created_at'] != null
                ? (data['created_at'] as Timestamp).toDate()
                : DateTime.now(),
          });
        }
      }

      setState(() {
        _orders = tempOrders;
        _isLoading = false;
      });

      print('Loaded ${_orders.length} recent orders');
    } catch (e) {
      print('Error loading recent orders: $e');
      
      // If index error, try without orderBy
      try {
        print('Trying without orderBy...');
        final snapshot = await FirebaseFirestore.instance
            .collection("measurements")
            .where("tailor_id", isEqualTo: _tailorId)
            .where("isCompleted", isEqualTo: false)
            .where("isBill", isEqualTo: false)
            .get();

        List<Map<String, dynamic>> tempOrders = [];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final customerId = data['customer_id'];

          if (customerId == null) continue;

          final customerDoc = await FirebaseFirestore.instance
              .collection("customers")
              .doc(customerId)
              .get();

          if (customerDoc.exists) {
            final customerData = customerDoc.data();
            final customerName = customerData?['name'] ?? 'Unknown';
            final price = data['price'] ?? 0.0;

            tempOrders.add({
              'id': 'Order #${doc.id.substring(0, 6).toUpperCase()}',
              'customer': customerName,
              'amount': price.toStringAsFixed(0),
              'status': 'Pending',
              'avatar': customerName.substring(0, 1).toUpperCase(),
              'measurementId': doc.id,
              'customerId': customerId,
              'created_at': data['created_at'] != null
                  ? (data['created_at'] as Timestamp).toDate()
                  : DateTime.now(),
            });
          }
        }

        // Sort locally and limit to 5
        tempOrders.sort((a, b) => b['created_at'].compareTo(a['created_at']));
        if (tempOrders.length > 5) {
          tempOrders = tempOrders.sublist(0, 5);
        }

        setState(() {
          _orders = tempOrders;
          _isLoading = false;
        });

        print('Loaded ${_orders.length} recent orders (without orderBy)');
      } catch (e2) {
        print('Error without orderBy: $e2');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.neutral.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 10),
            Text(
              'No pending orders',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _orders.asMap().entries.map((entry) {
          int index = entry.key;
          var order = entry.value;

          return Column(
            children: [
              RecentOrderItem(
                orderId: order["id"]!,
                customer: order["customer"]!,
                amount: order["amount"]!,
                status: order["status"]!,
                avatarText: order["avatar"]!,
                onTap: () {
                  if (widget.onOrderTap != null) {
                    widget.onOrderTap!(order);
                  }
                },
              ),
              if (index < _orders.length - 1)
                const Divider(height: 1, color: Color(0xFFEEEEF2)),
            ],
          );
        }).toList(),
      ),
    );
  }
}