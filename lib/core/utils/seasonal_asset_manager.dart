import 'dart:ui';

/// Enumeration of seasons based on astronomical dates.
enum Season { spring, summer, autumn, winter }

/// Enumeration of major holidays with high-priority assets.
enum Holiday { none, easter, christmas, newYear }

/// Type of particles to display in the header.
enum ParticleType { leaf, snowflake, sparkle, star, flower, christmasTree }

/// Data structure for seasonal and holiday configuration.
class SeasonalConfig {
  final String assetPath;
  final Color startColor;
  final Color endColor;
  final List<Color> particleColors;
  final String label;
  final ParticleType particleType;

  const SeasonalConfig({
    required this.assetPath,
    required this.startColor,
    required this.endColor,
    required this.particleColors,
    required this.label,
    required this.particleType,
  });
}

class SeasonalAssetManager {
  /// Evaluates the current date and returns the appropriate config.
  static SeasonalConfig getAssetConfig([DateTime? now]) {
    final date = now ?? DateTime.now();

    // 1. Check for Holidays first (High priority)
    final holiday = _getHoliday(date);
    if (holiday != Holiday.none) {
      return _getHolidayConfig(holiday);
    }

    // 2. Fallback to astronomical seasons
    final season = _getSeason(date);
    return _getSeasonConfig(season);
  }

  static Holiday _getHoliday(DateTime now) {
    final year = now.year;
    final easter = _calculateEaster(year);
    final easterMonday = easter.add(const Duration(days: 1));

    // Pasqua and Pasquetta
    if (now.year == easter.year &&
        now.month == easter.month &&
        now.day == easter.day) {
      return Holiday.easter;
    }
    if (now.year == easterMonday.year &&
        now.month == easterMonday.month &&
        now.day == easterMonday.day) {
      return Holiday.easter;
    }

    // Natale (24-26 Dicembre)
    if (now.month == 12 && (now.day >= 24 && now.day <= 26)) {
      return Holiday.christmas;
    }

    // Capodanno (31 Dicembre e 1 Gennaio)
    if ((now.month == 12 && now.day == 31) ||
        (now.month == 1 && now.day == 1)) {
      return Holiday.newYear;
    }

    return Holiday.none;
  }

  static Season _getSeason(DateTime now) {
    final month = now.month;
    final day = now.day;

    // Primavera (21 Marzo - 20 Giugno)
    if ((month == 3 && day >= 21) ||
        (month > 3 && month < 6) ||
        (month == 6 && day <= 20)) {
      return Season.spring;
    }
    // Estate (21 Giugno - 21 Settembre)
    if ((month == 6 && day >= 21) ||
        (month > 6 && month < 9) ||
        (month == 9 && day <= 21)) {
      return Season.summer;
    }
    // Autunno (22 Settembre - 20 Dicembre)
    if ((month == 9 && day >= 22) ||
        (month > 9 && month < 12) ||
        (month == 12 && day <= 20)) {
      return Season.autumn;
    }
    // Inverno (21 Dicembre - 20 Marzo)
    return Season.winter;
  }

  /// Algorithm of Meeus/Jones/Butcher for Gregorian Easter.
  static DateTime _calculateEaster(int year) {
    int a = year % 19;
    int b = year ~/ 100;
    int c = year % 100;
    int d = b ~/ 4;
    int e = b % 4;
    int f = (b + 8) ~/ 25;
    int g = (b - f + 1) ~/ 3;
    int h = (19 * a + b - d - g + 15) % 30;
    int i = c ~/ 4;
    int k = c % 4;
    int l = (32 + 2 * e + 2 * i - h - k) % 7;
    int m = (a + 11 * h + 22 * l) ~/ 451;
    int month = (h + l - 7 * m + 114) ~/ 31;
    int day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static SeasonalConfig _getHolidayConfig(Holiday holiday) {
    switch (holiday) {
      case Holiday.easter:
        return const SeasonalConfig(
          assetPath: 'assets/images/seasons/easter.png',
          startColor: Color(0xFFF59E0B), // Amber 600
          endColor: Color(0xFFD97706), // Amber 500
          particleColors: [
            Color(0xFFFEF3C7),
            Color(0xFFFDE68A),
            Color(0xFFFCD34D),
          ],
          label: 'BUONA PASQUA',
          particleType: ParticleType.flower,
        );
      case Holiday.christmas:
        return const SeasonalConfig(
          assetPath: 'assets/images/seasons/christmas.png',
          startColor: Color(0xFF991B1B), // Red 800
          endColor: Color(0xFFB91C1C), // Red 700
          particleColors: [
            Color(0xFFFECACA),
            Color(0xFFFCA5A5),
            Color(0xFFF87171),
          ],
          label: 'BUON NATALE',
          particleType: ParticleType.christmasTree,
        );
      case Holiday.newYear:
        return const SeasonalConfig(
          assetPath: 'assets/images/seasons/new_year.png',
          startColor: Color(0xFF1E293B), // Slate 800
          endColor: Color(0xFF334155), // Slate 700
          particleColors: [
            Color(0xFFFCD34D), // Gold
            Color(0xFFCBD5E1), // Silver
            Color(0xFFE2E8F0),
          ],
          label: 'BUON ANNO',
          particleType: ParticleType.sparkle,
        );
      default:
        return _getSeasonConfig(Season.spring);
    }
  }

  static SeasonalConfig _getSeasonConfig(Season season) {
    switch (season) {
      case Season.spring:
        return const SeasonalConfig(
          assetPath: 'assets/images/seasons/spring.png',
          startColor: Color(0xFF065F46), // Emerald 800
          endColor: Color(0xFF064E3B), // Emerald 900
          particleColors: [
            Color(0xFF10B981),
            Color(0xFF34D399),
            Color(0xFF6EE7B7),
            Color(0xFFA7F3D0),
          ],
          label: 'BUONGIORNO',
          particleType: ParticleType.flower,
        );
      case Season.summer:
        return const SeasonalConfig(
          assetPath: 'assets/images/seasons/summer.png',
          startColor: Color(0xFF0284C7), // Sky 600
          endColor: Color(0xFF075985), // Sky 800
          particleColors: [
            Color(0xFFBAE6FD),
            Color(0xFF7DD3FC),
            Color(0xFF38BDF8),
          ],
          label: 'BUONA ESTATE',
          particleType: ParticleType.flower,
        );
      case Season.autumn:
        return const SeasonalConfig(
          assetPath: 'assets/images/seasons/autumn.png',
          startColor: Color(0xFF78350F), // Brown 900
          endColor: Color(0xFF92400E), // Brown 800
          particleColors: [
            Color(0xFFD97706),
            Color(0xFFFFB347),
            Color(0xFFB45309),
          ],
          label: 'BUON AUTUNNO',
          particleType: ParticleType.leaf,
        );
      case Season.winter:
        return const SeasonalConfig(
          assetPath: 'assets/images/seasons/winter.png',
          startColor: Color(0xFF1E3A8A), // Blue 900
          endColor: Color(0xFF1E40AF), // Blue 800
          particleColors: [
            Color(0xFFBFDBFE),
            Color(0xFF93C5FD),
            Color(0xFF60A5FA),
          ],
          label: 'BUON INVERNO',
          particleType: ParticleType.snowflake,
        );
    }
  }
}
