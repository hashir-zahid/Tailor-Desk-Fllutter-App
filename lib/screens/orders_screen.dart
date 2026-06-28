// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_desk_app/services/measurement_service.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/widgets/app_header.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';
import 'edit_measurement_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _OrderFilter _activeFilter = _OrderFilter.all;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  String? get _tailorId => TailorAuth.getCurrentTailorId();

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> list = List.from(_orders);

    switch (_activeFilter) {
      case _OrderFilter.pending:
        list = list.where((o) => o['isCompleted'] == false).toList();
        break;
      case _OrderFilter.completed:
        list = list.where((o) => o['isCompleted'] == true).toList();
        break;
      case _OrderFilter.inProgress:
        list = list.where((o) => o['isCompleted'] == false).toList();
        break;
      case _OrderFilter.all:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (o) =>
                o['customerName'].toLowerCase().contains(q) ||
                o['customerPhone'].contains(q) ||
                o['orderId'].toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.trim()),
    );
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (_tailorId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _orders.clear();
    });

    try {
      List<Map<String, dynamic>> freshOrders = [];

      // Get all customers for this tailor
      final allCustomersSnapshot = await FirebaseFirestore.instance
          .collection("customers")
          .where("tailor_id", isEqualTo: _tailorId)
          .get(const GetOptions(source: Source.server));

      print('Found ${allCustomersSnapshot.docs.length} total customers');

      for (final customerDoc in allCustomersSnapshot.docs) {
        final customerData = customerDoc.data();
        final customerId = customerDoc.id;
        final customerName = customerData['name'] ?? 'Unknown';
        final hasMeasurements = customerData['has_measurements'] ?? false;

        // Skip if has_measurements is false
        if (!hasMeasurements) {
          print('Skipping customer without measurements: $customerName');
          continue;
        }

        print('Processing customer with measurements: $customerName');

        // Get measurements for this customer - WITHOUT orderBy to avoid index issue
        final measurementSnapshot = await FirebaseFirestore.instance
            .collection("measurements")
            .where("customer_id", isEqualTo: customerId)
            .get(const GetOptions(source: Source.server));

        if (measurementSnapshot.docs.isEmpty) {
          print('No measurement found for customer: $customerName');
          continue;
        }

        // Find the latest measurement manually
        Map<String, dynamic>? latestMeasurement;
        DocumentSnapshot? latestDoc;
        DateTime? latestDate;

        for (final doc in measurementSnapshot.docs) {
          final data = doc.data();
          final createdAt = data['created_at'] != null
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.now();

          if (latestDate == null || createdAt.isAfter(latestDate)) {
            latestDate = createdAt;
            latestMeasurement = data;
            latestDoc = doc;
          }
        }

        if (latestMeasurement == null || latestDoc == null) {
          print('No valid measurement found for customer: $customerName');
          continue;
        }

        final data = latestMeasurement;
        final measurementDoc = latestDoc;

        print('Found measurement for: $customerName');

        // Skip if bill is already generated
        if (data['isBill'] == true) {
          print('Skipping billed order for: $customerName');
          continue;
        }

        freshOrders.add({
          'measurementId': measurementDoc.id,
          'customerId': customerId,
          'customerName': customerName,
          'customerPhone': customerData['phone'] ?? '',
          'customerEmail': customerData['email'] ?? '',
          'orderId':
              '${customerName.toString().substring(0, customerName.toString().length >= 2 ? 2 : 1).toUpperCase()}-${customerId.toString().substring(0, 4).toUpperCase()}',
          'chest': (data['chest'] ?? 0).toDouble(),
          'waist': (data['waist'] ?? 0).toDouble(),
          'hip': (data['hip'] ?? 0).toDouble(),
          'shoulder': (data['shoulder'] ?? 0).toDouble(),
          'sleeve_length': (data['sleeve_length'] ?? 0).toDouble(),
          'neck': (data['neck'] ?? 0).toDouble(),
          'shirt_length': (data['shirt_length'] ?? 0).toDouble(),
          'trouser_length': (data['trouser_length'] ?? 0).toDouble(),
          'price': (data['price'] ?? 0).toDouble(),
          'isCompleted': data['isCompleted'] ?? false,
          'isBill': data['isBill'] ?? false,
          'created_at': latestDate ?? DateTime.now(),
        });
      }

      // Sort orders by created_at descending
      freshOrders.sort((a, b) => b['created_at'].compareTo(a['created_at']));

      setState(() {
        _orders = freshOrders;
      });

      print('Total orders loaded: ${_orders.length}');
    } catch (e) {
      print("Error loading orders: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OrderFilterSheet(
        current: _activeFilter,
        onSelect: (f) {
          setState(() => _activeFilter = f);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _toggleOrderStatus(
    String measurementId,
    bool currentStatus,
  ) async {
    try {
      await MeasurementService.updateMeasurementStatus(
        measurementId: measurementId,
        isCompleted: !currentStatus,
      );

      setState(() {
        final index = _orders.indexWhere(
          (o) => o['measurementId'] == measurementId,
        );
        if (index != -1) {
          _orders[index]['isCompleted'] = !currentStatus;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus
                ? 'Order marked as completed ✅'
                : 'Order marked as pending ⏳',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: !currentStatus
              ? const Color(0xFF1A9E5C)
              : const Color(0xFFE08C00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBillConfirmationDialog(String measurementId, String customerName, double price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6AE0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_rounded,
                color: Color(0xFF1A6AE0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Generate Bill',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate bill for $customerName?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Amount: Rs. ${price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE08C00).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE08C00).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: const Color(0xFFE08C00),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE08C00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral.withValues(alpha: 0.6),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A6AE0), Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A6AE0).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _generateBill(measurementId);
              },
              child: const Text(
                'Pay Bill',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateBill(String measurementId) async {
    try {
      await MeasurementService.updateBillStatus(
        measurementId: measurementId,
        isBill: true,
      );

      setState(() {
        _orders.removeWhere((o) => o['measurementId'] == measurementId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.receipt_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Bill generated successfully ✅',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A6AE0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating bill: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCountBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.whiteOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 14,
            color: AppColors.whiteOpacity(0.8),
          ),
          const SizedBox(width: 5),
          Text(
            '${_orders.length}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppHeader(
          tailorName: 'Orders',
          shopName: 'Manage your tailoring orders',
          logoWidget: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.whiteOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.whiteOpacity(0.2), width: 1),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          elevation: 6,
          toolbarHeight: 80,
          logoSize: 44,
          actions: [_buildCountBadge()],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildStatsRow(orders),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _buildList(orders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone or order ID…',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.neutral.withValues(alpha: 0.5),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: AppColors.neutral.withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              HapticFeedback.selectionClick();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _showFilterSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: _activeFilter != _OrderFilter.all
                      ? AppColors.primary
                      : AppColors.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: _activeFilter != _OrderFilter.all ? 0.35 : 0.08,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: _activeFilter != _OrderFilter.all
                      ? AppColors.textPrimary
                      : AppColors.neutral,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<Map<String, dynamic>> orders) {
    final completed = orders.where((o) => o['isCompleted'] == true).length;
    final pending = orders.where((o) => o['isCompleted'] == false).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${orders.length} ${orders.length != 1 ? 'orders' : 'order'}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A9E5C).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: const Color(0xFF1A9E5C),
                ),
                const SizedBox(width: 4),
                Text(
                  '$completed done',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1A9E5C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE08C00).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: const Color(0xFFE08C00),
                ),
                const SizedBox(width: 4),
                Text(
                  '$pending pending',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE08C00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_activeFilter != _OrderFilter.all) ...[
            GestureDetector(
              onTap: () {
                setState(() => _activeFilter = _OrderFilter.all);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _activeFilter.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 12,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '"$_searchQuery"',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return _EmptyState(isSearch: _searchQuery.isNotEmpty);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          onStatusToggle: _toggleOrderStatus,
          onBillTap: () {
            _showBillConfirmationDialog(
              order['measurementId'],
              order['customerName'],
              order['price'],
            );
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditMeasurementScreen(
                  measurementId: order['measurementId'],
                  customerId: order['customerId'],
                ),
              ),
            ).then((_) => _loadOrders());
          },
        );
      },
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(String, bool) onStatusToggle;
  final VoidCallback onBillTap;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onStatusToggle,
    required this.onBillTap,
    required this.onTap,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isCompleted = order['isCompleted'] ?? false;
    final statusColor = isCompleted
        ? const Color(0xFF1A9E5C)
        : const Color(0xFFE08C00);
    final statusText = isCompleted ? 'Completed' : 'Pending';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
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
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onStatusToggle(
                          order['measurementId'],
                          isCompleted,
                        );
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF1A9E5C)
                              : Colors.transparent,
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFF1A9E5C)
                                : AppColors.neutral.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 13),
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
                          const SizedBox(height: 5),
                          Text(
                            order['customerPhone'],
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (order['customerEmail'] != null &&
                              order['customerEmail'] != '')
                            Text(
                              'Rs. ${order['price']?.toStringAsFixed(0) ?? '0'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ✅ Bill Button instead of chevron
                        GestureDetector(
                          onTap: widget.onBillTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A6AE0), Color(0xFF4A90E2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A6AE0,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.receipt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Bill',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _OrderFilterSheet extends StatelessWidget {
  final _OrderFilter current;
  final void Function(_OrderFilter) onSelect;

  const _OrderFilterSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Orders',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Choose a status to filter by',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.neutral.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 14),
          ..._OrderFilter.values.map(
            (option) => _FilterTile(
              option: option,
              isSelected: current == option,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(option);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final _OrderFilter option;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isSelected ? 0.3 : 0.06,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                option.icon,
                size: 18,
                color: isSelected ? AppColors.textPrimary : AppColors.neutral,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.secondary,
                    ),
                  ),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
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
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_rounded,
                size: 36,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? 'No results found' : 'No orders yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try a different name, phone or order ID'
                  : 'Orders will appear here once you add measurements to customers',
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
}

// ── Filter Enum ───────────────────────────────────────────────────────────────
enum _OrderFilter {
  all,
  pending,
  completed,
  inProgress;

  String get label => switch (this) {
    _OrderFilter.all => 'All Orders',
    _OrderFilter.pending => 'Pending',
    _OrderFilter.completed => 'Completed',
    _OrderFilter.inProgress => 'In Progress',
  };

  String get description => switch (this) {
    _OrderFilter.all => 'Show all orders in the system',
    _OrderFilter.pending => 'Orders waiting to be started',
    _OrderFilter.completed => 'Successfully finished orders',
    _OrderFilter.inProgress => 'Orders currently being worked on',
  };

  IconData get icon => switch (this) {
    _OrderFilter.all => Icons.receipt_long_rounded,
    _OrderFilter.pending => Icons.schedule_rounded,
    _OrderFilter.completed => Icons.check_circle_rounded,
    _OrderFilter.inProgress => Icons.autorenew_rounded,
  };
}
