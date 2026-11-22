// "Henna Night" design direction: dark-first aubergine with a henna-copper
// accent, Playfair Display italic for display text and Manrope for UI text.

import 'package:material_ui/material_ui.dart';

/// Extra colors the Material [ColorScheme] has no slot for.
@immutable
class DawatColors extends ThemeExtension<DawatColors> {
  const DawatColors({
    required this.card,
    required this.cardHigh,
    required this.outline,
    required this.muted,
    required this.glow,
    required this.heroTop,
    required this.heroBottom,
    required this.roseGold,
    required this.pillBg,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color card;
  final Color cardHigh;
  final Color outline;
  final Color muted;

  /// Copper glow used in hero areas.
  final Color glow;
  final Color heroTop;
  final Color heroBottom;
  final Color roseGold;
  final Color pillBg;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  static const dark = DawatColors(
    card: Color(0xFF2A1D2F),
    cardHigh: Color(0xFF33243A),
    outline: Color(0xFF3F2E44),
    muted: Color(0xFFB19FA8),
    glow: Color(0xFFD98E5F),
    heroTop: Color(0xFF2B1A30),
    heroBottom: Color(0xFF1C1220),
    roseGold: Color(0xFFF0B48C),
    pillBg: Color(0xFF3D2A2A),
    success: Color(0xFF86C9A6),
    warning: Color(0xFFE9BE5C),
    danger: Color(0xFFEF8A80),
    info: Color(0xFFA9B8F0),
  );

  static const light = DawatColors(
    card: Color(0xFFFFFFFF),
    cardHigh: Color(0xFFF6ECE7),
    outline: Color(0xFFE8D9D1),
    muted: Color(0xFF7D6A73),
    glow: Color(0xFFD98E5F),
    heroTop: Color(0xFF3A2440),
    heroBottom: Color(0xFF241729),
    roseGold: Color(0xFFA8572C),
    pillBg: Color(0xFFF8E6DA),
    success: Color(0xFF2E7D57),
    warning: Color(0xFF9A6A00),
    danger: Color(0xFFC0392B),
    info: Color(0xFF3F51B5),
  );

  @override
  DawatColors copyWith() => this;

  @override
  DawatColors lerp(ThemeExtension<DawatColors>? other, double t) {
    if (other is! DawatColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DawatColors(
      card: l(card, other.card),
      cardHigh: l(cardHigh, other.cardHigh),
      outline: l(outline, other.outline),
      muted: l(muted, other.muted),
      glow: l(glow, other.glow),
      heroTop: l(heroTop, other.heroTop),
      heroBottom: l(heroBottom, other.heroBottom),
      roseGold: l(roseGold, other.roseGold),
      pillBg: l(pillBg, other.pillBg),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      info: l(info, other.info),
    );
  }
}

extension DawatThemeX on BuildContext {
  DawatColors get colors => Theme.of(this).extension<DawatColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  static const display = 'PlayfairDisplay';
  static const body = 'Manrope';

  static const _henna = Color(0xFFD98E5F);
  static const _hennaDeep = Color(0xFFB8693C);

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    c: DawatColors.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _henna,
      onPrimary: Color(0xFF21130F),
      primaryContainer: Color(0xFF4A2E25),
      onPrimaryContainer: Color(0xFFFFDCC7),
      secondary: Color(0xFFF0B48C),
      onSecondary: Color(0xFF2B160C),
      surface: Color(0xFF1C1220),
      onSurface: Color(0xFFF5E9E1),
      onSurfaceVariant: Color(0xFFB19FA8),
      surfaceContainerLowest: Color(0xFF170F1A),
      surfaceContainerLow: Color(0xFF21162A),
      surfaceContainer: Color(0xFF2A1D2F),
      surfaceContainerHigh: Color(0xFF33243A),
      surfaceContainerHighest: Color(0xFF3B2B42),
      outline: Color(0xFF5A4660),
      outlineVariant: Color(0xFF3F2E44),
      error: Color(0xFFEF8A80),
      onError: Color(0xFF2B0A06),
    ),
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    c: DawatColors.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _hennaDeep,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFDCC7),
      onPrimaryContainer: Color(0xFF4A2410),
      secondary: Color(0xFF6B3F5C),
      onSecondary: Color(0xFFFFFFFF),
      surface: Color(0xFFFBF5F1),
      onSurface: Color(0xFF2A1A2C),
      onSurfaceVariant: Color(0xFF7D6A73),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFFFFFFF),
      surfaceContainer: Color(0xFFF6ECE7),
      surfaceContainerHigh: Color(0xFFF1E4DE),
      surfaceContainerHighest: Color(0xFFEADBD3),
      outline: Color(0xFFBFAAB2),
      outlineVariant: Color(0xFFE8D9D1),
      error: Color(0xFFC0392B),
      onError: Color(0xFFFFFFFF),
    ),
  );

  static ThemeData _build({required Brightness brightness, required DawatColors c, required ColorScheme scheme}) {
    final base = ThemeData(brightness: brightness, colorScheme: scheme, useMaterial3: true, fontFamily: body);
    final t = base.textTheme;
    TextStyle disp(TextStyle? s, double size, {FontStyle style = FontStyle.italic}) =>
        (s ?? const TextStyle()).copyWith(
          fontFamily: display,
          fontStyle: style,
          fontWeight: FontWeight.w500,
          fontSize: size,
          height: 1.15,
          fontFeatures: const [FontFeature.liningFigures()],
          color: scheme.onSurface,
        );
    final textTheme = t.copyWith(
      displayLarge: disp(t.displayLarge, 44),
      displayMedium: disp(t.displayMedium, 36),
      displaySmall: disp(t.displaySmall, 30),
      headlineLarge: disp(t.headlineLarge, 28),
      headlineMedium: disp(t.headlineMedium, 24),
      headlineSmall: disp(t.headlineSmall, 21, style: FontStyle.normal),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 19, letterSpacing: -0.2),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
      titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 15.5, height: 1.45),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: t.bodySmall?.copyWith(color: c.muted, height: 1.4),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      labelSmall: t.labelSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.6),
    );

    final radius = BorderRadius.circular(14);
    final outlineSide = BorderSide(color: c.outline);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontStyle: FontStyle.italic),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius, side: outlineSide),
      ),
      dividerTheme: DividerThemeData(color: c.outline, space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brightness == Brightness.dark ? c.roseGold : scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: radius, borderSide: outlineSide),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: outlineSide),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: TextStyle(color: c.muted),
        hintStyle: TextStyle(color: c.muted),
        prefixIconColor: c.muted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: scheme.primary,
        side: outlineSide,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 13, color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(fontSize: 13, color: scheme.onPrimary),
        checkmarkColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? scheme.primary : c.muted),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: body,
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? scheme.primary : c.muted,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.cardHigh,
        contentTextStyle: TextStyle(fontFamily: body, color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: c.outline),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : c.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primary : c.card),
        trackOutlineColor: WidgetStateProperty.all(c.outline),
      ),
      listTileTheme: ListTileThemeData(iconColor: c.muted),
    );
  }
}
