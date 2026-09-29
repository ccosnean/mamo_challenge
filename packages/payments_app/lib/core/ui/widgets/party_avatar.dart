import 'package:flutter/material.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';

/// Initials on a colour derived from [id], so the same person or business
/// always gets the same colour. No network images.
class PartyAvatar extends StatelessWidget {
  const PartyAvatar({
    required this.id,
    required this.name,
    this.size = 44,
    super.key,
  });

  final String id;
  final String name;
  final double size;

  static const List<(Color background, Color foreground)> _palette = [
    (Color(0xFFE8EDFF), Color(0xFF2F4BC7)),
    (Color(0xFFFFEBD9), Color(0xFF8F4300)),
    (Color(0xFFE2F5EC), Color(0xFF0B6B3A)),
    (Color(0xFFF3E8FF), Color(0xFF6B3FB0)),
    (Color(0xFFFFE4E8), Color(0xFFA1263E)),
    (Color(0xFFE0F4F7), Color(0xFF0B5E6B)),
  ];

  @override
  Widget build(BuildContext context) {
    final (background, foreground) =
        _palette[_stableHash(id) % _palette.length];
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(
          initials(name),
          style: AppText.label(foreground).copyWith(fontSize: size * 0.34),
        ),
      ),
    );
  }

  /// `Ahmed Khalil` → `AK`, `Haddad Consulting FZ-LLC` → `HF`, `Cher` → `CH`.
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    String first(String word) => String.fromCharCodes(word.runes.take(1));
    if (parts.length > 1) {
      return (first(parts.first) + first(parts.last)).toUpperCase();
    }
    return String.fromCharCodes(parts.first.runes.take(2)).toUpperCase();
  }

  /// FNV-1a: stable across runs and platforms, unlike `String.hashCode`.
  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
