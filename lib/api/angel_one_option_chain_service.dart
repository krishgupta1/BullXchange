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
          if (data['change'] == null) data['change'] = 0.0;
          if (data['pChange'] == null) data['pChange'] = 0.0;
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
    String? specificExpiry,
  }) async {
    try {
      final List<Instrument> allInstruments = await _getOrLoadScripMaster();
      if (allInstruments.isEmpty) throw "Scrip Master JSON is empty.";

      final config = _getSymbolConfig(symbol);
      String spotToken = config['spotToken']!;
      final String optionName = config['optionName']!;

      String segment = config['segment']!;
      if (exchange == 'BSE' && segment != 'BFO') segment = 'BFO';
      if (exchange == 'NSE' && segment != 'NFO') segment = 'NFO';

      // 1. Spot Token
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

      // 2. Reference Price
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

      // 4. STRICT FILTERING (Fixes "Too High Frequency" issue)
      final List<Instrument> options = allInstruments.where((i) {
        // 🛑 STRICT MATCH: Prevents "NIFTY" matching "BANKNIFTY"
        final bool nameMatch = i.name.toUpperCase() == optionName;
        return nameMatch &&
            (i.instrumentType == "OPTIDX" || i.instrumentType == "OPTSTK") &&
            i.exchSeg == segment;
      }).toList();

      if (options.isEmpty) throw "No Options found for $optionName ($segment).";

      // 5. GET EXPIRIES (Hides Past Dates)
      final List<String> allExpiries = _findAllExpiries(options);

      String targetExpiry = "";
      if (specificExpiry != null &&
          specificExpiry.isNotEmpty &&
          specificExpiry != "Current") {
        targetExpiry = specificExpiry;
      } else if (allExpiries.isNotEmpty) {
        targetExpiry = allExpiries.first;
      }

      // 6. Filter by Expiry
      List<Instrument> targetOptions = options.where((i) {
        String cleanExp = i.expiry.trim().toUpperCase().replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        );
        return cleanExp == targetExpiry;
      }).toList();

      // 7. Filter by Strike Range (5%)
      if (referencePrice > 0) {
        final double range = referencePrice * 0.05;
        targetOptions = targetOptions.where((i) {
          double strike = double.tryParse(i.strike) ?? 0.0;
          if (strike > 100000) strike = strike / 100;
          return strike >= (referencePrice - range) &&
              strike <= (referencePrice + range);
        }).toList();
      }

      // Fallback if range is empty
      if (targetOptions.isEmpty) {
        targetOptions = options.where((i) {
          String cleanExp = i.expiry.trim().toUpperCase().replaceAll(
            RegExp(r'[^A-Z0-9]'),
            '',
          );
          return cleanExp == targetExpiry;
        }).toList();
      }

      // Sort
      targetOptions.sort((a, b) {
        double sA = double.tryParse(a.strike) ?? 0;
        double sB = double.tryParse(b.strike) ?? 0;
        return sA.compareTo(sB);
      });

      // Cap size
      if (targetOptions.length > 200) {
        targetOptions = targetOptions.sublist(0, 200);
      }

      // 8. BATCH FETCH
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

      String cleanExpiry = inst.expiry.toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9]'),
        '',
      );
      String strikeKey = "${strike.toStringAsFixed(2)}_$cleanExpiry";

      final data = liveData[inst.token];

      // ⭐️ FIX: Use Close if LTP is 0
      double ltp = double.tryParse(data?['ltp']?.toString() ?? "0") ?? 0.0;
      if (ltp == 0) {
        ltp = double.tryParse(data?['close']?.toString() ?? "0") ?? 0.0;
      }

      // ⭐️ FIX: Better OI check
      double oi =
          double.tryParse(data?['opnInterest']?.toString() ?? "0") ?? 0.0;
      if (oi == 0) oi = double.tryParse(data?['oi']?.toString() ?? "0") ?? 0.0;
      if (oi == 0) {
        oi = double.tryParse(data?['openInterest']?.toString() ?? "0") ?? 0.0;
      }

      int lotSize = int.tryParse(inst.lotSize) ?? 1;

      final Map<String, dynamic> node = {
        'openInterest': oi,
        'lastPrice': ltp,
        'pChange': data?['percentChange'] ?? data?['netChange'] ?? 0.0,
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
    formattedRows.sort(
      (a, b) =>
          (a['strikePrice'] as double).compareTo(b['strikePrice'] as double),
    );

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

  DateTime _parseDateRobust(String dateStr) {
    String d = dateStr.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    try {
      if (d.length >= 9) return DateFormat("ddMMMyyyy", "en_US").parseLoose(d);
      if (d.length >= 7) {
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

  // ⭐️ UPDATED: Hides Past Expiries
  List<String> _findAllExpiries(List<Instrument> o) {
    final Set<String> exps = o
        .map((e) => e.expiry.trim().toUpperCase())
        .toSet();
    final List<DateTime> dates = [];
    final Map<DateTime, String> map = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var e in exps) {
      DateTime dt = _parseDateRobust(e);
      // Strictly ignore dates before today
      if (dt.year < 2099 && (dt.isAfter(today) || dt.isAtSameMomentAs(today))) {
        dates.add(dt);
        map[dt] = e.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      }
    }
    dates.sort();
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
