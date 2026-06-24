import 'package:flutter/material.dart';

/// Shared palette: a distinct, readable color per workout section (i.e. the
/// body-region / phase tag stored in an exercise's note). Kept in one place so
/// the same section looks identical everywhere — program cards, the editor
/// rows, and the section chips.
const sectionColors = <String, Color>{
  'Karın': Color(0xFFD81B60),
  'Isınma': Color(0xFFEF6C00),
  'Core': Color(0xFF8E24AA),
  'Direnç': Color(0xFF1565C0),
  'Kardiyo': Color(0xFF2E7D32),
  'Esneme': Color(0xFF00838F),
};

/// Color for [section]; falls back to a neutral slate for unknown/empty tags.
Color sectionColor(String? section) =>
    sectionColors[section] ?? const Color(0xFF546E7A);
