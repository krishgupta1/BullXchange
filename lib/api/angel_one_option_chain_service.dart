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

    // NSE Indices
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
    }
    // BSE Indices
    else if (s == "SENSEX") {
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
  // 2. MAIN FETCH
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
      final String segment = config['segment']!;

      // Dynamic Token Search
      if (spotToken.isEmpty) {
        try {
          final underlying = allInstruments.firstWhere(
            (i) =>
                (i.name == optionName || i.symbol == "$optionName-EQ") &&
                i.symbol.endsWith("-EQ"),
          );
          spotToken = underlying.token;
        } catch (e) {
          throw "Spot Token not found for $symbol";
        }
      }

      // Fetch Spot Price
      double referencePrice = 0.0;
      final spotExchange = (segment == "BFO") ? "BSE" : "NSE";
      final spotData = await _fetchMarketData(spotToken, spotExchange);

      if (spotData != null) {
        double ltp = double.tryParse(spotData['ltp']?.toString() ?? "0") ?? 0;
        double close =
            double.tryParse(spotData['close']?.toString() ?? "0") ?? 0;
        referencePrice = (ltp > 0) ? ltp : close;
      }

      // Fallback to Futures if Spot is 0
      if (referencePrice == 0.0) {
        referencePrice = await _fetchFuturesPrice(
          optionName,
          allInstruments,
          segment,
        );
      }
      if (referencePrice == 0.0) throw "Market Data Unavailable (Price is 0).";

      // Filter Options
      final List<Instrument> options = allInstruments.where((i) {
        return i.name == optionName &&
            (i.instrumentType == "OPTIDX" || i.instrumentType == "OPTSTK") &&
            i.exchSeg == segment;
      }).toList();

      if (options.isEmpty) throw "No Options found.";

      final String nearestExpiry = _findNearestExpiry(options);
      final double range = referencePrice * 0.03; // 3% Range
      final List<Instrument> targetOptions = options.where((i) {
        if (i.expiry != nearestExpiry) return false;
        double strike = double.tryParse(i.strike) ?? 0.0;
        if (strike > 100000) strike = strike / 100;
        return strike >= (referencePrice - range) &&
            strike <= (referencePrice + range);
      }).toList();

      // Batch Fetch Live Data (50 limit)
      final List<String> allTokens = targetOptions.map((e) => e.token).toList();
      final Map<String, dynamic> liveDataMap = {};

      for (var i = 0; i < allTokens.length; i += 50) {
        final end = (i + 50 < allTokens.length) ? i + 50 : allTokens.length;
        try {
          final batchData = await _apiService.fetchLiveMarketData({
            segment: allTokens.sublist(i, end),
          });
          for (var item in batchData) {
            if (item is Map)
              liveDataMap[item['symbolToken'] ?? item['token'] ?? ""] = item;
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
  // 3. HELPERS
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

      // ⭐️ EXTRACT LOT SIZE from your Instrument model
      int lotSize = int.tryParse(inst.lotSize) ?? 1;

      double ltp = double.tryParse(data?['ltp']?.toString() ?? "0") ?? 0.0;
      if (ltp == 0)
        ltp = double.tryParse(data?['close']?.toString() ?? "0") ?? 0.0;

      final Map<String, dynamic> node = {
        'openInterest': data?['opnInterest'] ?? 0,
        'lastPrice': ltp,
        'pChange': data?['percentChange'] ?? 0.0,
        'lotSize': lotSize, // Passing to UI
      };

      if (!rows.containsKey(strikeKey))
        rows[strikeKey] = {'strikePrice': strike};
      if (inst.symbol.endsWith("CE"))
        rows[strikeKey]!['CE'] = node;
      else
        rows[strikeKey]!['PE'] = node;
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
                inst.name == n &&
                inst.instrumentType == "FUTIDX" &&
                inst.exchSeg == s,
          )
          .toList();
      if (futures.isEmpty) return 0.0;
      final String expiry = _findNearestExpiry(futures);
      final target = futures.firstWhere((f) => f.expiry == expiry);
      final data = await _fetchMarketData(target.token, s);
      if (data != null) {
        return (data['ltp'] as num?)?.toDouble() ??
            (data['close'] as num?)?.toDouble() ??
            0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  String _findNearestExpiry(List<Instrument> o) {
    final Set<String> exps = o.map((e) => e.expiry).toSet();
    final DateFormat f = DateFormat("ddMMMyyyy", "en_US");
    final DateTime now = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final List<DateTime> dates = [];

    for (var e in exps) {
      try {
        dates.add(f.parseLoose(e.trim()));
      } catch (_) {}
    }
    dates.sort();

    for (var d in dates) {
      if (d.isAtSameMomentAs(now) || d.isAfter(now))
        return f.format(d).toUpperCase();
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
