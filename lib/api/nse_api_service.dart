import 'package:dio/dio.dart';
import 'package:bullxchange/utils/logger.dart';

class NseApiService {
  final Dio _dio = Dio();

  NseApiService() {
    _dio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      'Referer': 'https://www.nseindia.com/option-chain',
    };
  }

  /// Step 1: Warm-up request to NSE (to get cookies)
  Future<void> _warmUp() async {
    try {
      await _dio.get('https://www.nseindia.com/option-chain');
      AppLog.d('🔥 NSE warm-up successful.');
    } catch (e) {
      AppLog.w('⚠️ Warm-up failed (might still work): $e');
    }
  }

  /// Step 2: Actual Option Chain fetch
  Future<Map<String, dynamic>?> fetchOptionChain(String symbol) async {
    final url = 'https://www.nseindia.com/api/option-chain-indices?symbol=$symbol';

    try {
      await _warmUp(); // fetch cookies first

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        AppLog.i("✅ NSE Option Chain fetched for $symbol");
        return response.data as Map<String, dynamic>;
      }

      // Sometimes NSE returns HTML even with 200 status
      if (response.data is String) {
        AppLog.e("❌ NSE returned non-JSON data (blocked): ${response.data.toString().substring(0, 80)}...");
      }

      return null;
    } on DioException catch (e) {
      AppLog.e("💥 Dio error fetching NSE Option Chain: ${e.message}");
      if (e.response != null) {
        AppLog.d("Dio Response: ${e.response?.data}");
      }
      return null;
    } on FormatException catch (e) {
      AppLog.e("💥 FormatException parsing NSE Option Chain: ${e.message}");
      return null;
    } catch (e, st) {
      AppLog.e("💥 Unexpected Error in fetchOptionChain: $e\n$st");
      return null;
    }
  }
}
