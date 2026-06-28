import 'package:flutter/material.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String tailorName;
  final String shopName;
  final String? logoUrl;
  final Widget? logoWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? subtitleColor;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final double? toolbarHeight;
  final Gradient? gradient;
  final VoidCallback? onHeaderTap;
  final Widget? profileWidget;
  final VoidCallback? onProfileTap;
  final bool isSearchable;
  final Function(String)? onSearchChanged;
  final String? searchHint;
  final TextEditingController? searchController;
  final double logoSize;

  const AppHeader({
    super.key,
    required this.tailorName,
    required this.shopName,
    this.logoUrl,
    this.logoWidget,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.textColor,
    this.subtitleColor,
    this.elevation = 2,
    this.bottom,
    this.toolbarHeight = 80, // Increased height from default 56 to 80
    this.gradient,
    this.onHeaderTap,
    this.profileWidget,
    this.onProfileTap,
    this.isSearchable = false,
    this.onSearchChanged,
    this.searchHint = 'Search...',
    this.searchController,
    this.logoSize = 50, // Increased logo size
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveTextColor = textColor ?? AppColors.textPrimary;
    final effectiveSubtitleColor = subtitleColor ?? AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? effectiveBackgroundColor : null,
        gradient: gradient,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: elevation,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: AppBar(
        title: _buildTitle(theme, effectiveTextColor, effectiveSubtitleColor),
        leading: _buildLeading(context),
        actions: _buildActions(context, effectiveTextColor),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        bottom: bottom,
        toolbarHeight: toolbarHeight,
        automaticallyImplyLeading: false,
        flexibleSpace: gradient != null
            ? Container(
                decoration: BoxDecoration(gradient: gradient),
              )
            : null,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, Color textColor, Color subtitleColor) {
    return GestureDetector(
      onTap: onHeaderTap,
      child: Row(
        children: [
          // Logo Section
          _buildLogo(),
          const SizedBox(width: 15),
          
          // Text Section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tailorName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // Increased font size
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 14,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        shopName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: subtitleColor,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    if (logoWidget != null) {
      return SizedBox(
        width: logoSize,
        height: logoSize,
        child: logoWidget ?? Image.asset('lib/logo/logo.png',
          fit: BoxFit.contain, 
          errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
      },
      )
      );
    }

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: logoSize / 2,
        backgroundImage: NetworkImage(logoUrl!),
        onBackgroundImageError: (_, _) {},
        child: const Icon(Icons.circle, size: 20),
      );
    }

    // Default logo - Scissor icon for tailor
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(logoSize / 2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.circle,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        color: textColor,
        iconSize: 28,
      );
    }

    return null;
  }

  List<Widget>? _buildActions(BuildContext context, Color textColor) {
    final List<Widget> actionList = [];

    if (isSearchable) {
      actionList.add(
        SizedBox(
          width: 220,
          height: 45,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 14),
              prefixIcon: Icon(Icons.search, color: textColor, size: 22),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            ),
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
      );
    }

    if (profileWidget != null) {
      actionList.add(
        GestureDetector(
          onTap: onProfileTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: profileWidget,
          ),
        ),
      );
    }

    if (actions != null) {
      actionList.addAll(actions!);
    }

    return actionList.isEmpty ? null : actionList;
  }

  @override
  Size get preferredSize => Size.fromHeight(
      toolbarHeight! + (bottom?.preferredSize.height ?? 0));
}