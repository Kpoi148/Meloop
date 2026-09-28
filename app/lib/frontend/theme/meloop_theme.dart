import 'package:flutter/material.dart';

import 'tokens/tempo_tokens.dart';

abstract final class MeloopTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: TempoColors.teal,
      onPrimary: TempoColors.white,
      secondary: TempoColors.yellow,
      onSecondary: TempoColors.ink,
      surface: TempoColors.paper,
      onSurface: TempoColors.ink,
      onSurfaceVariant: TempoColors.muted,
      outline: TempoColors.fieldBorder,
      outlineVariant: TempoColors.line,
      error: TempoColors.error,
      onError: TempoColors.white,
      errorContainer: TempoColors.errorSurface,
      onErrorContainer: TempoColors.error,
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(TempoRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: TempoType.fontFamily,
      scaffoldBackgroundColor: TempoColors.paper,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: const TextTheme(
        headlineLarge: TempoType.heading,
        headlineMedium: TempoType.section,
        titleLarge: TempoType.title,
        titleMedium: TempoType.label,
        bodyLarge: TempoType.body,
        bodyMedium: TempoType.body,
        bodySmall: TempoType.caption,
        labelLarge: TempoType.button,
        labelMedium: TempoType.label,
        labelSmall: TempoType.caption,
      ).apply(bodyColor: TempoColors.ink, displayColor: TempoColors.ink),
      iconTheme: const IconThemeData(
        color: TempoColors.ink,
        size: TempoSize.icon,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: TempoColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: border(TempoColors.fieldBorder),
        enabledBorder: border(TempoColors.fieldBorder),
        focusedBorder: border(TempoColors.teal, 2),
        errorBorder: border(TempoColors.error),
        focusedErrorBorder: border(TempoColors.error, 2),
        errorStyle: TempoType.caption.copyWith(color: TempoColors.error),
        hintStyle: TempoType.body.copyWith(color: TempoColors.muted),
      ),
      cardTheme: CardThemeData(
        color: TempoColors.fieldFill,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TempoRadius.card),
          side: const BorderSide(color: TempoColors.line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TempoColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TempoRadius.button),
        ),
      ),
      dividerTheme: const DividerThemeData(color: TempoColors.line),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TempoColors.teal,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: TempoColors.teal,
        selectionColor: TempoColors.selection,
        selectionHandleColor: TempoColors.teal,
      ),
    );
  }
}
