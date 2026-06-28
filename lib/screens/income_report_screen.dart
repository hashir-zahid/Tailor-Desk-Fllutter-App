// ignore_for_file: avoid_print, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class IncomeReportScreen extends StatefulWidget {
  const IncomeReportScreen({super.key});

  @override
  State<IncomeReportScreen> createState() => _IncomeReportScreenState();
}

class _IncomeReportScreenState extends State<IncomeReportScreen> {
  bool _isLoading = true;
  String? _tailorId;
  
  // Stats
  int _totalBilledOrders = 0;
  double _totalRevenue = 0.0;
  double _averageOrderValue = 0.0;
  double _highestOrder = 0.0;
  double _lowestOrder = 0.0;
  
  // Monthly breakdown
  Map<String, Map<String, dynamic>> _monthlyData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _tailorId = TailorAuth.getCurrentTailorId();
      
      if (_tailorId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get all measurements with isBill == true
      final snapshot = await FirebaseFirestore.instance
          .collection("measurements")
          .where("tailor_id", isEqualTo: _tailorId)
          .where("isBill", isEqualTo: true)
          .get();

      _totalBilledOrders = snapshot.docs.length;
      
      if (_totalBilledOrders > 0) {
        List<double> prices = [];
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final price = (data['price'] ?? 0).toDouble();
          prices.add(price);
          _totalRevenue += price;
          
          // Monthly breakdown
          final createdAt = data['created_at'] != null
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.now();
          
          final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          final monthName = '${_getMonthName(createdAt.month)} ${createdAt.year}';
          
          if (!_monthlyData.containsKey(monthKey)) {
            _monthlyData[monthKey] = {
              'monthName': monthName,
              'count': 0,
              'revenue': 0.0,
            };
          }
          
          _monthlyData[monthKey]!['count'] = _monthlyData[monthKey]!['count'] + 1;
          _monthlyData[monthKey]!['revenue'] = _monthlyData[monthKey]!['revenue'] + price;
        }
        
        // Calculate average, highest, lowest
        _averageOrderValue = _totalRevenue / _totalBilledOrders;
        _highestOrder = prices.reduce((a, b) => a > b ? a : b);
        _lowestOrder = prices.reduce((a, b) => a < b ? a : b);
        
        // Sort months descending
        final sortedKeys = _monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));
        final sortedMap = <String, Map<String, dynamic>>{};
        for (var key in sortedKeys) {
          sortedMap[key] = _monthlyData[key]!;
        }
        _monthlyData = sortedMap;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading income report: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatCurrency(double amount) {
    return 'Rs. ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1A1A2E),
        ),
        title: const Text(
          'Income Report',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
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
          : _totalBilledOrders == 0
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      _buildSummaryCards(),
                      const SizedBox(height: 20),
                      
                      // Monthly Breakdown
                      _buildMonthlyBreakdown(),
                      const SizedBox(height: 20),
                      
                      // Order Details
                      _buildOrderDetails(),
                    ],
                  ),
                ),
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
              'No Billed Orders',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Billed orders will appear here once you generate bills',
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

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _SummaryCard(
          title: 'Total Orders',
          value: '$_totalBilledOrders',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF1A6AE0),
        ),
        _SummaryCard(
          title: 'Total Revenue',
          value: _formatCurrency(_totalRevenue),
          icon: Icons.attach_money_rounded,
          color: const Color(0xFF1A9E5C),
        ),
        _SummaryCard(
          title: 'Average Order',
          value: _formatCurrency(_averageOrderValue),
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF7C3AED),
        ),
        _SummaryCard(
          title: 'Highest Order',
          value: _formatCurrency(_highestOrder),
          icon: Icons.arrow_upward_rounded,
          color: const Color(0xFFE07B20),
        ),
      ],
    );
  }

  Widget _buildMonthlyBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Monthly Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._monthlyData.entries.map((entry) {
            final data = entry.value;
            return _MonthlyTile(
              month: data['monthName'] ?? '',
              orders: data['count'] ?? 0,
              revenue: data['revenue'] ?? 0.0,
              totalRevenue: _totalRevenue,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Order Statistics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: 'Total Billed Orders',
            value: '$_totalBilledOrders',
            icon: Icons.receipt_long_rounded,
          ),
          _StatRow(
            label: 'Total Revenue',
            value: _formatCurrency(_totalRevenue),
            icon: Icons.attach_money_rounded,
            isHighlighted: true,
          ),
          _StatRow(
            label: 'Average Order Value',
            value: _formatCurrency(_averageOrderValue),
            icon: Icons.trending_up_rounded,
          ),
          _StatRow(
            label: 'Highest Order',
            value: _formatCurrency(_highestOrder),
            icon: Icons.arrow_upward_rounded,
          ),
          _StatRow(
            label: 'Lowest Order',
            value: _formatCurrency(_lowestOrder),
            icon: Icons.arrow_downward_rounded,
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly Tile ──────────────────────────────────────────────────────────────
class _MonthlyTile extends StatelessWidget {
  final String month;
  final int orders;
  final double revenue;
  final double totalRevenue;

  const _MonthlyTile({
    required this.month,
    required this.orders,
    required this.revenue,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  month,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$orders orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Rs. ${revenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 4,
              backgroundColor: AppColors.neutral.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Row ──────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlighted;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.neutral.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              color: isHighlighted ? const Color(0xFF1A9E5C) : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}