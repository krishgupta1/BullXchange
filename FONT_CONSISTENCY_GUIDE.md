# Font Consistency Guide for BullXchange App

## Overview
This guide ensures consistent font usage throughout the BullXchange app using the established typography system.

## Font Hierarchy System

### 1. ResponsiveHelper Font Sizes (Primary System)
Use these for all responsive font sizing:

```dart
// Display & Hero
ResponsiveHelper.displayFontSize    // 32.0 - Large headings, splash screens
ResponsiveHelper.appBarFontSize     // 28.0 - App bar titles

// Headings
ResponsiveHelper.h1FontSize         // 24.0 - Page titles
ResponsiveHelper.h2FontSize         // 20.0 - Section headers  
ResponsiveHelper.h3FontSize         // 18.0 - Subsection headers

// Body & Content
ResponsiveHelper.bodyFontSize       // 16.0 - Main body text
ResponsiveHelper.captionFontSize    // 14.0 - Secondary text, labels
ResponsiveHelper.smallFontSize      // 12.0 - Small text, captions
ResponsiveHelper.tinyFontSize       // 10.0 - Minimal text, tags

// Special Sizes
ResponsiveHelper.titleFontSize      // 22.0 - Card titles
ResponsiveHelper.subtitleFontSize   // 16.0 - Subtitles
ResponsiveHelper.labelFontSize      // 14.0 - Form labels
```

### 2. Theme-Based Typography (Alternative System)
Use these when working with Material Design themes:

```dart
// Display Styles
Theme.of(context).textTheme.displayLarge   // 32.0
Theme.of(context).textTheme.displayMedium  // 28.0

// Headline Styles  
Theme.of(context).textTheme.headlineLarge   // 24.0
Theme.of(context).textTheme.headlineMedium  // 20.0
Theme.of(context).textTheme.headlineSmall   // 18.0

// Title Styles
Theme.of(context).textTheme.titleLarge     // 22.0
Theme.of(context).textTheme.titleMedium    // 16.0
Theme.of(context).textTheme.titleSmall     // 14.0

// Body Styles
Theme.of(context).textTheme.bodyLarge      // 16.0
Theme.of(context).textTheme.bodyMedium     // 14.0
Theme.of(context).textTheme.bodySmall      // 12.0

// Label Styles
Theme.of(context).textTheme.labelLarge     // 16.0
Theme.of(context).textTheme.labelMedium    // 14.0
Theme.of(context).textTheme.labelSmall     // 10.0
```

### 3. AppTypography Widgets (Recommended for Consistency)
Use these widget-based components for maximum consistency:

```dart
AppTypography.heading1(context, 'Main Title')        // 18px, bold
AppTypography.heading2(context, 'Section Title')     // 16px, semi-bold
AppTypography.bodyText(context, 'Regular text')     // 14px, normal
AppTypography.bodySmallText(context, 'Small text')  // 12px, normal
AppTypography.caption(context, 'Caption text')      // 11px, normal
AppTypography.label(context, 'Label text')          // 14px, bold
```

## Usage Guidelines

### When to Use Each Size

#### **Display (32px)**
- Splash screen main text
- Hero sections
- Large promotional banners
- Major statistics display

#### **AppBar (28px)**
- All app bar titles
- Main navigation headers

#### **H1 - Page Titles (24px)**
- Main page titles
- Important section headers
- Large card titles

#### **H2 - Section Headers (20px)**
- Section titles within pages
- Modal headers
- Important group headers

#### **H3 - Subsection Headers (18px)**
- Subsection titles
- Card titles
- List group headers

#### **Body - Main Content (16px)**
- Primary body text
- Descriptions
- Form input text
- Button text

#### **Caption - Secondary Text (14px)**
- Secondary descriptions
- Labels
- Supporting text
- Small button text

#### **Small - Minor Text (12px)**
- Captions
- Metadata
- Timestamps
- Small labels

#### **Tiny - Minimal Text (10px)**
- Tags
- Status indicators
- Fine print
- Minimal labels

## Font Weights

```dart
FontWeight.w100  // Thin
FontWeight.w200  // ExtraLight
FontWeight.w300  // Light
FontWeight.w400  // Normal (default)
FontWeight.w500  // Medium
FontWeight.w600  // SemiBold
FontWeight.w700  // Bold
FontWeight.w800  // ExtraBold
FontWeight.w900  // Black
```

### Weight Guidelines:
- **Display/H1**: FontWeight.bold (w700)
- **H2/H3**: FontWeight.w600 or FontWeight.w700
- **Body**: FontWeight.w500 or FontWeight.normal
- **Caption/Small**: FontWeight.normal
- **Tiny**: FontWeight.normal or FontWeight.w500

## Color Usage

Always use theme colors for text:

```dart
// Primary text
Theme.of(context).colorScheme.onSurface

// Secondary text
Theme.of(context).textTheme.bodySmall?.color

// Primary color text
Theme.of(context).colorScheme.primary

// Error text
Theme.of(context).colorScheme.error
```

## Common Patterns

### 1. Error States
```dart
Text(
  'Error message',
  style: TextStyle(
    fontSize: ResponsiveHelper.smallFontSize,
    color: Theme.of(context).colorScheme.error,
  ),
)
```

### 2. Success States
```dart
Text(
  'Success!',
  style: TextStyle(
    fontSize: ResponsiveHelper.captionFontSize,
    color: Colors.green,
    fontWeight: FontWeight.w600,
  ),
)
```

### 3. Disabled Text
```dart
Text(
  'Disabled',
  style: TextStyle(
    fontSize: ResponsiveHelper.captionFontSize,
    color: Theme.of(context).disabledColor,
  ),
)
```

## Migration Rules

### FROM Hardcoded Sizes → TO ResponsiveHelper

```dart
// OLD (Don't use)
TextStyle(fontSize: 14)

// NEW (Use this)
TextStyle(fontSize: ResponsiveHelper.captionFontSize)
```

### FROM Mixed Theme Usage → TO Consistent Theme

```dart
// OLD (Inconsistent)
TextStyle(color: Colors.black, fontSize: 16)

// NEW (Theme-aware)
TextStyle(
  color: Theme.of(context).colorScheme.onSurface,
  fontSize: ResponsiveHelper.bodyFontSize,
)
```

## Files Updated for Consistency

The following files have been updated to use the consistent font system:

1. **Portfolio Page** (`lib/features/portfolio/screens/portfolio_page.dart`)
   - Error state text sizes
   - All hardcoded sizes replaced with ResponsiveHelper

2. **Account Page** (`lib/features/account/screens/account_page.dart`)
   - Profile text sizes
   - Button text sizes
   - Card text sizes

3. **Order Details Page** (`lib/features/stock_market/screens/order_details_page.dart`)
   - Title and header sizes
   - Detail row text sizes
   - Status step text sizes

4. **Trade Action Buttons** (`lib/widgets/trade_action_buttons.dart`)
   - Button text sizes

5. **F&O P&L Card** (`lib/features/f&o/widgets/share_pnl_card.dart`)
   - All text sizes updated to responsive system

## Best Practices

1. **Always use ResponsiveHelper** for font sizes
2. **Prefer theme colors** over hardcoded colors
3. **Use AppTypography widgets** when possible for maximum consistency
4. **Test on different screen sizes** to ensure responsive scaling works
5. **Maintain visual hierarchy** - don't use same size for different importance levels
6. **Consider accessibility** - ensure text remains readable at all sizes

## Testing Checklist

- [ ] Text scales properly on mobile (< 600px)
- [ ] Text scales appropriately on tablet (600-1200px)  
- [ ] Text scales well on desktop (> 1200px)
- [ ] Font weights are consistent across similar elements
- [ ] Colors follow theme system
- [ ] No hardcoded font sizes remain
- [ ] Visual hierarchy is maintained

## Future Development

When adding new screens or components:

1. Import ResponsiveHelper: `import 'package:bullxchange/utils/responsive_helper.dart';`
2. Use appropriate font sizes from the hierarchy
3. Follow the color guidelines
4. Test on multiple screen sizes
5. Update this guide if new patterns emerge

---

**Remember**: Consistent typography creates a professional, polished user experience and makes the app feel cohesive and well-designed.
