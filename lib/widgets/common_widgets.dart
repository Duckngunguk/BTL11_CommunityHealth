import 'package:flutter/material.dart';

import '../models/models.dart';

// Hệ màu chung: trung tính, tiết chế và đủ tương phản cho sản phẩm y tế.
const primaryGreen = Color(0xFF0F766E);
const primaryDark = Color(0xFF0B625A);
const primaryLight = Color(0xFFE8F5F2);

const primaryBlue = Color(0xFF2563EB);
const blueLight = Color(0xFFEEF4FF);

const accentRed = Color(0xFFB42318);
const redLight = Color(0xFFFDF0EF);

const accentYellow = Color(0xFF9A5B13);
const yellowLight = Color(0xFFFFF7E8);

const gray900 = Color(0xFF172033);
const gray800 = Color(0xFF253148);
const gray700 = Color(0xFF3F4D63);
const gray600 = Color(0xFF5E6B7E);
const gray500 = Color(0xFF7B8798);
const gray400 = Color(0xFFA8B2C1);
const gray200 = Color(0xFFE3E8EF);
const gray100 = Color(0xFFF6F8FB);

// Legacy (backward compatibility)
const softGreen = primaryLight;
const pageBackground = gray100;

const appSurfaceShadow = BoxShadow(
  color: Color(0x0F172033),
  blurRadius: 24,
  offset: Offset(0, 8),
);

ThemeData buildCommunityHealthTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.light,
      surface: Colors.white,
      error: accentRed,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: pageBackground,
    colorScheme: base.colorScheme.copyWith(
      primary: primaryDark,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      onPrimaryContainer: primaryDark,
      secondary: primaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: blueLight,
      onSecondaryContainer: gray900,
      surface: Colors.white,
      onSurface: gray900,
      outline: gray200,
      error: accentRed,
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: const TextStyle(
        color: gray900,
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: const TextStyle(
        color: gray900,
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: const TextStyle(
        color: gray900,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: const TextStyle(
        color: gray900,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: const TextStyle(
        color: gray700,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        color: gray700,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: const TextStyle(
        color: gray500,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: gray200),
      ),
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: gray900,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: gray900,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: gray700, size: 22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentRed),
      ),
      prefixIconColor: gray500,
      suffixIconColor: gray500,
      hintStyle: const TextStyle(color: gray400, fontSize: 14),
      labelStyle: const TextStyle(color: gray600, fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: gray200,
        disabledForegroundColor: gray500,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: gray800,
        backgroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        side: const BorderSide(color: gray200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primaryLight,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? primaryDark : gray500,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? primaryDark : gray500,
          size: 22,
        );
      }),
    ),
    dividerTheme: const DividerThemeData(color: gray200, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: gray900,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44, this.compact = false});

  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: primaryDark,
            borderRadius: BorderRadius.circular(size * .28),
          ),
          child: Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: size * .55,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CommunityHealth',
                style: TextStyle(
                  color: gray900,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: gray200),
        boxShadow: shadow ? const [appSurfaceShadow] : null,
      ),
      child: child,
    );
  }
}

class AppPageWidth extends StatelessWidget {
  const AppPageWidth({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

// ============================================================
// SECTION LABEL — "TIÊU ĐỀ PHẦN"
// ============================================================
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: gray500,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06,
        ),
      ),
    );
  }
}

// ============================================================
// SECTION HEADER — tiêu đề có trailing widget
// ============================================================
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: gray500,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ============================================================
// STATUS PILL — tag màu trạng thái
// ============================================================
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final ChildVaccinationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      ChildVaccinationStatus.complete => (
          'Đã tiêm đủ',
          primaryDark,
          primaryLight,
        ),
      ChildVaccinationStatus.dueSoon => (
          'Sắp đến lịch',
          accentYellow,
          yellowLight,
        ),
      ChildVaccinationStatus.late => (
          'Trễ lịch',
          accentRed,
          redLight,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ============================================================
// CHILD CARD — thẻ hiển thị thông tin trẻ em
// ============================================================
class ChildCard extends StatelessWidget {
  const ChildCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  final ChildProfile child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color pillBg;
    Color pillFg;
    String pillText;

    if (child.lateDays > 0) {
      pillBg = redLight;
      pillFg = accentRed;
      pillText = 'Trễ ${child.lateDays} ngày';
    } else if (child.status == ChildVaccinationStatus.dueSoon) {
      pillBg = yellowLight;
      pillFg = accentYellow;
      pillText = 'Sắp lịch';
    } else {
      pillBg = primaryLight;
      pillFg = primaryDark;
      pillText = 'Đủ lịch';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: blueLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  child.fullName.characters.first,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${child.village} • ${child.nextVaccine} • Mẹ: ${child.motherName}',
                    style: const TextStyle(fontSize: 11.5, color: gray500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                pillText,
                style: TextStyle(
                  color: pillFg,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// APP CHIP — filter chip theo style HTML
// ============================================================
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.white,
          border: Border.all(color: selected ? primaryBlue : gray200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : gray700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STAT CARD — thẻ chỉ số
// ============================================================
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black87),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATE — trạng thái trống
// ============================================================
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: gray400),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: gray500),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TIMELINE ITEM — bản ghi tiêm/thuốc
// ============================================================
class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSynced,
  });

  final String title;
  final String subtitle;
  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: gray900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSynced ? primaryLight : yellowLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSynced ? 'Đã đồng bộ' : 'Chờ đồng bộ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSynced ? primaryDark : accentYellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(subtitle,
              style:
                  const TextStyle(color: gray500, fontSize: 11.5, height: 1.4)),
        ],
      ),
    );
  }
}
