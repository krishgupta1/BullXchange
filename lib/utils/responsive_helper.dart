import 'package:flutter/material.dart';

class ResponsiveHelper {
  static late BoxConstraints _constraints;
  static late BuildContext _context;

  static void init(BuildContext context, BoxConstraints constraints) {
    _context = context;
    _constraints = constraints;
  }

  // Screen size getters
  static double get screenWidth => _constraints.maxWidth;
  static double get screenHeight => _constraints.maxHeight;
  
  // Breakpoint definitions
  static bool get isMobile => screenWidth < 600;
  static bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  static bool get isDesktop => screenWidth >= 1200;
  
  // Responsive scaling factors (optimized for modern mobile)
  static double get scaleFactor => isMobile ? 1.0 : isTablet ? 1.1 : 1.2; // More conservative scaling
  static double get widthScale => screenWidth / 375.0; // Base width (iPhone X/11 Pro)
  static double get heightScale => screenHeight / 812.0; // Base height (iPhone X/11 Pro)

  // Responsive spacing
  static double get horizontalPadding => _scaleSize(16.0);
  static double get verticalPadding => _scaleSize(16.0);
  static double get cardPadding => _scaleSize(20.0);
  static double get sectionSpacing => _scaleSize(24.0);
  static double get itemSpacing => _scaleSize(12.0);
  static double get smallSpacing => _scaleSize(8.0);
  static double get tinySpacing => _scaleSize(4.0);

  // Modern Mobile Font Sizes (Material Design 3 & iOS HIG compliant)
  static double get appBarFontSize => _scaleFontSize(28.0);      // Large Title
  static double get h1FontSize => _scaleFontSize(24.0);          // Headline 1
  static double get h2FontSize => _scaleFontSize(20.0);          // Headline 2
  static double get h3FontSize => _scaleFontSize(18.0);          // Headline 3
  static double get bodyFontSize => _scaleFontSize(16.0);        // Body Large
  static double get captionFontSize => _scaleFontSize(14.0);     // Body Medium
  static double get smallFontSize => _scaleFontSize(12.0);      // Body Small
  static double get tinyFontSize => _scaleFontSize(10.0);        // Label Small
  
  // Additional semantic font sizes for better hierarchy
  static double get displayFontSize => _scaleFontSize(32.0);     // Display
  static double get titleFontSize => _scaleFontSize(22.0);       // Title Large
  static double get subtitleFontSize => _scaleFontSize(16.0);    // Title Medium
  static double get labelFontSize => _scaleFontSize(14.0);      // Label Medium

  // Responsive dimensions
  static double get cardBorderRadius => _scaleSize(20.0);
  static double get buttonHeight => _scaleSize(48.0);
  static double get iconSize => _scaleSize(24.0);
  static double get avatarSize => _scaleSize(50.0);
  static double get listItemHeight => _scaleSize(72.0);

  // Helper methods
  static double _scaleSize(double size) {
    final scaled = size * widthScale;
    return scaled.clamp(size * 0.8, size * 1.5); // Limit scaling range
  }

  static double _scaleFontSize(double fontSize) {
    final scaled = fontSize * scaleFactor;
    // More conservative scaling for better readability
    return scaled.clamp(fontSize * 0.95, fontSize * 1.2); 
  }

  // Responsive layout builders
  static Widget buildResponsive({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  static int getColumns({int maxColumns = 2, double minItemWidth = 200}) {
    if (isMobile) return 1;
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final columns = (availableWidth / minItemWidth).floor();
    return columns.clamp(1, maxColumns);
  }

  // Safe area helpers
  static EdgeInsets get safePadding => MediaQuery.of(_context).padding;
  static double get bottomNavHeight => MediaQuery.of(_context).padding.bottom + 60;
  static double get topSafeArea => MediaQuery.of(_context).padding.top;
}

// Extension methods for easier usage
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  
  // Responsive sizing
  double responsiveHeight(double height) => height * ResponsiveHelper.heightScale;
  double responsiveWidth(double width) => width * ResponsiveHelper.widthScale;
  
  // Responsive font sizing
  TextStyle responsiveText(TextStyle style) {
    return style.copyWith(
      fontSize: ResponsiveHelper._scaleFontSize(style.fontSize ?? 14),
    );
  }
}
