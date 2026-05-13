import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Component1 extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const Component1({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  Widget _navItem({
    required int index,
    required String activeAsset,
    required String inactiveAsset,
    required String label,
  }) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            isActive ? activeAsset : inactiveAsset,
            width: 30,
            height: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.black87 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const baseHeight = 76.0;

    return Container(
      height: baseHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Main row of nav items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: _navItem(
                      index: 0,
                      activeAsset: 'assets/nav_assets/nav_home_active.svg',
                      inactiveAsset: 'assets/nav_assets/nav_home_inactive.svg',
                      label: 'Home',
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _navItem(
                      index: 1,
                      activeAsset: 'assets/nav_assets/nav_forecast_active.svg',
                      inactiveAsset: 'assets/nav_assets/nav_forecast_inactive.svg',
                      label: 'Forecast',
                    ),
                  ),
                ),

                // Reserve space for the center search button
                const SizedBox(width: 56),

                Expanded(
                  child: Center(
                    child: _navItem(
                      index: 3,
                      activeAsset: 'assets/nav_assets/nav_outlook_active.svg',
                      inactiveAsset: 'assets/nav_assets/nav_outlook_inactive.svg',
                      label: 'Outlook',
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _navItem(
                      index: 4,
                      activeAsset: 'assets/nav_assets/nav_settings_active.svg',
                      inactiveAsset: 'assets/nav_assets/nav_settings_inactive.svg',
                      label: 'Settings',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Center search FAB (lowered for alignment)
          Positioned(
            top: 6,
            child: GestureDetector(
              onTap: () => onItemTapped(2),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/nav_assets/nav_search.svg',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
