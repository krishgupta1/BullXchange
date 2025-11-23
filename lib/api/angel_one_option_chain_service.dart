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
  // 1. CONFIGURATION
  // ---------------------------------------------------------------------------
  Map<String, String> _getSymbolConfig(String inputSymbol) {
    final s = inputSymbol.toUpperCase().replaceAll(' ', '').trim();

    if (s == "NIFTY" || s == "NIFTY50") {
      return {"spotToken": "99926000", "optionName": "NIFTY", "segment": "NFO"};
    } else if (s == "BANKNIFTY" || s == "NIFTYBANK") {
      return {
        "spotToken": "99926009",
        "optionName": "BANKNIFTY",
        "segment": "NFO",
      };
    } else if (s == "FINNIFTY" || s == "NIFTYFINSERVICE") {
      return {
        "spotToken": "99926037",
        "optionName": "FINNIFTY",
        "segment": "NFO",
      };
    } else if (s == "MIDCPNIFTY" || s == "MIDCAPNIFTY") {
      return {
        "spotToken": "99926074",
        "optionName": "MIDCPNIFTY",
        "segment": "NFO",
      };
    } else if (s == "SENSEX") {
      return {
        "spotToken": "99919000",
        "optionName": "SENSEX",
        "segment": "BFO",
      };
    } else if (s == "BANKEX") {
      return {
        "spotToken": "99919014",
        "optionName": "BANKEX",
        "segment": "BFO",
      };
    }

    return {"spotToken": "", "optionName": s, "segment": "NFO"};
  }

  // ---------------------------------------------------------------------------
  // 2. FETCH MARKET OVERVIEW (New Method for Overview Tab)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchMarketOverview(
    String symbol, {
    String exchange = 'NSE',
  }) async {
    try {
      final List<Instrument> allInstruments = await _getOrLoadScripMaster();
      final config = _getSymbolConfig(symbol);
      String spotToken = config['spotToken']!;
      final String optionName = config['optionName']!;

      // Determine segment for Spot (Indices usually NSE/BSE, not NFO/BFO)
      String spotExchange = (config['segment'] == "BFO") ? "BSE" : "NSE";

      // 1. Resolve Spot Token if missing
      if (spotToken.isEmpty) {
        try {
          final underlying = allInstruments.firstWhere(
            (i) =>
                (i.name == optionName || i.symbol == "$optionName-EQ") &&
                i.symbol.endsWith("-EQ"),
          );
          spotToken = underlying.token;
          spotExchange =
              underlying.exchSeg; // Use exact exchange from instrument
        } catch (_) {
          AppLog.w("⚠️ Could not resolve spot token for overview: $symbol");
          return {};
        }
      }

      // 2. Fetch Full Market Data
      // Note: Ensure your _apiService.fetchLiveMarketData requests "FULL" mode
      // or returns 52-week high/low data.
      final data = await _fetchMarketData(spotToken, spotExchange);

      if (data != null) {
        // Fix 0 prices on weekends by using 'close'
        double ltp = double.tryParse(data['ltp']?.toString() ?? "0") ?? 0;
        double close = double.tryParse(data['close']?.toString() ?? "0") ?? 0;
        if (ltp == 0 && close > 0) {
          data['ltp'] = close; // Polyfill LTP
          data['change'] = 0.0; // No change on weekend
          data['pChange'] = 0.0;
        }
        return data;
      }
    } catch (e) {
      AppLog.e("Error fetching market overview: $e");
    }
    return {};
  }

  // ---------------------------------------------------------------------------
  // 3. FETCH OPTION CHAIN (Your Existing Logic)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchOptionChainData(
    String symbol, {
    required String exchange,
  }) async {
    try {
      final List<Instrument> allInstruments = await _getOrLoadScripMaster();
      if (allInstruments.isEmpty) throw "Scrip Master JSON is empty.";

      final config = _getSymbolConfig(symbol);
      String spotToken = config['spotToken']!;
      final String optionName = config['optionName']!;

      String segment = config['segment']!;
      if (exchange == 'BSE') segment = 'BFO';
      if (exchange == 'NSE') segment = 'NFO';

      // 1. Search for Spot Token if missing
      if (spotToken.isEmpty) {
        try {
          final underlying = allInstruments.firstWhere(
            (i) =>
                (i.name == optionName || i.symbol == "$optionName-EQ") &&
                i.symbol.endsWith("-EQ"),
          );
          spotToken = underlying.token;
        } catch (_) {}
      }

      // 2. Fetch Spot Price (Handle 0 values for weekends)
      double referencePrice = 0.0;
      final spotExchange = (segment == "BFO") ? "BSE" : "NSE";

      if (spotToken.isNotEmpty) {
        final spotData = await _fetchMarketData(spotToken, spotExchange);
        if (spotData != null) {
          double ltp = double.tryParse(spotData['ltp']?.toString() ?? "0") ?? 0;
          double close =
              double.tryParse(spotData['close']?.toString() ?? "0") ?? 0;
          // ⭐️ Prioritize LTP, but use Close if LTP is 0 (Weekend Logic)
          referencePrice = (ltp > 0) ? ltp : close;
        }
      }

      // 3. Fallback to Futures if Spot is still 0
      if (referencePrice == 0.0) {
        AppLog.w(
          "⚠️ Spot Price is 0. Trying Futures fallback for $optionName...",
        );
        referencePrice = await _fetchFuturesPrice(
          optionName,
          allInstruments,
          segment,
        );
      }

      // ⭐️ Final Safety Net: If even Futures fail, return error but don't crash
      if (referencePrice == 0.0) {
        throw "Market Data Unavailable (Price is 0). Market might be closed.";
      }

      // 4. Filter Options
      final List<Instrument> options = allInstruments.where((i) {
        final bool nameMatch =
            i.name.toUpperCase() == optionName ||
            i.name.toUpperCase().contains(optionName);
        return nameMatch &&
            (i.instrumentType == "OPTIDX" || i.instrumentType == "OPTSTK") &&
            i.exchSeg == segment;
      }).toList();

      if (options.isEmpty) throw "No Options found for $optionName ($segment).";

      // 5. Find Expiry & Range
      final String nearestExpiry = _findNearestExpiry(options);
      final double range = referencePrice * 0.03;

      final List<Instrument> targetOptions = options.where((i) {
        if (i.expiry != nearestExpiry) return false;
        double strike = double.tryParse(i.strike) ?? 0.0;
        if (strike > 100000) strike = strike / 100;
        return strike >= (referencePrice - range) &&
            strike <= (referencePrice + range);
      }).toList();

      if (targetOptions.isEmpty) {
        // If tight range fails, try a wider range
        throw "No strikes found near $referencePrice (Expiry: $nearestExpiry)";
      }

      // 6. Batch Fetch
      final List<String> allTokens = targetOptions.map((e) => e.token).toList();
      final Map<String, dynamic> liveDataMap = {};

      for (var i = 0; i < allTokens.length; i += 50) {
        final end = (i + 50 < allTokens.length) ? i + 50 : allTokens.length;
        try {
          final batchData = await _apiService.fetchLiveMarketData({
            segment: allTokens.sublist(i, end),
          });
          for (var item in batchData) {
            if (item is Map) {
              liveDataMap[item['symbolToken'] ?? item['token'] ?? ""] = item;
            }
          }
        } catch (_) {}
      }

      return _buildOptionChainResponse(
        targetOptions,
        liveDataMap,
        referencePrice,
      );
    } catch (e) {
      AppLog.e("Error fetching chain: $e");
      throw e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // 4. HELPERS
  // ---------------------------------------------------------------------------
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

      int lotSize = int.tryParse(inst.lotSize) ?? 1;

      double ltp = double.tryParse(data?['ltp']?.toString() ?? "0") ?? 0.0;
      // ⭐️ Use Close if LTP is 0 (Fixes weekend 0 values)
      if (ltp == 0) {
        ltp = double.tryParse(data?['close']?.toString() ?? "0") ?? 0.0;
      }

      final Map<String, dynamic> node = {
        'openInterest': data?['opnInterest'] ?? 0,
        'lastPrice': ltp,
        'pChange': data?['percentChange'] ?? 0.0,
        'lotSize': lotSize,
      };

      if (!rows.containsKey(strikeKey)) {
        rows[strikeKey] = {'strikePrice': strike};
      }
      if (inst.symbol.endsWith("CE")) {
        rows[strikeKey]!['CE'] = node;
      } else {
        rows[strikeKey]!['PE'] = node;
      }
    }

    final formattedRows = rows.values.toList();
    formattedRows.sort(
      (a, b) =>
          (a['strikePrice'] as double).compareTo(b['strikePrice'] as double),
    );
    return {
      'records': {'underlyingValue': spotPrice},
      'filtered': {'data': formattedRows},
    };
  }

  Future<Map<String, dynamic>?> _fetchMarketData(String t, String e) async {
    try {
      final res = await _apiService.fetchLiveMarketData({
        e: [t],
      });
      if (res.isNotEmpty && res[0] is Map) return res[0];
    } catch (_) {}
    return null;
  }

  Future<double> _fetchFuturesPrice(
    String n,
    List<Instrument> i,
    String s,
  ) async {
    try {
      final futures = i
          .where(
            (inst) =>
                (inst.name == n || inst.name.contains(n)) &&
                inst.instrumentType == "FUTIDX" &&
                inst.exchSeg == s,
          )
          .toList();

      if (futures.isEmpty) return 0.0;

      final String expiry = _findNearestExpiry(futures);
      final target = futures.firstWhere((f) => f.expiry == expiry);

      final data = await _fetchMarketData(target.token, s);
      if (data != null) {
        double val = (data['ltp'] as num?)?.toDouble() ?? 0.0;
        // ⭐️ Fallback to Close for Futures too
        if (val == 0) val = (data['close'] as num?)?.toDouble() ?? 0.0;
        return val;
      }
    } catch (_) {}
    return 0.0;
  }

  String _findNearestExpiry(List<Instrument> o) {
    if (o.isEmpty) throw "No instruments";
    final Set<String> exps = o.map((e) => e.expiry).toSet();
    final DateFormat f = DateFormat("ddMMMyyyy", "en_US");
    final DateTime now = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
    final List<DateTime> dates = [];

    for (var e in exps) {
      try {
        dates.add(f.parseLoose(e.trim()));
      } catch (_) {}
    }
    dates.sort();

    for (var d in dates) {
      if (d.isAtSameMomentAs(now) || d.isAfter(now)) {
        return f.format(d).toUpperCase();
      }
    }
    if (dates.isNotEmpty) return f.format(dates.last).toUpperCase();
    throw "No expiry found";
  }

  Future<List<Instrument>> _getOrLoadScripMaster() async {
    if (_cachedInstruments != null) return _cachedInstruments!;
    final s = await rootBundle.loadString('assets/OpenAPIScripMaster.json');
    final List<dynamic> d = jsonDecode(s);
    _cachedInstruments = d.map((e) => Instrument.fromJson(e)).toList();
    return _cachedInstruments!;
  }
}
