import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/exercise_template.dart';

/// Resolves an illustration URL for a free-text exercise name by matching it
/// against the bundled exercise catalog. Used to backfill images onto programs
/// whose exercises were authored (in the seed JSON) without an [imageUrl].
///
/// Matching is intentionally conservative: it only returns a URL when the name
/// matches a catalog entry exactly (token-wise), or when a catalog entry's full
/// name is contained within the exercise name (e.g. "Squat (barbell / goblet)"
/// -> "Barbell Squat"). This avoids attaching a misleading image to an exercise
/// that has no real match; unmatched names keep the placeholder illustration.
class ExerciseImageResolver {
  /// Canonical token-key ("bench press") -> image URL, for exact matches.
  final Map<String, String> _exact;

  /// Catalog entries with >= 2 tokens, used for "name contains catalog entry"
  /// (subset) matches. Kept sorted longest-first so the most specific entry
  /// wins.
  final List<_Entry> _subset;

  ExerciseImageResolver._(this._exact, this._subset);

  /// Loads and indexes the catalog from assets. Cheap enough to call once at
  /// startup.
  static Future<ExerciseImageResolver> load() async {
    final raw = await rootBundle.loadString('assets/exercise_library.json');
    final templates = (jsonDecode(raw) as List).map((e) =>
        ExerciseTemplate.fromJson(Map<String, dynamic>.from(e as Map)));

    final exact = <String, String>{};
    final subset = <_Entry>[];
    for (final t in templates) {
      final url = t.imageUrl;
      if (url == null) continue;
      final tokens = _tokens(t.name);
      if (tokens.isEmpty) continue;
      exact.putIfAbsent(_key(tokens), () => url);
      if (tokens.length >= 2) subset.add(_Entry(tokens, url));
    }
    // Longest (most specific) entries first.
    subset.sort((a, b) => b.tokens.length.compareTo(a.tokens.length));
    return ExerciseImageResolver._(exact, subset);
  }

  /// The best illustration URL for [name], or null when no confident match.
  String? resolve(String name) {
    final query = _tokens(_clean(name));
    if (query.isEmpty) return null;

    final exact = _exact[_key(query)];
    if (exact != null) return exact;

    final querySet = query.toSet();
    for (final e in _subset) {
      // _subset is longest-first, so the first fully-contained entry is the
      // most specific match.
      if (querySet.containsAll(e.tokens)) return e.url;
    }
    return null;
  }

  /// Reduces a name to lowercase alphanumeric tokens, treating every separator
  /// (including hyphens) as a boundary so "Pull-Up", "Pull Up" and "pull up"
  /// tokenize identically.
  static List<String> _tokens(String s) {
    final normalized = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    return normalized.split(' ').where((t) => t.isNotEmpty).toList();
  }

  /// Order-independent key for exact matching.
  static String _key(List<String> tokens) {
    final sorted = [...tokens]..sort();
    return sorted.join(' ');
  }

  /// Strips qualifiers that the catalog never contains: keeps only the first
  /// variant of a combo ("A + B", "A / B", "A & B", "A veya B") and drops any
  /// parenthetical note.
  static String _clean(String s) {
    var out = s;
    for (final sep in const ['/', '+', '&', ' veya ']) {
      final i = out.indexOf(sep);
      if (i >= 0) out = out.substring(0, i);
    }
    return out.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  }
}

class _Entry {
  final List<String> tokens;
  final String url;
  _Entry(this.tokens, this.url);
}
