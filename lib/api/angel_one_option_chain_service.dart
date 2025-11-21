import 'dart:convert';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:bullxchange/api/angel_one_api_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class AngelOneOptionChainService {
  // 1. Use your working API Service
  final AngelOneApiService _apiService = AngelOneApiService();

  // 2. Cache for the large JSON file
  static List<Instrument>? _cachedInstruments;

  // ---------------------------------------------------------------------------
  // 🛠 CONFIG: Map UI Names to Angel API Tokens
  // ---------------------------------------------------------------------------
  Map<String, String> _getSymbolConfig(String inputSymbol) {
    final s = inputSymbol.toUpperCase().trim();

    // 1. NIFTY 50
    if (s == "NIFTY 50" || s == "NIFTY") {
      return {
        "spotToken": "99926000", // NSE Token for Nifty 50
        "optionName": "NIFTY", // Name used in Option Scrip Master
      };
    }
    // 2. BANK NIFTY
    else if (s == "NIFTY BANK" || s == "BANKNIFTY" || s == "BANK NIFTY") {
      return {"spotToken": "99926009", "optionName": "BANKNIFTY"};
    }
    // 3. FIN NIFTY
    else if (s == "NIFTY FIN SERVICE" || s == "FINNIFTY" || s.contains("FIN")) {
      return {"spotToken": "99926037", "optionName": "FINNIFTY"};
    }

    // Fallback (Likely won't work for Indices without manual mapping)
    return {"spotToken": "", "optionName": s};
  }

  // ---------------------------------------------------------------------------
  // 🚀 MAIN FETCH METHOD
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchOptionChainData(String symbol) async {
    try {
      AppLog.i("🚀 [OptionChain] Fetching data for: $symbol");

      // 1. Get Configuration
      final config = _getSymbolConfig(symbol);
      final String spotToken = config['spotToken']!;
      final String optionName = config['optionName']!;

      if (spotToken.isEmpty) {
        AppLog.e(
          "❌ [OptionChain] Could not map symbol '$symbol' to a Spot Token.",
        );
        return null;
      }

      // 2. Load Master Data (Cached)
      final List<Instrument> allInstruments = await _getOrLoadScripMaster();
      if (allInstruments.isEmpty) {
        AppLog.e("❌ [OptionChain] Scrip Master is empty.");
        return null;
      }

      // 3. FETCH SPOT PRICE (With Debugging & Fallbacks)
      AppLog.i(
        "📡 [OptionChain] Requesting Spot Price for Token: $spotToken (NSE)",
      );

      // Request data from NSE exchange
      final List<dynamic> spotResponse = await _apiService.fetchLiveMarketData({
        "NSE": [spotToken],
      });

      AppLog.i("🔍 [OptionChain] Raw Spot Response: $spotResponse");

      double spotPrice = 0.0;

      if (spotResponse.isNotEmpty && spotResponse[0] is Map) {
        final item = spotResponse[0];

        // 🛡️ ROBUST PARSING: Try 'ltp' -> 'lastPrice' -> 'closePrice'
        final ltp = double.tryParse(item['ltp']?.toString() ?? "0") ?? 0.0;
        final lastPrice =
            double.tryParse(item['lastPrice']?.toString() ?? "0") ?? 0.0;
        final closePrice =
            double.tryParse(item['closePrice']?.toString() ?? "0") ?? 0.0;

        if (ltp > 0) {
          spotPrice = ltp;
        } else if (lastPrice > 0) {
          spotPrice = lastPrice;
          AppLog.w(
            "⚠️ [OptionChain] 'ltp' was 0, used 'lastPrice': $spotPrice",
          );
        } else if (closePrice > 0) {
          spotPrice = closePrice;
          AppLog.w(
            "⚠️ [OptionChain] 'ltp' was 0, used 'closePrice' (Market Closed?): $spotPrice",
          );
        }
      }

      if (spotPrice == 0.0) {
        AppLog.e(
          "❌ [OptionChain] Spot Price is 0.0. API returned valid data but no price found.",
        );
        return null;
      }
      AppLog.i("✅ [OptionChain] Final Spot Price for $optionName: $spotPrice");

      // 4. Filter Options from Master Data
      final List<Instrument> options = allInstruments.where((i) {
        return i.name == optionName &&
            i.instrumentType == "OPTIDX" &&
            i.exchSeg == "NFO";
      }).toList();

      if (options.isEmpty) {
        AppLog.e("❌ [OptionChain] No OPTIDX found for name: $optionName");
        return null;
      }

      // 5. Find Nearest Expiry
      final String? nearestExpiry = _findNearestExpiry(options);
      if (nearestExpiry == null) {
        AppLog.e("❌ [OptionChain] Could not find nearest expiry.");
        return null;
      }
      AppLog.i("🗓️ [OptionChain] Nearest Expiry: $nearestExpiry");

      // 6. Smart Filter: Range 3%
      final double range = spotPrice * 0.03;
      final double minStrike = spotPrice - range;
      final double maxStrike = spotPrice + range;

      final List<Instrument> targetOptions = options.where((i) {
        if (i.expiry != nearestExpiry) return false;
        double strike = double.tryParse(i.strike) ?? 0.0;
        // Angel One strike fix (sometimes stored as 1800000 instead of 18000)
        if (strike > 100000) strike = strike / 100;
        return strike >= minStrike && strike <= maxStrike;
      }).toList();

      if (targetOptions.isEmpty) {
        AppLog.e(
          "❌ [OptionChain] No options found within range ($minStrike - $maxStrike).",
        );
        return null;
      }

      // 7. Fetch Live Data for Options (Using NFO segment)
      final List<String> tokensToFetch = targetOptions
          .map((e) => e.token)
          .toList();

      final List<dynamic> liveDataList = await _apiService.fetchLiveMarketData({
        "NFO": tokensToFetch,
      });

      // Convert List to Map for easy lookup
      final Map<String, dynamic> liveDataMap = {};
      for (var item in liveDataList) {
        if (item is Map) {
          String t = item['symbolToken'] ?? item['token'] ?? "";
          if (t.isNotEmpty) liveDataMap[t] = item;
        }
      }

      // 8. Build Response
      return _buildOptionChainResponse(targetOptions, liveDataMap, spotPrice);
    } catch (e, st) {
      AppLog.e("❌ [OptionChain] Critical Error: $e\n$st");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🛠 HELPERS
  // ---------------------------------------------------------------------------

  Future<List<Instrument>> _getOrLoadScripMaster() async {
    if (_cachedInstruments != null && _cachedInstruments!.isNotEmpty) {
      return _cachedInstruments!;
    }
    try {
      final jsonString = await rootBundle.loadString(
        'assets/OpenAPIScripMaster.json',
      );
      final List<dynamic> data = jsonDecode(jsonString);
      _cachedInstruments = data.map((e) => Instrument.fromJson(e)).toList();
      return _cachedInstruments!;
    } catch (e) {
      AppLog.e("❌ Error loading Scrip Master: $e");
      return [];
    }
  }

  String? _findNearestExpiry(List<Instrument> options) {
    final Set<String> uniqueExpiries = options.map((e) => e.expiry).toSet();
    if (uniqueExpiries.isEmpty) return null;

    // Angel One format is usually "ddMMMyyyy" (e.g. 28NOV2024)
    final DateFormat angelFormat = DateFormat("ddMMMyyyy");
    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);

    final List<DateTime> dates = [];
    for (var exp in uniqueExpiries) {
      try {
        dates.add(angelFormat.parse(exp));
      } catch (_) {
        // Fallback for other formats if necessary
      }
    }
    dates.sort();

    for (var d in dates) {
      if (d.isAtSameMomentAs(todayDate) || d.isAfter(todayDate)) {
        return angelFormat.format(d).toUpperCase();
      }
    }
    return null;
  }

  Map<String, dynamic> _buildOptionChainResponse(
    List<Instrument> instruments,
    Map<String, dynamic> liveData,
    double spotPrice,
  ) {
    final Map<String, Map<String, dynamic>> rows = {};

    for (var inst in instruments) {
      double strike = double.tryParse(inst.strike) ?? 0.0;
      if (strike > 100000) strike = strike / 100;

      String strikeKey = strike.toStringAsFixed(2);
      final data = liveData[inst.token];

      // Map API keys to our UI keys
      final Map<String, dynamic> node = {
        'openInterest': data?['opnInterest'] ?? 0,
        'lastPrice': data?['ltp'] ?? 0.0,
        'change': data?['netChange'] ?? 0.0,
        'pChange': data?['percentChange'] ?? 0.0,
        'volume': data?['volume'] ?? data?['tradeVolume'] ?? 0,
        'identifier': inst.symbol,
      };

      if (!rows.containsKey(strikeKey)) {
        rows[strikeKey] = {'strikePrice': strike};
      }

      if (inst.symbol.endsWith("CE")) {
        rows[strikeKey]!['CE'] = node;
      } else if (inst.symbol.endsWith("PE")) {
        rows[strikeKey]!['PE'] = node;
      }
    }

    final List<Map<String, dynamic>> formattedRows = rows.values.toList();
    formattedRows.sort(
      (a, b) =>
          (a['strikePrice'] as double).compareTo(b['strikePrice'] as double),
    );

    return {
      'records': {
        'underlyingValue': spotPrice,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'filtered': {'data': formattedRows},
    };
  }
}
