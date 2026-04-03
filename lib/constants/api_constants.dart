class ApiConstants {
  // IMPORTANT: These are static credentials that don't change frequently
  static const String apiKey = "NdcoPXBK";
  static const String clientIP = "172.16.52.194";

  // JWT token is now fetched dynamically from Firebase
  // Use AngelOneService.getJwtToken() to get the current token
  static const String? jwtToken =
      null; // Deprecated - use AngelOneService instead
}
