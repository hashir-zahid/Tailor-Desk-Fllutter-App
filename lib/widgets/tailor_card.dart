import 'package:flutter/material.dart';

class TailorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? subtitle;
  final bool isLoading;
  final IconData? avatarIcon;  
  final Widget? avatar;      

  const TailorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
    this.subtitle,
    this.isLoading = false,
    this.avatarIcon,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: color != null 
                ? [color!, color!.withValues(alpha: 0.8)] 
                : [const Color(0xFF1A2A4A), const Color(0xFF152238)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar Section
                    if (avatar != null)
                      avatar!
                    else if (avatarIcon != null)
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(
                          avatarIcon!,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}