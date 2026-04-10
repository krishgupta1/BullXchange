class ApiConstants {
  // These will be updated from Firestore on startup
  static String jwtToken = "";
  static String apiKey = "NdcoPXBK";
  static String clientIP = "172.16.52.194";
  
  // Additional fields from Firestore
  static String clientCode = "";
  static String clientPublicIP = "172.16.52.194";
  static String macAddress = "00:00:00:00:00:00";
  static String privateKey = "";
  static String sourceId = "WEB";

  static void updateFromFirestore(Map<String, dynamic> data) {
    if (data.containsKey('jwtToken')) jwtToken = data['jwtToken'];
    if (data.containsKey('apiKey')) apiKey = data['apiKey'];
    if (data.containsKey('clientLocalIP')) clientIP = data['clientLocalIP'];
    if (data.containsKey('clientPublicIP')) clientPublicIP = data['clientPublicIP'];
    if (data.containsKey('clientCode')) clientCode = data['clientCode'];
    if (data.containsKey('macAddress')) macAddress = data['macAddress'];
    if (data.containsKey('privateKey')) privateKey = data['privateKey'];
    if (data.containsKey('sourceId')) sourceId = data['sourceId'];
    
    // Fallback logic
    if (apiKey.isEmpty && privateKey.isNotEmpty) apiKey = privateKey;
  }
}

