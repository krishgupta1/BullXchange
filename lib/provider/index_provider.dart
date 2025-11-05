// lib/providers/index_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../api/angel_one_api_service.dart';
import '../models/future_option_instrument_model.dart';
// import '../utils/logger.dart'; // Using print()

List<dynamic> _parseIndexJson(String jsonString) {
  return jsonDecode(jsonString) as List<dynamic>;
}

class IndexProvider with ChangeNotifier {
  final AngelOneApiService _apiService = AngelOneApiService();

  List<FutureOptionInstrument> _mainIndices = [];
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _refreshTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FutureOptionInstrument> get mainIndices => _mainIndices;

  // ⚠️ These are the values we *think* are right. We'll confirm with the logs.
  final List<String> _targetIndices = ['NIFTY 50', 'NIFTY BANK'];

  IndexProvider() {
    print("--- INDEX PROVIDER: Initializing... ---");
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/OpenAPIScripMaster.json',
      );
      final List<dynamic> data = await compute(_parseIndexJson, jsonString);

      final List<FutureOptionInstrument> foundIndices = [];

      final allInstruments = data
          .map(
            (item) =>
                FutureOptionInstrument.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      print(
        "--- INDEX PROVIDER: Total instruments loaded: ${allInstruments.length} ---",
      );

      //
      // --- 🔽 NEW DEBUGGING BLOCK 🔽 ---
      //
      print(
        "--- INDEX PROVIDER: Searching for potential Spot Index matches... ---",
      );

      // Let's find potential matches for NIFTY 50
      try {
        var nifty50Matches = allInstruments
            .where(
              (inst) =>
                  inst.name.toUpperCase().contains('NIFTY 50') &&
                  inst.instrumentType.toUpperCase().contains('INDEX'),
            )
            .toList();

        if (nifty50Matches.isNotEmpty) {
          print(
            "--- INDEX PROVIDER: Found ${nifty50Matches.length} potential matches for 'NIFTY 50'. First one:",
          );
          var match = nifty50Matches.first;
          print("  -> name: '${match.name}'");
          print("  -> exchSeg: '${match.exchSeg}'");
          print("  -> instrumentType: '${match.instrumentType}'");
          print("  -> token: '${match.token}'");
        } else {
          print(
            "--- INDEX PROVIDTER: ❌ Could not find any 'INDEX' instrument containing 'NIFTY 50'. ---",
          );
        }
      } catch (e) {
        /* ignore */
      }

      // Let's find potential matches for NIFTY BANK
      try {
        var bankNiftyMatches = allInstruments
            .where(
              (inst) =>
                  inst.name.toUpperCase().contains('NIFTY BANK') &&
                  inst.instrumentType.toUpperCase().contains('INDEX'),
            )
            .toList();

        if (bankNiftyMatches.isNotEmpty) {
          print(
            "--- INDEX PROVIDER: Found ${bankNiftyMatches.length} potential matches for 'NIFTY BANK'. First one:",
          );
          var match = bankNiftyMatches.first;
          print("  -> name: '${match.name}'");
          print("  -> exchSeg: '${match.exchSeg}'");
          print("  -> instrumentType: '${match.instrumentType}'");
          print("  -> token: '${match.token}'");
        } else {
          print(
            "--- INDEX PROVIDTER: ❌ Could not find any 'INDEX' instrument containing 'NIFTY BANK'. ---",
          );
        }
      } catch (e) {
        /* ignore */
      }

      print("--- INDEX PROVIDER: --- End of debug search ---");
      //
      // --- 🔼 END OF DEBUGGING BLOCK 🔼 ---
      //

      // --- This is the original logic (which is failing) ---
      for (var indexName in _targetIndices) {
        try {
          final instrument = allInstruments.firstWhere(
            (inst) =>
                inst.name == indexName &&
                (inst.exchSeg == 'NSE' || inst.exchSeg == 'BSE'),
          );
          foundIndices.add(instrument);
          print(
            "--- INDEX PROVIDER: ✅ (Exact Match) Found Spot Index: ${instrument.name} ---",
          );
        } catch (e) {
          print(
            "--- INDEX PROVIDER: ❌ (Exact Match) Could not find '$indexName' with exch 'NSE' or 'BSE'. ---",
          );
        }
      }
      // --- End of original logic ---

      _mainIndices = foundIndices;
      print(
        "--- INDEX PROVIDER: ✅ Loaded ${_mainIndices.length} spot indices. ---",
      );

      await _startPeriodicFetches();
    } catch (e, stackTrace) {
      print("--- INDEX PROVIDER: ❌ ERROR in _initialize: $e\n$stackTrace");
      _errorMessage = "Failed to load index data.";
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

  Future<void> _fetchEssentialData() async {
    if (_mainIndices.isEmpty) return;
    await _updateInstruments(_mainIndices);
  }

  Future<void> _updateInstruments(
    List<FutureOptionInstrument> instruments,
  ) async {
    final Map<String, List<String>> tokensByExchange = {};
    for (var inst in instruments) {
      if (inst.token.isNotEmpty) {
        tokensByExchange.putIfAbsent(inst.exchSeg, () => []).add(inst.token);
      }
    }
    if (tokensByExchange.isEmpty) return;

    final liveDataList = await _apiService.fetchLiveMarketData(
      tokensByExchange,
    );

    if (liveDataList.isNotEmpty) {
      final Map<String, Map<String, dynamic>> liveDataMap = {};
      for (var stock in liveDataList) {
        if (stock is Map<String, dynamic>) {
          String? token;
          if (stock['symbolToken'] != null) {
            token = stock['symbolToken'].toString();
          } else if (stock['token'] != null) {
            token = stock['token'].toString();
          }
          if (token != null && token.isNotEmpty) {
            liveDataMap[token] = Map<String, dynamic>.from(stock);
          }
        }
      }

      for (var instrument in _mainIndices) {
        final mapped = liveDataMap[instrument.token];
        if (mapped != null) {
          instrument.liveData = _sanitizeLiveData(mapped);
        }
      }
      notifyListeners();
    }
  }

  // This is the full _sanitizeLiveData method
  Map<String, dynamic> _sanitizeLiveData(Map<String, dynamic> rawData) {
    final sanitizedData = Map<String, dynamic>.from(rawData);
    final Map<String, List<String>> aliases = {
      'totalTradedVolume': ['ttlTrdQty', 'totalTradedQty', 'volume'],
      'open': ['openPrice', 'o'],
      'high': ['highPrice', 'h'],
      'low': ['lowPrice', 'l'],
      'ltp': ['lastPrice', 'lastTradedPrice'],
      'netChange': ['change', 'changeValue'],
      'percentChange': ['pChange', 'pchg'],
      'close': ['closePrice'],
      'avgPrice': ['averagePrice'],
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
