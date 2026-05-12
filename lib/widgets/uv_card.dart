import 'package:flutter/material.dart';

import '../models/uv.dart';

class UvCard extends StatelessWidget {
  final UvIndex? uvIndex;
  final bool isLoading;
  final String? error;

  const UvCard({
    required this.uvIndex,
    required this.isLoading,
    required this.error,
    super.key,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _getLevel(int uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Mid';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  String _getAdvice(int uv) {
    if (uv <= 2) return 'No protection needed.';
    if (uv <= 5) return 'Some protection required.';
    if (uv <= 7) return 'Protection essential.';
    if (uv <= 10) return 'Extra protection needed.';
    return 'Stay indoors if possible.';
  }

  // ── Shared card shell ────────────────────────────────────────────────────

  Widget _shell({required Widget child}) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── States ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return _shell(
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return _shell(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE24B4A), size: 24),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return _shell(
      child: const Center(
        child: Text(
          'UV data\nnot available',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  // ── Main card ────────────────────────────────────────────────────────────

  Widget _buildCard(UvIndex uv) {
    final uvValue = uv.max.toInt().clamp(0, 11);
    final level = _getLevel(uvValue);
    final advice = _getAdvice(uvValue);

    return _shell(
      child: Padding(
        padding: const EdgeInsets.only(left: 11, top: 8, right: 6, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Label ───────────────────────────────
            const Text(
              'UV INDEX',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1.5,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 4),

            // ── Value + Level ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$uvValue',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 48,
                    height: 1.0,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    level,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      height: 1.56,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Gradient bar + indicator ─────────────
            LayoutBuilder(
              builder: (context, constraints) {
                const double barWidth = 119;
                const double indicatorSize = 14;
                final double indicatorLeft =
                    ((uvValue / 11) * (barWidth - indicatorSize))
                        .clamp(0.0, barWidth - indicatorSize);

                return SizedBox(
                  width: barWidth,
                  height: indicatorSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gradient bar
                      Positioned(
                        top: (indicatorSize - 3) / 2,
                        left: 0,
                        width: barWidth,
                        child: Container(
                          height:8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2A1AD8),
                                Color(0xFF4E26E2),
                                Color(0xFF7231EC),
                                Color(0xFF953DF5),
                                Color(0xFFAB4DFA),
                                Color(0xFFE552FF),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Indicator dot
                      Positioned(
                        left: indicatorLeft,
                        top: 0,
                        child: Container(
                          width: indicatorSize,
                          height: indicatorSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFC3C3C3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 1.2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 6),

            // ── Advice text ──────────────────────────
            Text(
              advice,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (error != null) return _buildError(error!);
    if (uvIndex == null) return _buildEmpty();
    return _buildCard(uvIndex!);
  }
}