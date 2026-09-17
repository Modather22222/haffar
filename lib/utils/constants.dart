/// Application-wide constants (colors, spacing, font sizes from Stitch design system)
abstract class AppConstants {
  AppConstants._();

  // ── Spacing (4px base unit) ─────────────────────────────────────────────
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const gutter = 16.0;
  static const marginMobile = 20.0;

  // ── Border Radius ───────────────────────────────────────────────────────
  static const radiusSm = 4.0;
  static const radiusMd = 8.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;
  static const radiusFull = 9999.0;

  // ── Typography Sizes (matching Stitch) ──────────────────────────────────
  static const displayLgFontSize = 32.0;
  static const headlineMdFontSize = 24.0;
  static const bodyLgFontSize = 18.0;
  static const bodyMdFontSize = 16.0;
  static const labelBoldFontSize = 14.0;

  // ── Button ──────────────────────────────────────────────────────────────
  static const buttonMinHeight = 52.0;
  static const buttonRadius = 16.0;
  static const buttonExtrusion = 4.0;
  static const buttonPressOffset = 2.0;

  // ── Lesson Path ─────────────────────────────────────────────────────────
  static const nodeSize = 56.0;
  static const currentNodeRingWidth = 4.0;
}
