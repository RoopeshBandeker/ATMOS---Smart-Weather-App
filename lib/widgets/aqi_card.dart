import 'package:flutter/material.dart';

import '../models/air_quality.dart';

/// AQI Card — matches Figma node 194:427
/// White card · radius 24 · shadow 0px 4px 2px rgba(0,0,0,0.25)
/// "AQI" label · big value + category inline · gradient bar + dot
class AqiCard extends StatelessWidget {
  final AirQualityIndex? airQuality;
  final bool isLoading;
  final String? error;

  const AqiCard({
    required this.airQuality,
    required this.isLoading,
    required this.error,
    super.key,
  });

  int _displayValue(int aqi) {
    switch (aqi) {
      case 1: return 18;
      case 2: return 34;
      case 3: return 51;
      case 4: return 76;
      case 5: return 95;
      default: return 51;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Loading ───────────────────────────────────────────────
    if (isLoading) {
      return const _CardShell(
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // ── Error ─────────────────────────────────────────────────
    if (error != null) {
      return const _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AqiLabel(),
            SizedBox(height: 6),
            Text(
              'Unavailable',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    // ── No data ───────────────────────────────────────────────
    if (airQuality == null || airQuality!.aqi <= 0) {
      return const _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AqiLabel(),
            SizedBox(height: 6),
            Text(
              'No data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    // ── Main card ─────────────────────────────────────────────
    final aqi          = airQuality!;
    final displayValue = _displayValue(aqi.aqi);
    final category     = aqi.category;
    final progress     = (displayValue / 100).clamp(0.0, 1.0);

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "AQI" label
          const _AqiLabel(),

          const SizedBox(height: 4),

          // "51  Moderate"
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$displayValue',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 48,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Gradient bar + dot
          _GradientBarWithDot(progress: progress),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CARD SHELL — white · radius 24 · shadow 0px 4px 2px #00000040
// ─────────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  "AQI" LABEL — #94A3B8 · 10px · bold · uppercase
// ─────────────────────────────────────────────────────────────
class _AqiLabel extends StatelessWidget {
  const _AqiLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'AQI',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GRADIENT BAR WITH DOT — matches Figma node 195:433
//  Green→Yellow→Orange→Red · height 8 · radius 999 · white dot
// ─────────────────────────────────────────────────────────────
class _GradientBarWithDot extends StatelessWidget {
  final double progress; // 0.0 – 1.0

  const _GradientBarWithDot({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const double dotSize  = 14;
      final double barWidth = constraints.maxWidth;
      final double dotLeft  = ((barWidth - dotSize) * progress)
          .clamp(0.0, barWidth - dotSize);

      return SizedBox(
        height: dotSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Gradient bar
            Positioned(
              top: 3,
              left: 0,
              right: 0,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF34C759),
                      Color(0xFFFFD60A),
                      Color(0xFFFF9F0A),
                      Color(0xFFFF3B30),
                    ],
                  ),
                ),
              ),
            ),
            // White dot indicator
            Positioned(
              top: 0,
              left: dotLeft,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD1D5DB),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}