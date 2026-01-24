import 'package:intl/intl.dart';

class OptionCalculator {
  static final DateFormat _expiryDateFormat = DateFormat("ddMMMyyyy", "en_US");
  
  /// Calculate days remaining until expiry
  static int getDaysToExpiry(String expiryDate) {
    try {
      // Clean expiry date format
      String cleanDate = expiryDate.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      
      // Parse the expiry date
      DateTime expiry;
      if (cleanDate.length >= 9) {
        expiry = _expiryDateFormat.parseLoose(cleanDate);
      } else if (cleanDate.length >= 7) {
        String prefix = cleanDate.substring(0, 5);
        String suffix = cleanDate.substring(5);
        expiry = _expiryDateFormat.parseLoose("${prefix}20$suffix");
      } else {
        return 0;
      }
      
      // Calculate days difference
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
      
      return expiryDay.difference(today).inDays;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get expiry status text and color
  static ExpiryInfo getExpiryInfo(String expiryDate) {
    int days = getDaysToExpiry(expiryDate);
    
    String status;
    ExpiryUrgency urgency;
    
    if (days < 0) {
      status = "Expired";
      urgency = ExpiryUrgency.expired;
    } else if (days == 0) {
      status = "Expiry Today";
      urgency = ExpiryUrgency.today;
    } else if (days == 1) {
      status = "Tomorrow";
      urgency = ExpiryUrgency.urgent;
    } else if (days <= 7) {
      status = "$days days";
      urgency = ExpiryUrgency.warning;
    } else if (days <= 30) {
      status = "$days days";
      urgency = ExpiryUrgency.normal;
    } else {
      status = "$days days";
      urgency = ExpiryUrgency.safe;
    }
    
    return ExpiryInfo(
      daysRemaining: days,
      statusText: status,
      urgency: urgency,
    );
  }
  
  /// Calculate simple theta decay impact (estimated)
  static double calculateThetaImpact(double optionPremium, int daysToExpiry) {
    if (daysToExpiry <= 0) return 0.0;
    
    // Simple theta calculation: premium / daysToExpiry
    // This is a basic approximation - real theta depends on many factors
    return optionPremium / daysToExpiry;
  }
  
  /// Get time decay percentage
  static double getTimeDecayPercent(double optionPremium, int daysToExpiry) {
    if (daysToExpiry <= 0) return 100.0;
    
    double dailyDecay = calculateThetaImpact(optionPremium, daysToExpiry);
    return (dailyDecay / optionPremium) * 100;
  }
}

class ExpiryInfo {
  final int daysRemaining;
  final String statusText;
  final ExpiryUrgency urgency;
  
  ExpiryInfo({
    required this.daysRemaining,
    required this.statusText,
    required this.urgency,
  });
}

enum ExpiryUrgency {
  expired,    // Past expiry
  today,      // Expires today
  urgent,     // 1 day left
  warning,    // 2-7 days left
  normal,     // 8-30 days left
  safe,       // 30+ days left
}
