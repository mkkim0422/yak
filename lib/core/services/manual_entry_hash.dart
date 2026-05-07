import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../features/family/models/family_member.dart';

/// Stable identity hash for a user-entered supplement.
///
/// Two manual entries that describe the same product (same name, category,
/// schedule and dose) should land on the *same* hash regardless of which
/// user — or which device — created the entry. This is the join key the
/// Phase 4 backend will use to roll up community-submitted manuals into
/// "사용자 인증" candidates that can be promoted into the curated 250 DB.
///
/// Phase 1 (current ship): runs locally only. Each phone hashes its own
/// entries — there is no cross-user signal, no auto-promotion, no
/// "20명이 입력함" labels. The plumbing exists so Phase 4 can light it up
/// without any client-side migration.
///
/// TODO Phase 4 (backend integration):
///   1. POST hashes (anonymously, device-id keyed) to Supabase on save.
///   2. Backend keeps a counter per hash. When count crosses N (~20), the
///      operator gets a review queue entry; if approved, the manual is
///      ingested into the curated 250 DB and existing manuals stop showing
///      the "📝 직접" pill — they become "✅ 사용자 인증" instead.
///   3. Until then, render is unchanged (hash is computed but never sent).
String manualEntryHash(ManualProductEntry entry) {
  final normalizedName = _normalizeName(entry.name);
  final normalizedBrand = _normalizeName(entry.brand ?? '');
  final parts = <String>[
    normalizedName,
    normalizedBrand,
    entry.category.toLowerCase().trim(),
    entry.intakeTimingValue,
    entry.dosePerIntake.toString(),
    entry.intakesPerDay.toString(),
    entry.packageSize.toString(),
  ];
  final raw = parts.join('|');
  return sha1.convert(utf8.encode(raw)).toString();
}

/// Loose normalisation so "Now Foods Vitamin D3" and "now foods  vitamin d3"
/// hash equally. Lowercase + collapse whitespace; punctuation kept since
/// "비타민D3 5000" vs "비타민D3 1000" must remain distinct hashes.
String _normalizeName(String s) {
  return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Convenience: pass-through helper for callers that already have an
/// in-memory `ManualProductEntry` and want a one-liner. Kept separate so
/// future hash variants (Phase 4 may want sha256 + salt) can change in
/// one place.
String hashFor(ManualProductEntry entry) => manualEntryHash(entry);

extension on ManualProductEntry {
  String get intakeTimingValue => intakeTiming.name;
}
