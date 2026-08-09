import 'package:flutter/material.dart';

import '../models/models.dart';

// ============================================================
// COLOR SYSTEM — Theo thiết kế nhom10_CSE441_final.html
// ============================================================
const primaryGreen = Color(0xFF10B981);       // --primary
const primaryDark = Color(0xFF059669);         // --primary-dark
const primaryLight = Color(0xFFE6F4EA);        // --primary-light

const primaryBlue = Color(0xFF1A73E8);         // --blue (màu chính nav, buttons)
const blueLight = Color(0xFFE6F0FA);           // --blue-light

const accentRed = Color(0xFFC5221F);           // --red
const redLight = Color(0xFFFCE8E6);            // --red-light

const accentYellow = Color(0xFFB06000);        // --yellow
const yellowLight = Color(0xFFFEF7E0);         // --yellow-light

const gray900 = Color(0xFF0F172A);             // --gray-900
const gray800 = Color(0xFF1E293B);             // --gray-800
const gray700 = Color(0xFF334155);             // --gray-700
const gray600 = Color(0xFF4A5D6E);             // --gray-600
const gray500 = Color(0xFF7D8C9D);             // --gray-500
const gray400 = Color(0xFFA3B3C2);             // --gray-400
const gray200 = Color(0xFFE5EBF4);             // --gray-200
const gray100 = Color(0xFFF4F7FA);             // --gray-100

// Legacy (backward compatibility)
const softGreen = primaryLight;
const pageBackground = gray100;


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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
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
              color: Colors.black.withOpacity(0.02),
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
              decoration: BoxDecoration(
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: gray900),
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
          Text(subtitle, style: const TextStyle(color: gray500, fontSize: 11.5, height: 1.4)),
        ],
      ),
    );
  }
}
