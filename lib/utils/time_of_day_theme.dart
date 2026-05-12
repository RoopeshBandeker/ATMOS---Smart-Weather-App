import 'package:flutter/material.dart';

enum AtmosTimePhase { morning, afternoon, night }

class SettingsPageTheme {
  final Color cardBackground;
  final Color selectedButton;
  final Color selectedButtonText;
  final Color unselectedButtonBackground;
  final Color unselectedButtonText;
  final Color titleText;

  const SettingsPageTheme({
    required this.cardBackground,
    required this.selectedButton,
    required this.selectedButtonText,
    required this.unselectedButtonBackground,
    required this.unselectedButtonText,
    required this.titleText,
  });
}

AtmosTimePhase getAtmosTimePhase(DateTime time) {
  final hour = time.hour;

  if (hour >= 19 || hour < 5) {
    return AtmosTimePhase.night;
  }

  if (hour >= 5 && hour < 12) {
    return AtmosTimePhase.morning;
  }

  return AtmosTimePhase.afternoon;
}

List<Color> getAtmosSkyGradient(DateTime time) {
  switch (getAtmosTimePhase(time)) {
    case AtmosTimePhase.night:
      return const [
        Color.fromARGB(255, 70, 31, 122),
        Color(0xFF957BDB),
        Color(0xFFDAD1F2),
        Color(0xFFFFFFFF),
      ];
    case AtmosTimePhase.morning:
      return const [
        Color(0xFF6EC6FF),
        Color(0xFFBFE9FF),
        Color(0xFFEAF7FF),
        Color(0xFFFFFFFF),
      ];
    case AtmosTimePhase.afternoon:
      return const [
        Color.fromARGB(255, 255, 162, 91),
        Color.fromARGB(255, 255, 195, 132),
        Color.fromARGB(255, 246, 215, 153),
        Color(0xFFFFFFFF),
      ];
  }
}

SettingsPageTheme getSettingsPageTheme(DateTime time) {
  switch (getAtmosTimePhase(time)) {
    case AtmosTimePhase.morning:
      return const SettingsPageTheme(
        cardBackground: Color(0xFFEEFCFF),
        selectedButton: Color(0xFF7CD5FF),
        selectedButtonText: Color(0xFFFFFFFF),
        unselectedButtonBackground: Color(0xFFFFFFFF),
        unselectedButtonText: Color(0xFF000000),
        titleText: Color(0xFF000000),
      );
    case AtmosTimePhase.afternoon:
      return const SettingsPageTheme(
        cardBackground: Color(0xFFFFFAEF),
        selectedButton: Color(0xFFFFAA58),
        selectedButtonText: Color(0xFFFFFFFF),
        unselectedButtonBackground: Color(0xFFFFFFFF),
        unselectedButtonText: Color(0xFF000000),
        titleText: Color(0xFF000000),
      );
    case AtmosTimePhase.night:
      return const SettingsPageTheme(
        cardBackground: Color(0xFFF4F0FF),
        selectedButton: Color(0xFFA38DE0),
        selectedButtonText: Color(0xFFFFFFFF),
        unselectedButtonBackground: Color(0xFFFFFFFF),
        unselectedButtonText: Color(0xFF000000),
        titleText: Color(0xFF000000),
      );
  }
}
