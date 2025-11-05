// lib/provider/instrument_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:flutter/foundation.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../api/angel_one_api_service.dart';
import '../models/instrument_model.dart';

List<dynamic> _parseJson(String jsonString) {
  return jsonDecode(jsonString) as List<dynamic>;
}

class InstrumentProvider with ChangeNotifier {
  final AngelOneApiService _apiService = AngelOneApiService();

  List<Instrument> _allInstruments = [];
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _refreshTimer;

  Map<String, Instrument> _allNSEStocksMap = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Instrument> get allNSEStocks => _allInstruments
      .where(
        (inst) =>
            inst.exchSeg == 'NSE' &&
            inst.symbol.endsWith('-EQ') &&
            inst.name.isNotEmpty,
      )
      .toList();

  // --- SPOT INDEX GETTERS ---

  Instrument? get nifty50 => _allInstruments.firstWhere(
    (inst) => inst.symbol == 'Nifty 50',
    orElse: () => Instrument.fromJson({}),
  );
  Instrument? get bankNifty => _allInstruments.firstWhere(
    (inst) => inst.symbol == 'Nifty Bank',
    orElse: () => Instrument.fromJson({}),
  );

  // --- 🔽 GETTERS NOW FIXED 🔽 ---
  Instrument? get finNifty => _allInstruments.firstWhere(
    (inst) => inst.symbol == 'Nifty Fin Service', // FIXED (removed 's')
    orElse: () => Instrument.fromJson({}),
  );

  Instrument? get midcapNifty => _allInstruments.firstWhere(
    (inst) => inst.symbol == 'NIFTY MID SELECT', // FIXED
    orElse: () => Instrument.fromJson({}),
  );
  // --- 🔼 END OF FIX 🔼 ---

  Instrument? get sensex => _allInstruments.firstWhere(
    (inst) => inst.symbol == 'SENSEX', // This one was correct
    orElse: () => Instrument.fromJson({}),
  );

  Instrument? get bankex => _allInstruments.firstWhere(
    (inst) => inst.symbol == 'BANKEX', // This one was correct
    orElse: () => Instrument.fromJson({}),
  );

  List<Instrument> get topGainers {
    final stocks = allNSEStocks
        .where((inst) => inst.liveData['percentChange'] is num)
        .toList();
    stocks.sort(
      (a, b) => (b.liveData['percentChange'] as num).compareTo(
        a.liveData['percentChange'] as num,
      ),
    );
    return stocks;
  }

  List<Instrument> get topLosers {
    final stocks = allNSEStocks
        .where((inst) => inst.liveData['percentChange'] is num)
        .toList();
    stocks.sort(
      (a, b) => (a.liveData['percentChange'] as num).compareTo(
        b.liveData['percentChange'] as num,
      ),
    );
    return stocks;
  }

  List<Instrument> get mostActiveByVolume {
    final stocks = allNSEStocks
        .where(
          (inst) =>
              inst.liveData.containsKey('totalTradedVolume') &&
              inst.liveData['totalTradedVolume'] != null,
        )
        .toList();

    stocks.sort((a, b) {
      final aVolume =
          num.tryParse(a.liveData['totalTradedVolume'].toString()) ?? 0;
      final bVolume =
          num.tryParse(b.liveData['totalTradedVolume'].toString()) ?? 0;
      return bVolume.compareTo(aVolume);
    });
    return stocks;
  }

  InstrumentProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/OpenAPIScripMaster.json',
      );
      final List<dynamic> data = await compute(_parseJson, jsonString);
      _allInstruments = data
          .map((item) => Instrument.fromJson(item as Map<String, dynamic>))
          .toList();

      // --- DEBUGGING BLOCK REMOVED ---

      await _startPeriodicFetches();
    } catch (e, stackTrace) {
      AppLog.e("❌ ERROR in _initialize: $e\n$stackTrace");
      _errorMessage = "Failed to load initial data.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _startPeriodicFetches() async {
    await _fetchEssentialData();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _fetchEssentialData();
    });
  }

  /// Fetches indices and stocks in separate, safe API calls.
  Future<void> _fetchEssentialData() async {
    // Call 1: For ALL 6 indices
    await _updateInstruments([
      nifty50,
      bankNifty,
      finNifty, // Now finds the correct symbol
      midcapNifty, // Now finds the correct symbol
      sensex,
      bankex,
    ]);

    // Call 2: For stocks (a safe number to avoid API limits)
    await _updateInstruments(allNSEStocks.take(50).toList());
  }

  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  // ✨ HOLDINGS METHOD ✨
  Future<void> fetchLiveDataForHoldings(
    List<StockHoldingModel> holdings,
  ) async {
    final symbolsToFetch = holdings.map((h) => h.stockSymbol).toSet();
    final instrumentsToFetch = _allInstruments
        .where(
          (inst) => symbolsToFetch.contains(inst.symbol.replaceAll('-EQ', '')),
        )
        .toList();
    if (instrumentsToFetch.isNotEmpty) {
      AppLog.i("🚀 Fetching live data specifically for user holdings...");
      await _updateInstruments(instrumentsToFetch);
    }
  }
  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  Future<void> _updateInstruments(List<Instrument?> instruments) async {
    final uniqueInstruments = instruments
        .whereType<Instrument>()
        .toSet()
        .toList();
    final Map<String, List<String>> tokensByExchange = {};
    for (var inst in uniqueInstruments) {
      if (inst.token.isNotEmpty) {
        tokensByExchange.putIfAbsent(inst.exchSeg, () => []).add(inst.token);
      }
    }
    if (tokensByExchange.isEmpty) return;

    final liveDataList = await _apiService.fetchLiveMarketData(
      tokensByExchange,
    );

    try {
      AppLog.d(
        '🔎 _updateInstruments: requested tokensByExchange = $tokensByExchange',
      );
    } catch (_) {}

    if (liveDataList.isNotEmpty) {
      try {
        if (liveDataList.isNotEmpty) {
          final sample = liveDataList.take(3).toList();
          for (var i = 0; i < sample.length; i++) {
            final item = sample[i];
            if (item is Map<String, dynamic>) {
              AppLog.d('  sample[$i] keys = ${item.keys.toList()}');
              for (var k in [
                'symbolToken',
                'symboltoken',
                'symbol_token',
                'token',
              ]) {
                if (item.containsKey(k)) {
                  AppLog.d('    $k = ${item[k]}');
                }
              }
            } else {
              AppLog.d('  sample[$i] is ${item.runtimeType}');
            }
          }
        }
      } catch (e) {
        AppLog.w('Error while logging liveDataList sample: $e');
      }

      final Map<String, Map<String, dynamic>> liveDataMap = {};
      for (var stock in liveDataList) {
        if (stock is Map<String, dynamic>) {
          String? token;
          if (stock['symbolToken'] != null) {
            token = stock['symbolToken'].toString();
          } else if (stock['symboltoken'] != null) {
            token = stock['symboltoken'].toString();
          } else if (stock['symbol_token'] != null) {
            token = stock['symbol_token'].toString();
          } else if (stock['token'] != null) {
            token = stock['token'].toString();
          }

          if (token != null && token.isNotEmpty) {
            liveDataMap[token] = Map<String, dynamic>.from(stock);
          }
        }
      }

      for (var instrument in _allInstruments) {
        final mapped = liveDataMap[instrument.token];
        if (mapped != null) {
          instrument.liveData = _sanitizeLiveData(mapped);
        }
      }
      notifyListeners();
    }
  }

  /// Lookup helper to find an instrument by its exchange token.
  Instrument? getInstrumentByToken(String token) {
    try {
      return _allInstruments.firstWhere((i) => i.token == token);
    } catch (_) {
      return null;
    }
  }

  /// Helper to find an instrument by its stock symbol (e.g., "RELIANCE-EQ")
  Instrument? getInstrumentBySymbol(String symbol) {
    final String eqSymbol = '$symbol-EQ';

    if (_allNSEStocksMap.isEmpty) {
      _allNSEStocksMap = {for (var stock in allNSEStocks) stock.symbol: stock};
    }
    return _allNSEStocksMap[eqSymbol];
  }

  Future<void> fetchLiveDataFor(List<Instrument> instruments) async {
    await _updateInstruments(instruments);
  }

  Map<String, dynamic> _sanitizeLiveData(Map<String, dynamic> rawData) {
    final sanitizedData = Map<String, dynamic>.from(rawData);
    final Map<String, List<String>> aliases = {
      'totalTradedVolume': [
        'ttlTrdQty',
        'totalTradedQty',
        'volume',
        'tradedVolume',
        'tradeVolume',
      ],
      'open': ['openPrice', 'open_price', 'o'],
      'high': ['highPrice', 'high_price', 'h'],
      'low': ['lowPrice', 'low_price', 'l'],
      'ltp': ['lastPrice', 'last_traded_price', 'lastTradedPrice'],
      'netChange': ['change', 'net_change', 'changeValue'],
      'percentChange': ['pChange', 'pchg', 'percent_change'],
      'close': ['closePrice', 'close_price'],
      'avgPrice': ['avg_price', 'averagePrice'],
      'avgVolume': [
        'avgTradedQty',
        'avg_trd_qty',
        'avg_volume',
        'avgVol',
        'avgtrdqty',
      ],
      'marketCap': [
        'marketCap',
        'mktCap',
        'market_cap',
        'mcap',
        'marketCapitalization',
      ],
    };

    for (var target in aliases.keys) {
      if ((!sanitizedData.containsKey(target) ||
          sanitizedData[target] == null)) {
        for (var alt in aliases[target]!) {
          if (sanitizedData.containsKey(alt) && sanitizedData[alt] != null) {
            sanitizedData[target] = sanitizedData[alt];
            break;
          }
        }
      }
    }

    const numericKeys = [
      'ltp',
      'netChange',
      'percentChange',
      'totalTradedVolume',
      'avgVolume',
      'marketCap',
      'open',
      'high',
      'low',
      'close',
      'avgPrice',
    ];
    for (var key in numericKeys) {
      if (sanitizedData.containsKey(key) && sanitizedData[key] != null) {
        final parsedValue = num.tryParse(sanitizedData[key].toString());
        if (parsedValue != null) sanitizedData[key] = parsedValue;
      }
    }

    return sanitizedData;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
