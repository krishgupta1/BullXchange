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
  // 2. FETCH MARKET OVERVIEW
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
      String spotExchange = (config['segment'] == "BFO") ? "BSE" : "NSE";

      if (spotToken.isEmpty) {
        try {
          final underlying = allInstruments.firstWhere(
            (i) =>
                (i.name == optionName || i.symbol == "$optionName-EQ") &&
                i.symbol.endsWith("-EQ"),
          );
          spotToken = underlying.token;
          spotExchange = underlying.exchSeg;
        } catch (_) {
          AppLog.w("⚠️ Could not resolve spot token for overview: $symbol");
          return {};
        }
      }

      final data = await _fetchMarketData(spotToken, spotExchange);
      if (data != null) {
        double ltp = double.tryParse(data['ltp']?.toString() ?? "0") ?? 0;
        double close = double.tryParse(data['close']?.toString() ?? "0") ?? 0;
        if (ltp == 0 && close > 0) {
          data['ltp'] = close;
          data['change'] = 0.0;
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
  // 3. FETCH OPTION CHAIN
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchOptionChainData(
    String symbol, {
    required String exchange,
  }) async {
    try {
      // DEBUG DEVICE DATE
      print("🔥 DEBUG: Device Date is ${DateTime.now()}");

      final List<Instrument> allInstruments = await _getOrLoadScripMaster();
      if (allInstruments.isEmpty) throw "Scrip Master JSON is empty.";

      final config = _getSymbolConfig(symbol);
      String spotToken = config['spotToken']!;
      final String optionName = config['optionName']!;

      String segment = config['segment']!;
      if (exchange == 'BSE') segment = 'BFO';
      if (exchange == 'NSE') segment = 'NFO';

      // 1. Search for Spot Token
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

      // 2. Fetch Spot Price
      double referencePrice = 0.0;
      final spotExchange = (segment == "BFO") ? "BSE" : "NSE";

      if (spotToken.isNotEmpty) {
        final spotData = await _fetchMarketData(spotToken, spotExchange);
        if (spotData != null) {
          double ltp = double.tryParse(spotData['ltp']?.toString() ?? "0") ?? 0;
          double close =
              double.tryParse(spotData['close']?.toString() ?? "0") ?? 0;
          referencePrice = (ltp > 0) ? ltp : close;
        }
      }

      // 3. Fallback to Futures
      if (referencePrice == 0.0) {
        referencePrice = await _fetchFuturesPrice(
          optionName,
          allInstruments,
          segment,
        );
      }

      if (referencePrice == 0.0) {
        AppLog.w("⚠️ Market Price 0. Fetching full chain.");
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

      print("🔥 DEBUG: Found ${options.length} options for $optionName");

      // 5. GET ALL EXPIRIES
      final List<String> allExpiries = _findAllExpiries(options);
      print("🔥 DEBUG: Expiries after parse: $allExpiries");

      // 6. TARGET LIST & SORTING
      List<Instrument> targetOptions;

      if (referencePrice > 0) {
        final double range = referencePrice * 0.05; // 5% range
        targetOptions = options.where((i) {
          double strike = double.tryParse(i.strike) ?? 0.0;
          if (strike > 100000) strike = strike / 100;
          return strike >= (referencePrice - range) &&
              strike <= (referencePrice + range);
        }).toList();
      } else {
        targetOptions = List.from(options);
      }

      if (targetOptions.isEmpty) throw "No strikes found.";

      // ⭐️ ROBUST SORTING: Nearest Dates First
      targetOptions.sort((a, b) {
        DateTime dA = _parseDateRobust(a.expiry);
        DateTime dB = _parseDateRobust(b.expiry);
        int cmp = dA.compareTo(dB);
        if (cmp != 0) return cmp;

        double sA = double.tryParse(a.strike) ?? 0;
        double sB = double.tryParse(b.strike) ?? 0;
        return sA.compareTo(sB);
      });

      // Increase Safety Limit
      if (targetOptions.length > 1500) {
        targetOptions = targetOptions.sublist(0, 1500);
      }

      // 7. BATCH FETCH
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
        allExpiries,
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
    List<String> allExpiries,
  ) {
    final Map<String, Map<String, dynamic>> rows = {};

    for (var inst in instruments) {
      double strike = double.tryParse(inst.strike) ?? 0.0;
      if (strike > 100000) strike = strike / 100;

      // Clean up expiry key
      String cleanExpiry = inst.expiry.toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9]'),
        '',
      );
      String strikeKey = "${strike.toStringAsFixed(2)}_$cleanExpiry";

      final data = liveData[inst.token];
      int lotSize = int.tryParse(inst.lotSize) ?? 1;
      double ltp = double.tryParse(data?['ltp']?.toString() ?? "0") ?? 0.0;
      if (ltp == 0) {
        ltp = double.tryParse(data?['close']?.toString() ?? "0") ?? 0.0;
      }

      final Map<String, dynamic> node = {
        'openInterest': data?['opnInterest'] ?? 0,
        'lastPrice': ltp,
        'pChange': data?['percentChange'] ?? 0.0,
        'lotSize': lotSize,
        'expiryDate': cleanExpiry,
        'symbol': inst.symbol,
      };

      if (!rows.containsKey(strikeKey)) {
        rows[strikeKey] = {'strikePrice': strike, 'expiryDate': cleanExpiry};
      }
      if (inst.symbol.endsWith("CE")) {
        rows[strikeKey]!['CE'] = node;
      } else {
        rows[strikeKey]!['PE'] = node;
      }
    }

    final formattedRows = rows.values.toList();
    formattedRows.sort((a, b) {
      int expCmp = _parseDateRobust(
        a['expiryDate'],
      ).compareTo(_parseDateRobust(b['expiryDate']));
      if (expCmp != 0) return expCmp;
      return (a['strikePrice'] as double).compareTo(b['strikePrice'] as double);
    });

    return {
      'records': {'underlyingValue': spotPrice},
      'expiryDates': allExpiries,
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
        if (val == 0) val = (data['close'] as num?)?.toDouble() ?? 0.0;
        return val;
      }
    } catch (_) {}
    return 0.0;
  }

  // ⭐️ ROBUST PARSER: Handles "28-NOV-2024" and "28NOV24"
  DateTime _parseDateRobust(String dateStr) {
    // Remove non-alphanumeric (hyphens, spaces): 28-NOV-2024 -> 28NOV2024
    String d = dateStr.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    try {
      if (d.length >= 9) return DateFormat("ddMMMyyyy", "en_US").parseLoose(d);
      if (d.length >= 7) {
        // 28NOV24 -> 28NOV2024
        String prefix = d.substring(0, 5);
        String suffix = d.substring(5);
        return DateFormat(
          "ddMMMyyyy",
          "en_US",
        ).parseLoose("${prefix}20$suffix");
      }
    } catch (_) {}
    return DateTime(2099);
  }

  // ⭐️ FIXED: Returns ALL dates (Past & Future) to ensure 2024 isn't hidden
  List<String> _findAllExpiries(List<Instrument> o) {
    final Set<String> exps = o
        .map((e) => e.expiry.trim().toUpperCase())
        .toSet();
    final List<DateTime> dates = [];
    final Map<DateTime, String> map = {};

    for (var e in exps) {
      DateTime dt = _parseDateRobust(e);
      if (dt.year < 2099) {
        dates.add(dt);
        // Store cleaned version (no hyphens) to match Row logic
        map[dt] = e.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      }
    }
    dates.sort();

    // ⭐️ SHOW ALL DATES (Removed .where check)
    return dates.map((d) => map[d]!).toList();
  }

  String _findNearestExpiry(List<Instrument> o) {
    final all = _findAllExpiries(o);
    if (all.isNotEmpty) return all.first;
    if (o.isNotEmpty) return o.first.expiry;
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
