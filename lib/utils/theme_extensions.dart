import 'package:flutter/material.dart';

/// Extension methods for consistent typography access across the app.
/// Provides easy access to theme text styles with proper context.
///
/// Usage:
///   context.heading1('Title')
///   context.heading2('Subtitle')
///   context.bodyText('Description')

extension ThemeExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Heading 1 (18px, bold)
  TextStyle get heading1 => textTheme.headlineSmall ?? const TextStyle();

  // Heading 2 (16px, semi-bold)
  TextStyle get heading2 => textTheme.titleLarge ?? const TextStyle();

  // Body text (14px)
  TextStyle get bodyText => textTheme.bodyLarge ?? const TextStyle();

  // Body small (12px)
  TextStyle get bodySmallText => textTheme.bodyMedium ?? const TextStyle();

  // Caption (11px)
  TextStyle get caption => textTheme.bodySmall ?? const TextStyle();

  // Label (14px, bold)
  TextStyle get label => textTheme.labelLarge ?? const TextStyle();
}

/// Helper methods for quick text creation with consistent theming
extension TextHelpers on BuildContext {
  /// Create heading 1 text
  Widget heading1Text(
    String text, {
    TextAlign textAlign = TextAlign.start,
    int maxLines = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: heading1,
    );
  }

  /// Create heading 2 text
  Widget heading2Text(
    String text, {
    TextAlign textAlign = TextAlign.start,
    int maxLines = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: heading2,
    );
  }

  /// Create body text
  Widget bodyTextWidget(
    String text, {
    TextAlign textAlign = TextAlign.start,
    int maxLines = 10,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: bodyText,
    );
  }

  /// Create small body text
  Widget bodySmallTextWidget(
    String text, {
    TextAlign textAlign = TextAlign.start,
    int maxLines = 10,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: bodySmallText,
    );
  }

  /// Create caption text
  Widget captionText(
    String text, {
    TextAlign textAlign = TextAlign.start,
    int maxLines = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: caption,
    );
  }
}
