import 'package:flutter/material.dart';

/// Standard di certificazione gestiti dall'Audit Manager.
enum AuditStandard {
  sqnpi,
  bio;

  String get id => name;

  String get label {
    switch (this) {
      case AuditStandard.sqnpi:
        return 'SQNPI';
      case AuditStandard.bio:
        return 'BIO';
    }
  }

  String get fullName {
    switch (this) {
      case AuditStandard.sqnpi:
        return 'SQNPI - Produzione Integrata';
      case AuditStandard.bio:
        return 'BIO - Agricoltura Biologica';
    }
  }

  String get description {
    switch (this) {
      case AuditStandard.sqnpi:
        return 'Sistema di Qualità Nazionale Produzione Integrata';
      case AuditStandard.bio:
        return 'Regolamento UE 2018/848 e Normativa Biologica';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AuditStandard.sqnpi:
        return const Color(0xFF2D6A4F); // Verde bosco SQNPI
      case AuditStandard.bio:
        return const Color(0xFF1B5E20); // Verde organico BIO
    }
  }

  Color get accentColor {
    switch (this) {
      case AuditStandard.sqnpi:
        return const Color(0xFF52B788);
      case AuditStandard.bio:
        return const Color(0xFFE5A93B); // Oro/Terra calda per Bio
    }
  }

  Color get surfaceTint {
    switch (this) {
      case AuditStandard.sqnpi:
        return const Color(0xFFE8F5E9);
      case AuditStandard.bio:
        return const Color(0xFFF1F8E9);
    }
  }

  IconData get icon {
    switch (this) {
      case AuditStandard.sqnpi:
        return Icons.eco;
      case AuditStandard.bio:
        return Icons.spa;
    }
  }

  static AuditStandard fromString(
    String? val, {
    AuditStandard fallback = AuditStandard.sqnpi,
  }) {
    if (val == null) return fallback;
    final clean = val.trim().toLowerCase();
    if (clean == 'bio' || clean == 'biologico') return AuditStandard.bio;
    return AuditStandard.sqnpi;
  }
}
