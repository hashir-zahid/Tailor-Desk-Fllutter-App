import 'package:flutter/material.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class AppFooter extends StatefulWidget {
  final int currentIndex;
  final Function(int index) onTap;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  final List<_NavItem> _items = const [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: "Home",
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: "Customers",
    ),
    _NavItem(
      icon: Icons.add_rounded,
      activeIcon: Icons.add_rounded,
      label: "Add",
      isCenter: true,
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: "Orders",
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: "Account",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _items.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _scaleAnimations = _controllers
        .map(
          (c) => Tween<double>(begin: 1.0, end: 1.15).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOutBack),
          ),
        )
        .toList();

    _controllers[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(AppFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = widget.currentIndex == index;

              // Special FAB-style center button
              if (item.isCenter) {
                return Expanded(
                  child: MouseRegion(                      // 👈 added
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => widget.onTap(index),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _scaleAnimations[index],
                          builder: (context, child) => Transform.scale(
                            scale: _scaleAnimations[index].value,
                            child: child,
                          ),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.75),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Regular nav items
              return Expanded(
                child: MouseRegion(                        // 👈 added
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => widget.onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: _scaleAnimations[index],
                      builder: (context, child) => Transform.scale(
                        scale: _scaleAnimations[index].value,
                        child: child,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) => ScaleTransition(
                              scale: anim,
                              child: child,
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              key: ValueKey(isSelected),
                              size: 24,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFADB5BD),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFADB5BD),
                              letterSpacing: 0.2,
                            ),
                            child: Text(item.label),
                          ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            height: 3,
                            width: isSelected ? 20 : 0,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });
}