import 'package:dio/dio.dart';
import 'package:bullxchange/utils/logger.dart';
import '../constants/api_constants.dart';

class AngelOneApiService {
  // 2. Create a Dio instance for network requests
  final Dio _dio = Dio();

  Future<List<dynamic>> fetchLiveMarketData(
    Map<String, List<String>> tokensByExchange,
  ) async {
    if (tokensByExchange.isEmpty) {
      AppLog.w("⚠️ No tokens provided for market data fetch");
      return [];
    }
    
    try {
      AppLog.i("🔄 Fetching live market data for tokens: $tokensByExchange");
      
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
      
      AppLog.d("📊 API Response Status: ${response.statusCode}");
      AppLog.d("📊 API Response Data: ${decoded.toString().substring(0, decoded.toString().length > 200 ? 200 : decoded.toString().length)}...");

      try {
        if (response.statusCode == 200 &&
            decoded["status"] == true &&
            decoded["data"]?["fetched"] is List) {
          final fetched = decoded["data"]["fetched"] as List<dynamic>;
          AppLog.i("✅ Successfully fetched ${fetched.length} market data items");
          return fetched;
        } else {
          final errorMsg = decoded['message'] ?? 'Unknown error';
          AppLog.e("❌ API Error: $errorMsg");
          AppLog.e("❌ Full Response: $decoded");
          return [];
        }
      } catch (e) {
        AppLog.e("❌ Network Error fetching market data: $e");
        AppLog.e("❌ Stack trace: ${StackTrace.current}");
        return [];
      }
    } catch (e) {
      AppLog.e("❌ Unexpected error in fetchLiveMarketData: $e");
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

  // -----------------------------------------------------------------
  // ✨ NEW METHOD ADDED AS REQUESTED ✨
  // -----------------------------------------------------------------

  /// Fetches historical candle data for a specific instrument.
  Future<List<dynamic>?> fetchCandleData({
    required String exchange,
    required String symbolToken,
    required String interval,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      // This is the Angel One API endpoint for historical data
      const String historicalDataUrl =
          "https://apiconnect.angelone.in/rest/secure/angelbroking/historical/v1/getCandleData";

      // Re-use the same headers, as they are required for all authenticated calls
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

      // This is the JSON payload the API expects for candle data
      final Map<String, dynamic> requestBody = {
        "exchange": exchange,
        "symboltoken": symbolToken,
        "interval": interval,
        "fromdate": fromDate,
        "todate": toDate,
      };

      AppLog.d(
        "🚀 Fetching candle data: $exchange $symbolToken ($fromDate to $toDate)",
      );

      // Make the POST request using dio
      final response = await _dio.post(
        historicalDataUrl,
        data: requestBody,
        options: options,
      );

      final decoded = response.data;

      // Check the response structure for candle data
      if (response.statusCode == 200 &&
          decoded["status"] == true &&
          decoded["data"] is List) {
        // The API returns a list of lists:
        // [ [timestamp, open, high, low, close, volume], ... ]
        return decoded["data"] as List<dynamic>;
      } else {
        AppLog.w(
          "Failed to fetch candle data: ${decoded['message'] ?? 'Unknown error'}",
        );
        return null;
      }
    } on DioException catch (e) {
      // Handle Dio-specific errors
      AppLog.e("Error in fetchCandleData (Dio): ${e.message}");
      if (e.response != null) {
        AppLog.d("Dio Response Error Data: ${e.response?.data}");
      }
      return null;
    } catch (e) {
      // Handle any other unexpected errors
      AppLog.e("An unexpected error occurred in fetchCandleData: $e");
      return null;
    }
  }
}
