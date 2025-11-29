import 'package:flutter/material.dart';

/// Professional reusable text widgets following the app's typography system.
/// Replaces repetitive TextStyle declarations throughout the app.
///
/// Usage:
///   AppTypography.heading1(context, 'My Title')
///   AppTypography.bodyText(context, 'Description')
///   AppTypography.caption(context, 'Caption text')

class AppTypography {
  // --- LARGE HEADINGS (H1) ---
  /// Main page heading (18px, bold)
  static Widget heading1(
    BuildContext context,
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
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  // --- SUBHEADINGS (H2) ---
  /// Section heading (16px, semi-bold)
  static Widget heading2(
    BuildContext context,
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
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  // --- BODY TEXT ---
  /// Regular body text (14px)
  static Widget bodyText(
    BuildContext context,
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
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  // --- SMALL BODY TEXT ---
  /// Smaller body text (12px)
  static Widget bodySmallText(
    BuildContext context,
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
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  // --- CAPTIONS ---
  /// Fine print / caption text (11px)
  static Widget caption(
    BuildContext context,
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
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  // --- LABELS ---
  /// Label text for form fields, buttons (14px, bold)
  static Widget label(
    BuildContext context,
    String text, {
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  // --- CUSTOM STYLED TEXT ---
  /// For cases where custom styling is needed beyond standard hierarchy
  static Widget customText(
    BuildContext context,
    String text, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign textAlign = TextAlign.start,
    int maxLines = 10,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'EudoxusSans',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
