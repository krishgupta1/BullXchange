import 'dart:convert';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:bullxchange/api/angel_one_api_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class AngelOneOptionChainService {
  final AngelOneApiService _apiService = AngelOneApiService();
  static List<Instrument>? _cachedInstruments;

  // ---------------------------------------------------------------------------
  // ✅ NEW METHOD: Load Instruments from JSON File
  // ---------------------------------------------------------------------------
  static Future<List<Instrument>> loadInstrumentsFromJson() async {
    if (_cachedInstruments != null) {
      return _cachedInstruments!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/OpenAPIScripMaster.json',
      );
      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      _cachedInstruments = data
          .map((item) => Instrument.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedInstruments!;
    } catch (e) {
      AppLog.e("❌ Failed to load instruments from JSON: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ UPDATED METHOD: Fetch Option Chain Data with JSON Fallback
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchOptionChainData({
    required String symbol,
    String expiryDate = '',
  }) async {
    try {
      AppLog.i("🔄 Fetching option chain data for $symbol");

      // First try to get current expiry date if not provided
      if (expiryDate.isEmpty) {
        final currentExpiry = await getCurrentExpiryDate(symbol);
        if (currentExpiry != null) {
          return await fetchOptionChainData(
            symbol: symbol,
            expiryDate: currentExpiry,
          );
        }
      }

      // Try API call first
      final apiData = await _fetchOptionChainFromApi(symbol, expiryDate);
      if (apiData.isNotEmpty) {
        AppLog.i("✅ Successfully fetched option chain from API");
        return apiData;
      }

      // Fallback to JSON data
      AppLog.w("⚠️ API failed, falling back to JSON data");
      return await _fetchOptionChainFromJson(symbol, expiryDate);
    } catch (e) {
      AppLog.e("❌ Error fetching option chain data: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ NEW METHOD: Fetch Option Chain from Angel One API
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchOptionChainFromApi(
    String symbol,
    String expiryDate,
  ) async {
    try {
      // Find the symbol token for the given symbol
      final instruments = await loadInstrumentsFromJson();
      final symbolInstrument = instruments.firstWhere(
        (inst) =>
            inst.symbol.toUpperCase() == symbol.toUpperCase() ||
            inst.name.toUpperCase() == symbol.toUpperCase(),
        orElse: () => Instrument.fromJson({}),
      );

      if (symbolInstrument.token.isEmpty) {
        AppLog.w("⚠️ Symbol token not found for $symbol");
        return [];
      }

      // Prepare the request payload
      final Map<String, List<String>> tokensByExchange = {
        symbolInstrument.exchSeg: [symbolInstrument.token],
      };

      // Fetch live data
      final liveData = await _apiService.fetchLiveMarketData(tokensByExchange);

      if (liveData.isEmpty) {
        AppLog.w("⚠️ No live data received for $symbol");
        return [];
      }

      // Process the live data into option chain format
      return _processLiveDataToOptionChain(liveData, symbol, expiryDate);
    } catch (e) {
      AppLog.e("❌ Error in API option chain fetch: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ NEW METHOD: Fetch Option Chain from JSON Data
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchOptionChainFromJson(
    String symbol,
    String expiryDate,
  ) async {
    try {
      final instruments = await loadInstrumentsFromJson();
      AppLog.i("📊 Loaded ${instruments.length} total instruments from JSON");

      final symbolUpper = symbol.toUpperCase();
      final symbolName = symbolUpper == "NIFTY 50" ? "NIFTY" : symbolUpper;

      // Filter for symbol's options
      final symbolOptions = instruments.where((inst) {
        final name = inst.name.toUpperCase();

        AppLog.d(
          "🔍 Checking instrument: ${inst.name} against symbol: $symbolName",
        );

        // Match options for given symbol
        return name.contains(symbolName) &&
            (name.contains('CE') || name.contains('PE')) &&
            inst.exchSeg == 'NFO';
      }).toList();

      AppLog.i(
        "🎯 Found ${symbolOptions.length} option instruments for $symbolName",
      );

      // Group by strike price
      final Map<double, Map<String, Instrument>> strikeGroups = {};

      for (final option in symbolOptions) {
        final nameParts = option.name.split(' ');
        if (nameParts.length >= 3) {
          final strikePriceStr = nameParts[nameParts.length - 2];
          final strikePrice = double.tryParse(strikePriceStr);

          if (strikePrice != null) {
            final optionType = nameParts.contains('CE') ? 'CE' : 'PE';

            if (!strikeGroups.containsKey(strikePrice)) {
              strikeGroups[strikePrice] = {};
            }
            strikeGroups[strikePrice]![optionType] = option;
          }
        }
      }

      // Convert to option chain format
      final List<Map<String, dynamic>> optionChain = [];

      for (final strikePrice in strikeGroups.keys.toList()..sort()) {
        final group = strikeGroups[strikePrice]!;

        final row = <String, dynamic>{
          'strikePrice': strikePrice,
          'expiryDate': expiryDate.isEmpty
              ? _getDefaultExpiryDate()
              : expiryDate,
        };

        // Add CE data if available
        if (group.containsKey('CE')) {
          final ceInstrument = group['CE']!;
          row['CE'] = {
            'symbol': ceInstrument.symbol,
            'name': ceInstrument.name,
            'token': ceInstrument.token,
            'lastPrice': ceInstrument.liveData['ltp'] ?? 0.0,
            'openInterest': ceInstrument.liveData['openInterest'] ?? 0,
            'change': ceInstrument.liveData['change'] ?? 0.0,
            'percentChange': ceInstrument.liveData['percentChange'] ?? 0.0,
            'volume': ceInstrument.liveData['totalTradedVolume'] ?? 0,
          };
        }

        // Add PE data if available
        if (group.containsKey('PE')) {
          final peInstrument = group['PE']!;
          row['PE'] = {
            'symbol': peInstrument.symbol,
            'name': peInstrument.name,
            'token': peInstrument.token,
            'lastPrice': peInstrument.liveData['ltp'] ?? 0.0,
            'openInterest': peInstrument.liveData['openInterest'] ?? 0,
            'change': peInstrument.liveData['change'] ?? 0.0,
            'percentChange': peInstrument.liveData['percentChange'] ?? 0.0,
            'volume': peInstrument.liveData['totalTradedVolume'] ?? 0,
          };
        }

        optionChain.add(row);
      }

      AppLog.i(
        "✅ Generated option chain from JSON: ${optionChain.length} strikes",
      );
      return optionChain;
    } catch (e) {
      AppLog.e("❌ Error in JSON option chain generation: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ HELPER METHODS
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> _processLiveDataToOptionChain(
    List<dynamic> liveData,
    String symbol,
    String expiryDate,
  ) {
    // Angel One API returns live data for the symbol, not option chain data
    // We need to fall back to JSON data for option chain
    AppLog.w(
      "⚠️ Angel One API doesn't provide option chain data directly, falling back to JSON",
    );
    return [];
  }

  Future<String?> getCurrentExpiryDate(String symbol) async {
    try {
      // For now, return current month's last Thursday
      final now = DateTime.now();
      final lastThursday = _getLastThursdayOfMonth(now.year, now.month);
      return DateFormat('yyyy-MM-dd').format(lastThursday);
    } catch (e) {
      AppLog.e("❌ Error getting current expiry date: $e");
      return null;
    }
  }

  DateTime _getLastThursdayOfMonth(int year, int month) {
    DateTime lastDay = DateTime(year, month + 1, 0);

    // Find the last Thursday
    while (lastDay.weekday != DateTime.thursday) {
      lastDay = lastDay.subtract(const Duration(days: 1));
    }

    return lastDay;
  }

  String _getDefaultExpiryDate() {
    final now = DateTime.now();
    final lastThursday = _getLastThursdayOfMonth(now.year, now.month);
    return DateFormat('yyyy-MM-dd').format(lastThursday);
  }
}
