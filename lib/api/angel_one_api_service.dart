import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class AngelOneApiService {
  // 2. Create a Dio instance for network requests
  final Dio _dio = Dio();

  Future<List<dynamic>> fetchLiveMarketData(
    Map<String, List<String>> tokensByExchange,
  ) async {
    if (tokensByExchange.isEmpty) {
      return [];
    }
    try {
      final url =
          "https://apiconnect.angelone.in/rest/secure/angelbroking/market/v1/quote/";

      // Note: In Dio, headers are passed via an `Options` object.
      final options = Options(
        headers: {
          "Authorization": "Bearer ${ApiConstants.jwtToken}",
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-UserType": "USER",
          "X-SourceID": "WEB",
          "X-ClientLocalIP": ApiConstants.clientIP,
          "X-ClientPublicIP": ApiConstants.clientIP,
          "X-MACAddress": "00:00:00:00:00:00",
          "X-PrivateKey": ApiConstants.apiKey,
        },
      );

      // The JSON body is passed to the `data` parameter.
      final data = {"mode": "FULL", "exchangeTokens": tokensByExchange};

      // 3. Make the POST request using dio
      final response = await _dio.post(url, data: data, options: options);

      // 4. Dio automatically decodes the JSON response body.
      // We access it directly via `response.data`.
      final decoded = response.data;

      if (response.statusCode == 200 &&
          decoded["status"] == true &&
          decoded["data"]?["fetched"] is List) {
        return decoded["data"]["fetched"] as List<dynamic>;
      } else {
        print("API Error: ${decoded['message'] ?? 'Unknown error'}");
        return [];
      }
    } on DioException catch (e) {
      // 5. Dio has a dedicated exception type for better error handling.
      print("Error in AngelOneApiService (Dio): ${e.message}");
      if (e.response != null) {
        print("Dio Response Error Data: ${e.response?.data}");
      }
      return [];
    } catch (e) {
      print("An unexpected error occurred: $e");
      return [];
    }
  }

  /// Fetch quote data for a single instrument using its exchange segment and token.
  /// Returns the first item from the fetched list or null if nothing returned.
  Future<Map<String, dynamic>?> fetchQuoteForInstrument(
    String exchSeg,
    String token,
  ) async {
    final result = await fetchLiveMarketData({
      exchSeg: [token],
    });
    if (result.isNotEmpty && result.first is Map<String, dynamic>) {
      return result.first as Map<String, dynamic>;
    }
    return null;
  }

  /// Attempt to fetch fundamentals/company data for the given tokens.
  /// This method is a safe probe: it posts to the same quote endpoint
  /// but requests mode = 'FUNDAMENTAL'. If Angel One supports this mode
  /// the response will be similar in shape and returned as a List.
  Future<List<dynamic>> fetchFundamentals(
    Map<String, List<String>> tokensByExchange,
  ) async {
    // fetchFundamentals was removed in the reverted state — keep signature for compatibility
    // but return empty to avoid breaking callers. If you need fundamentals later,
    // we should implement against the documented Angel One fundamentals endpoint.
    return [];
  }
}
