import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onExperimentTap;
  final VoidCallback? onAddTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    this.onHomeTap,
    this.onExperimentTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 75,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            icon: Icons.home_rounded,
            label: "Home",
            selected: currentIndex == 0,
            onTap: onHomeTap,
          ),

          const SizedBox(width: 50),

          _buildItem(
            icon: Icons.folder_rounded,
            label: "Experiments",
            selected: currentIndex == 1,
            onTap: onExperimentTap,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required bool selected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF2563EB)
                  : Colors.grey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? const Color(0xFF2563EB)
                    : Colors.grey,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}