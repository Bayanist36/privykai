import 'package:flutter/material.dart';

import 'package:habit_tracker/core/utils/russian_plural.dart';

/// Builds the character counter under the habit name field.
///
/// The visible part stays in the design-mandated `length/limit` form while the
/// accessibility label reports the real remainder with correct Russian plural
/// forms. Flutter's own Russian localization returns "Остался 1 символ" for
/// every number ending in 1 (for example 31), which is BUG-12.
abstract final class NameCounter {
  static String label({required int currentLength, required int maxLength}) {
    final remaining = (maxLength - currentLength).clamp(0, maxLength);
    return RussianPlural.remainingCharacters(remaining);
  }

  static Widget build(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) {
    if (maxLength == null || maxLength <= 0) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: label(currentLength: currentLength, maxLength: maxLength),
      excludeSemantics: true,
      child: Text(
        '$currentLength/$maxLength',
        textAlign: TextAlign.end,
        style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
