import 'dart:convert';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class AngelOneOptionChainService {
  // Replace with your actual credentials management or Singleton
  final String _jwtToken = "YOUR_JWT_TOKEN";
  final String _apiKey = "YOUR_API_KEY";
  final String _clientIp = "YOUR_IP"; // Or fetch dynamically

  final Dio _dio = Dio();

  AngelOneOptionChainService() {
    _dio.options.baseUrl =
        "https://apiconnect.angelone.in/rest/secure/angelbroking/market/v1";
    _dio.options.headers = {
      "Authorization": "Bearer $_jwtToken",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-UserType": "USER",
      "X-SourceID": "WEB",
      "X-ClientLocalIP": _clientIp,
      "X-ClientPublicIP": _clientIp,
      "X-MACAddress": "00:00:00:00:00:00",
      "X-PrivateKey": _apiKey,
    };
  }

  /// Main method called by Provider
  Future<Map<String, dynamic>?> fetchOptionChainData(String symbol) async {
    try {
      // 1. Load Master Data (In a real app, cache this in memory!)
      final List<Instrument> allInstruments = await _loadScripMaster();

      // 2. Determine formatting (Angel One uses "NIFTY" for name, but symbol might differ)
      //    Target Name usually: "NIFTY", "BANKNIFTY", "FINNIFTY"
      final String targetName = _mapSymbolToAngelName(symbol);

      // 3. Filter for Options (OPTIDX) for this symbol
      final List<Instrument> options = allInstruments.where((i) {
        return i.name == targetName &&
            i.instrumentType == "OPTIDX" &&
            i.exchSeg == "NFO";
      }).toList();

      if (options.isEmpty) return null;

      // 4. Find the nearest Expiry Date
      //    Angel One expiry format is usually "28NOV2024"
      final String? nearestExpiry = _findNearestExpiry(options);
      if (nearestExpiry == null) return null;

      AppLog.i("🗓️ Selected Expiry for $symbol: $nearestExpiry");

      // 5. Filter options for ONLY this expiry
      final List<Instrument> expiryOptions = options
          .where((i) => i.expiry == nearestExpiry)
          .toList();

      // 6. Prepare Tokens to Fetch
      //    Fetching ALL strikes might hit API limits (50 limit usually).
      //    Ideally, we fetch SPOT price first, then filter range.
      //    For now, we'll take the middle 50 contracts or execute batching.
      //    Let's slice the list to avoid 429 errors if the list is huge.
      final List<String> tokens = expiryOptions.map((e) => e.token).toList();

      // *Optimization: Limit to 50 tokens if required, or implement batching logic here.*
      // For safety in this example, we take first 50. (In prod, filter by ATM).
      final List<String> safeTokens = tokens.take(50).toList();

      // 7. Fetch Live Data from Angel One
      final Map<String, dynamic> liveDataMap = await _fetchLiveMarketData(
        safeTokens,
      );

      // 8. Construct the Response Structure
      //    We need to group by Strike Price -> { CE: ..., PE: ... }

      // Get Underlying Value (Spot Price) from the index itself
      double underlyingValue = 0.0;
      // Try to find the spot token (e.g. Nifty 50 token) and fetch it?
      // For simplicity, we'll take the average of ATM strike or pass 0.

      final List<Map<String, dynamic>> formattedRows = [];

      // Group by Strike
      final Map<String, List<Instrument>> byStrike = {};
      for (var opt in expiryOptions) {
        if (!liveDataMap.containsKey(opt.token)) {
          continue; // Skip if no live data
        }

        // Angel strike is often "24500.000000", parse it clean
        String strikeKey = double.parse(
          opt.strike,
        ).toStringAsFixed(0); // "24500"

        byStrike.putIfAbsent(strikeKey, () => []).add(opt);
      }

      // Build rows
      byStrike.forEach((strikeStr, instruments) {
        Map<String, dynamic> ceData = {};
        Map<String, dynamic> peData = {};

        for (var inst in instruments) {
          final live = liveDataMap[inst.token];
          if (live == null) continue;

          // Map Angel keys to your UI keys
          final mapped = {
            'openInterest': live['opnInterest'] ?? 0,
            'lastPrice': live['ltp'] ?? 0.0,
            'change': live['netChange'] ?? 0.0,
            'pChange': live['percentChange'] ?? 0.0,
            'volume': live['volume'] ?? 0,
          };

          if (inst.symbol.endsWith("CE")) {
            ceData = mapped;
          } else {
            peData = mapped;
          }
        }

        if (ceData.isNotEmpty || peData.isNotEmpty) {
          formattedRows.add({
            'strikePrice': double.parse(strikeStr),
            'CE': ceData.isEmpty ? null : ceData,
            'PE': peData.isEmpty ? null : peData,
          });
        }
      });

      // Sort by strike price
      formattedRows.sort(
        (a, b) =>
            (a['strikePrice'] as double).compareTo(b['strikePrice'] as double),
      );

      return {
        'records': {
          'underlyingValue':
              underlyingValue, // You might need a separate call for Spot Index LTP
          'timestamp': DateTime.now().toString(),
        },
        'filtered': {'data': formattedRows},
      };
    } catch (e, st) {
      AppLog.e("❌ Angel Option Chain Error: $e\n$st");
      return null;
    }
  }

  // --- HELPERS ---

  Future<List<Instrument>> _loadScripMaster() async {
    // NOTE: This is heavy. In production, pass this list from a provider
    // instead of reloading JSON every time.
    final jsonString = await rootBundle.loadString(
      'assets/OpenAPIScripMaster.json',
    );
    final List<dynamic> data = jsonDecode(jsonString);
    return data.map((e) => Instrument.fromJson(e)).toList();
  }

  String _mapSymbolToAngelName(String symbol) {
    // Map your UI symbols to Angel One "Name" field
    switch (symbol.toUpperCase()) {
      case "NIFTY":
        return "NIFTY";
      case "BANKNIFTY":
        return "BANKNIFTY";
      case "FINNIFTY":
        return "FINNIFTY";
      default:
        return symbol;
    }
  }

  String? _findNearestExpiry(List<Instrument> options) {
    // Angel format: "28NOV2024"
    // We need to parse these dates and find the closest future one.
    final Set<String> uniqueExpiries = options.map((e) => e.expiry).toSet();
    if (uniqueExpiries.isEmpty) return null;

    final DateFormat angelFormat = DateFormat("ddMMMyyyy"); // 28NOV2024
    final DateTime now = DateTime.now();
    // Set 'today' to midnight to avoid time issues
    final DateTime today = DateTime(now.year, now.month, now.day);

    final List<DateTime> dates = [];

    for (var exp in uniqueExpiries) {
      try {
        dates.add(angelFormat.parse(exp));
      } catch (e) {
        /* Ignore parse errors */
      }
    }

    dates.sort(); // Ascending

    // Find first date >= today
    for (var d in dates) {
      if (d.isAtSameMomentAs(today) || d.isAfter(today)) {
        return angelFormat.format(d).toUpperCase();
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _fetchLiveMarketData(List<String> tokens) async {
    try {
      final response = await _dio.post(
        "/market/v1/market_data",
        data: {
          "mode": "FULL",
          "exchangeTokens": {"NFO": tokens}, // NFO is for Options
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> fetched = response.data['data']['fetched'];
        final Map<String, dynamic> result = {};

        for (var item in fetched) {
          String token = item['symbolToken'] ?? item['token'];
          result[token] = item;
        }
        return result;
      }
    } catch (e) {
      AppLog.e("Failed to fetch live tokens: $e");
    }
    return {};
  }
}
