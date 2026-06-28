// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _billedOrders = [];
  bool _isLoading = true;
  String? get _tailorId => TailorAuth.getCurrentTailorId();

  @override
  void initState() {
    super.initState();
    _loadBilledOrders();
  }

  Future<void> _loadBilledOrders() async {
    if (_tailorId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    _billedOrders.clear();

    try {
      // Get all measurements with isBill = true
      final snapshot = await FirebaseFirestore.instance
          .collection("measurements")
          .where("tailor_id", isEqualTo: _tailorId)
          .where("isBill", isEqualTo: true)
          .orderBy("created_at", descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final customerId = data['customer_id'];

        // Get customer details
        final customerDoc = await FirebaseFirestore.instance
            .collection("customers")
            .doc(customerId)
            .get();

        if (customerDoc.exists) {
          final customerData = customerDoc.data();
          final customerName = customerData?['name'] ?? 'Unknown';

          _billedOrders.add({
            'measurementId': doc.id,
            'customerId': customerId,
            'customerName': customerName,
            'customerPhone': customerData?['phone'] ?? '',
            'customerEmail': customerData?['email'] ?? '',
            'orderId':
                '${customerName.substring(0, 2).toUpperCase()}-${customerId.substring(0, 4).toUpperCase()}',
            'chest': data['chest'] ?? 0.0,
            'waist': data['waist'] ?? 0.0,
            'hip': data['hip'] ?? 0.0,
            'shoulder': data['shoulder'] ?? 0.0,
            'sleeve_length': data['sleeve_length'] ?? 0.0,
            'neck': data['neck'] ?? 0.0,
            'shirt_length': data['shirt_length'] ?? 0.0,
            'trouser_length': data['trouser_length'] ?? 0.0,
            'price': data['price'] ?? 0.0,
            'isCompleted': data['isCompleted'] ?? false,
            'isBill': data['isBill'] ?? true,
            'created_at': data['created_at'] != null
                ? (data['created_at'] as Timestamp).toDate()
                : DateTime.now(),
          });
        }
      }

      // Sort by created_at descending
      _billedOrders.sort((a, b) => b['created_at'].compareTo(a['created_at']));

      print('Loaded ${_billedOrders.length} billed orders');
    } catch (e) {
      print('Error loading billed orders: $e');
    }

    setState(() => _isLoading = false);
  }

  // ignore: unused_element
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.primary,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEF2)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _billedOrders.isEmpty
              ? _buildEmptyState()
              : _buildOrderList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Bill History',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Billed orders will appear here',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _billedOrders.length,
      itemBuilder: (context, index) {
        final order = _billedOrders[index];
        return _BilledOrderCard(order: order);
      },
    );
  }
}

// ── Billed Order Card ─────────────────────────────────────────────────────────
class _BilledOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _BilledOrderCard({required this.order});

  static const List<Color> _avatarColors = [
    Color(0xFF1A2A4A),
    Color(0xFF2E3F6E),
    Color(0xFF1E4D6B),
    Color(0xFF3B2E6E),
    Color(0xFF1A4A3A),
    Color(0xFF4A2E1A),
    Color(0xFF2E1A4A),
    Color(0xFF4A1A2E),
  ];

  Color get _avatarColor =>
      _avatarColors[order['customerName'].codeUnitAt(0) % _avatarColors.length];

  String get _initials {
    final parts = order['customerName'].trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isCompleted = order['isCompleted'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _avatarColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _avatarColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                // Order info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['customerName'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order['customerPhone'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_rounded,
                            size: 12,
                            color: const Color(0xFF1A6AE0).withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order['orderId'],
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A6AE0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1A6AE0).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 10,
                            color: const Color(0xFF1A6AE0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Billed',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A6AE0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rs. ${order['price']?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom measurements strip
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.straighten_rounded,
                  size: 13,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Chest: ${order['chest']?.toStringAsFixed(1) ?? '0.0"'} • Waist: ${order['waist']?.toStringAsFixed(1) ?? '0.0"'} • Hip: ${order['hip']?.toStringAsFixed(1) ?? '0.0"'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(order['created_at']),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.neutral.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}