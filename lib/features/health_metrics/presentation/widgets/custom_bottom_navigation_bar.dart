import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            isActive: activeTab == 'home',
            onTap: () => onTabSelected('home'),
          ),
          _NavItem(
            icon: Icons.favorite_border_rounded,
            isActive: activeTab == 'heart',
            onTap: () => onTabSelected('heart'),
          ),
          // Center Add Button
          GestureDetector(
            onTap: () => onTabSelected('add'),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEE374D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEE374D).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'serif',
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            isActive: activeTab == 'message',
            onTap: () => onTabSelected('message'),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            isActive: activeTab == 'settings',
            onTap: () => onTabSelected('settings'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isActive ? const Color(0xFFEE374D) : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}
