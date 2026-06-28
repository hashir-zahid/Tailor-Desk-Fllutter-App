import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_desk_app/screens/account_screen.dart';
import 'package:tailor_desk_app/screens/add_customer_screen.dart';
import 'package:tailor_desk_app/screens/customers_screen.dart';
import 'package:tailor_desk_app/screens/orders_screen.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/widgets/app_header.dart';
import 'package:tailor_desk_app/widgets/tailor_card.dart';
import 'package:tailor_desk_app/widgets/recent_order_item.dart';
import 'package:tailor_desk_app/widgets/app_footer.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  
  const HomeScreen({
    super.key, 
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomeContent(),
    const CustomersScreen(),
    const AddCustomerScreen(),
    const OrdersScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onFooterTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE),
      appBar: _currentIndex == 0
          ? AppHeader(
              tailorName: TailorAuth.getTailorName() ?? "Tailor",
              shopName: TailorAuth.getShopName() ?? "Dev Tailor",
              actions: [],
            )
          : null,
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: _onFooterTap,
      ),
      body: _screens[_currentIndex],
    );
  }

}

// ── Home Content ──
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _totalCustomers = 0;
  int _pendingCustomers = 0;
  int _completedOrders = 0;
  int _totalOrders = 0;
  bool _isLoading = true;
  String? get _tailorId => TailorAuth.getCurrentTailorId();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (_tailorId == null) {
      if(mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if(mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Get all customers for this tailor
      final customersSnapshot = await FirebaseFirestore.instance
          .collection("customers")
          .where("tailor_id", isEqualTo: _tailorId)
          .get();

      // Get all measurements for this tailor
      final measurementsSnapshot = await FirebaseFirestore.instance
          .collection("measurements")
          .where("tailor_id", isEqualTo: _tailorId)
          .get();

      // Get distinct customers with pending orders (isCompleted == false)
      final pendingCustomerIds = measurementsSnapshot.docs
          .where((doc) => doc.data()['isCompleted'] == false)
          .map((doc) => doc.data()['customer_id'] as String)
          .toSet();

      final pendingCustomersCount = pendingCustomerIds.length;

      // Total customers
      final totalCustomers = customersSnapshot.docs.length;

      // Total orders (all measurements)
      final totalOrders = measurementsSnapshot.docs.length;

      // Completed orders (isCompleted = true)
      final completedOrders = measurementsSnapshot.docs
          .where((doc) => doc.data()['isCompleted'] == true)
          .length;

      if(mounted) {
        setState(() {
          _totalCustomers = totalCustomers;
          _pendingCustomers = pendingCustomersCount;
          _completedOrders = completedOrders;
          _totalOrders = totalOrders;
          _isLoading = false;
        });
      }

    } catch (e) {
      // ignore: avoid_print
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(context),
          const SizedBox(height: 20),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A2A4A)),
                )
              : _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildRecentOrdersSection(),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final String greeting = hour < 12
        ? "Good morning"
        : hour < 17
        ? "Good afternoon"
        : "Good evening";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$greeting, ${TailorAuth.getTailorName() ?? "Tailor"}",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2A4A),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        TailorCard(
          title: "Total Customers",
          value: "$_totalCustomers",
          icon: Icons.people_alt_outlined,
          color: const Color(0xFF1A2A4A),
          avatarIcon: Icons.people_alt,
          subtitle: "Total clients",
          onTap: () {
            // Navigate to Customers tab
            final homeScreen = context.findAncestorStateOfType<_HomeScreenState>();
            if (homeScreen != null) {
              homeScreen._onFooterTap(1);
            }
          },
        ),
        TailorCard(
          title: "Pending",
          value: "$_pendingCustomers",
          icon: Icons.schedule_outlined,
          color: const Color(0xFFE07B20),
          avatarIcon: Icons.schedule,
          subtitle: "Awaiting action",
          onTap: () {
            // Navigate to Orders tab
            final homeScreen = context.findAncestorStateOfType<_HomeScreenState>();
            if (homeScreen != null) {
              homeScreen._onFooterTap(3);
            }
          },
        ),
        TailorCard(
          title: "Completed",
          value: "$_completedOrders",
          icon: Icons.check_circle_outline,
          color: const Color(0xFF1E7A50),
          avatarIcon: Icons.check_circle,
          subtitle: "Orders done",
          onTap: () {
            // Navigate to Orders tab
            final homeScreen = context.findAncestorStateOfType<_HomeScreenState>();
            if (homeScreen != null) {
              homeScreen._onFooterTap(3);
            }
          },
        ),
        TailorCard(
          title: "Total Orders",
          value: "$_totalOrders",
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF1A5E72),
          avatarIcon: Icons.receipt_long,
          subtitle: "All measurements",
          onTap: () {
            // Navigate to Orders tab
            final homeScreen = context.findAncestorStateOfType<_HomeScreenState>();
            if (homeScreen != null) {
              homeScreen._onFooterTap(3);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Orders",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2A4A),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to Orders tab
                final homeScreen = context.findAncestorStateOfType<_HomeScreenState>();
                if (homeScreen != null) {
                  homeScreen._onFooterTap(3);
                }
              },
              child: const Text(
                "See all",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A5E72),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const RecentOrdersList(),
      ],
    );
  }
}