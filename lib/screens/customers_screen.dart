// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_desk_app/models/customer_model.dart';
import 'package:tailor_desk_app/screens/add_customer_screen.dart';
import 'package:tailor_desk_app/screens/add_measurement_screen.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';
import 'package:tailor_desk_app/widgets/app_header.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  _FilterOption _activeFilter = _FilterOption.all;
  List<Customer> _allCustomers = [];
  bool _isLoading = true;

  String? get _tailorId => TailorAuth.getCurrentTailorId();

  List<Customer> get _filtered {
    List<Customer> list = List.from(_allCustomers);

    switch (_activeFilter) {
      case _FilterOption.nameAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _FilterOption.measurements:
        list = list.where((c) => c.hasMeasurements == true).toList();
        break;
      case _FilterOption.noMeasurements:
        list = list.where((c) => c.hasMeasurements == false).toList();
        break;
      case _FilterOption.all:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.phone.contains(q) ||
                (c.email?.toLowerCase().contains(q) ?? false),
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
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (_tailorId == null) return;

    setState(() => _isLoading = true);

    try {
      // Get customers using a one-time query
      final snapshot = await FirebaseFirestore.instance
          .collection("customers")
          .where("tailor_id", isEqualTo: _tailorId)
          .orderBy("created_at", descending: true)
          .get();
      
      _allCustomers = snapshot.docs.map((doc) {
        return Customer.fromMap(doc.id, doc.data());
      }).toList();
      
      print('Loaded ${_allCustomers.length} customers');
    } catch (e) {
      print('Error loading customers: $e');
    }

    setState(() => _isLoading = false);
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
      builder: (_) => _FilterSheet(
        current: _activeFilter,
        onSelect: (f) {
          setState(() => _activeFilter = f);
          Navigator.pop(context);
        },
      ),
    );
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
            Icons.people_outline_rounded,
            size: 14,
            color: AppColors.whiteOpacity(0.8),
          ),
          const SizedBox(width: 5),
          Text(
            '${_allCustomers.length}',
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
    final customers = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppHeader(
          tailorName: 'Customers',
          shopName: 'Manage your client directory',
          logoWidget: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.whiteOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.whiteOpacity(0.2), width: 1),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
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
            _buildStatsRow(customers),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _buildList(customers),
            ),
          ],
        ),
        floatingActionButton: _buildFAB(),
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
                    hintText: 'Search by name, phone or email…',
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
                  color: _activeFilter != _FilterOption.all
                      ? AppColors.primary
                      : AppColors.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: _activeFilter != _FilterOption.all ? 0.35 : 0.08,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: _activeFilter != _FilterOption.all
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

  Widget _buildStatsRow(List<Customer> customers) {
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
              '${customers.length} '
              '${customers.length != 1 ? 'customers' : 'customer'}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_activeFilter != _FilterOption.all) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _activeFilter = _FilterOption.all);
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
          const Spacer(),
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

  Widget _buildList(List<Customer> customers) {
    if (customers.isEmpty) {
      return _EmptyState(isSearch: _searchQuery.isNotEmpty);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _CustomerCard(
          customer: customer,
          activeFilter: _activeFilter,
          onMeasurementAdded: _loadCustomers,
        );
      },
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
          if (result == true) {
            _loadCustomers();
          }
        },
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text(
          'New Customer',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

// ── Customer Card ─────────────────────────────────────────────────────────────
class _CustomerCard extends StatefulWidget {
  final Customer customer;
  final _FilterOption activeFilter;
  final VoidCallback onMeasurementAdded;

  const _CustomerCard({
    required this.customer,
    required this.activeFilter,
    required this.onMeasurementAdded,
  });

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _pressed = false;

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
      _avatarColors[widget.customer.name.codeUnitAt(0) % _avatarColors.length];

  String get _initials {
    final parts = widget.customer.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _deleteCustomer(Customer customer) async {
    try {
      // Delete customer from Firestore
      await FirebaseFirestore.instance
          .collection("customers")
          .doc(customer.id)
          .delete();
      
      // Also delete all measurements for this customer
      final measurementSnapshot = await FirebaseFirestore.instance
          .collection("measurements")
          .where("customer_id", isEqualTo: customer.id)
          .get();
      
      for (var doc in measurementSnapshot.docs) {
        await doc.reference.delete();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${customer.name} deleted successfully',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onMeasurementAdded(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Customer',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${customer.name}"? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
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
                colors: [Colors.red, Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteCustomer(customer);
              },
              child: const Text(
                'Delete',
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

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
      },
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
                    _buildAvatar(),
                    const SizedBox(width: 13),
                    Expanded(child: _buildInfo(customer)),
                    _buildRight(customer),
                  ],
                ),
              ),
              // Bottom section - Show "Add Measurement" button if no measurements
              if (!customer.hasMeasurements)
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
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      if (customer.note != null) ...[
                        Icon(
                          Icons.notes_rounded,
                          size: 13,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            customer.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        Expanded(child: Container()),
                      ],
                      // "Add Measurement" button
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMeasurementScreen(
                                customer: widget.customer,
                              ),
                            ),
                          );
                          if (result == true) {
                            widget.onMeasurementAdded();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.straighten_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add Measurement',
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 52,
      height: 52,
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
            fontSize: 17,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(Customer customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                customer.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (customer.hasMeasurements) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A9E5C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF1A9E5C).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 10,
                      color: Color(0xFF1A9E5C),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Measured',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A9E5C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        _buildInfoRow(icon: Icons.phone_outlined, text: customer.phone),
        if (customer.email != null) ...[
          const SizedBox(height: 3),
          _buildInfoRow(
            icon: Icons.alternate_email_rounded,
            text: customer.email!,
            truncate: true,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    bool truncate = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.neutral.withValues(alpha: 0.5)),
        const SizedBox(width: 5),
        truncate
            ? Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }

  Widget _buildRight(Customer customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatDate(customer.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Delete Button
        GestureDetector(
          onTap: () => _showDeleteDialog(customer),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.red.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
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
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  final _FilterOption current;
  final void Function(_FilterOption) onSelect;

  const _FilterSheet({required this.current, required this.onSelect});

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
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Choose how to view customers',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.neutral.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 14),
          ..._FilterOption.values.map(
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
  final _FilterOption option;
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
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.secondary,
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
                    : Icons.people_outline_rounded,
                size: 36,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? 'No results found' : 'No customers yet',
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
                  ? 'Try a different name, phone or email'
                  : 'Tap New Customer to add your first entry',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearch) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Use the button below to get started',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Filter Enum ───────────────────────────────────────────────────────────────
enum _FilterOption {
  all,
  nameAZ,
  measurements,
  noMeasurements;

  String get label => switch (this) {
    _FilterOption.all => 'All Customers',
    _FilterOption.nameAZ => 'Name A → Z',
    _FilterOption.measurements => 'Has Measurements',
    _FilterOption.noMeasurements => 'No Measurements',
  };

  String get description => switch (this) {
    _FilterOption.all => 'Show everyone in your directory',
    _FilterOption.nameAZ => 'Sort alphabetically by first name',
    _FilterOption.measurements => 'Only customers with measurements saved',
    _FilterOption.noMeasurements => 'Only customers without measurements saved',
  };

  IconData get icon => switch (this) {
    _FilterOption.all => Icons.people_outline_rounded,
    _FilterOption.nameAZ => Icons.sort_by_alpha_rounded,
    _FilterOption.measurements => Icons.straighten_rounded,
    _FilterOption.noMeasurements => Icons.cancel_rounded,
  };
}