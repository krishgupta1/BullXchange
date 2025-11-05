// lib/provider/future_option_instrument_provider.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../api/angel_one_api_service.dart';
import '../models/future_option_instrument_model.dart';
// You can re-enable your real logger if you have one
// import '../utils/logger.dart';

List<dynamic> _parseFnOJson(String jsonString) {
  return jsonDecode(jsonString) as List<dynamic>;
}

class FutureOptionProvider with ChangeNotifier {
  final AngelOneApiService _apiService = AngelOneApiService();

  List<FutureOptionInstrument> _mainIndexFutures = [];
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _refreshTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FutureOptionInstrument> get mainIndexFutures => _mainIndexFutures;

  // These are the 'name' values we'll find in the JSON for FUTIDX instruments
  final List<String> _targetUnderlying = [
    'NIFTY',
    'BANKNIFTY',
    'FINNIFTY',
    'MIDCPNIFTY',
    'SENSEX',
    'BANKEX',
  ];

  FutureOptionProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/OpenAPIScripMaster.json',
      );
      final List<dynamic> data = await compute(_parseFnOJson, jsonString);

      final List<FutureOptionInstrument> allNfoFutures = data
          .map((item) => item as Map<String, dynamic>)
          .where((item) {
            // Filter for Index Futures
            final exchSeg = item['exch_seg'];
            final instType = item['instrumenttype'];
            return (exchSeg == 'NFO' || exchSeg == 'BFO') &&
                instType == 'FUTIDX';
          })
          .map((item) => FutureOptionInstrument.fromJson(item))
          .toList();

      // AppLog.i("Found ${allNfoFutures.length} total index futures.");

      final List<FutureOptionInstrument> foundIndices = [];
      for (var underlying in _targetUnderlying) {
        // Find the near-month contract for each index
        final instrument = _findNearMonthFuture(allNfoFutures, underlying);
        if (instrument != null) {
          foundIndices.add(instrument);
        } else {
          // AppLog.w("Could not find near-month future for $underlying");
        }
      }

      _mainIndexFutures = foundIndices;
      // AppLog.i("✅ Loaded ${_mainIndexFutures.length} main index futures.");

      await _startPeriodicFetches();
    } catch (e, stackTrace) {
      // AppLog.e("❌ ERROR in F&O _initialize: $e\n$stackTrace");
      print("❌ ERROR in F&O _initialize: $e\n$stackTrace"); // Keep error logs
      _errorMessage = "Failed to load F&O data.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to find the future for a specific underlying with the soonest expiry
  FutureOptionInstrument? _findNearMonthFuture(
    List<FutureOptionInstrument> allFutures,
    String underlyingSymbol,
  ) {
    try {
      // Find all futures for the given underlying (e.g., all 'NIFTY' futures)
      final matchingFutures = allFutures
          .where((inst) => inst.underlyingSymbol == underlyingSymbol)
          .toList();

      if (matchingFutures.isEmpty) return null;

      // Sort them by expiry date (ascending)
      matchingFutures.sort((a, b) => a.expiry.compareTo(b.expiry));

      // Get the one with the soonest (first) expiry date
      return matchingFutures.first;
    } catch (e) {
      // AppLog.e("Error finding near-month future for $underlyingSymbol: $e");
      print("Error finding near-month future for $underlyingSymbol: $e");
      return null;
    }
  }

  Future<void> _startPeriodicFetches() async {
    await _fetchEssentialData();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _fetchEssentialData();
    });
  }

  /// Fetches data for only the 6 main index futures
  Future<void> _fetchEssentialData() async {
    if (_mainIndexFutures.isEmpty) return;
    await _updateInstruments(_mainIndexFutures);
  }

  Future<void> _updateInstruments(
    List<FutureOptionInstrument?> instruments,
  ) async {
    final uniqueInstruments = instruments
        .whereType<FutureOptionInstrument>()
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

      for (var instrument in _mainIndexFutures) {
        final mapped = liveDataMap[instrument.token];
        if (mapped != null) {
          instrument.liveData = _sanitizeLiveData(mapped);
        }
      }
      notifyListeners();
    }
  }

  Map<String, dynamic> _sanitizeLiveData(Map<String, dynamic> rawData) {
    final sanitizedData = Map<String, dynamic>.from(rawData);
    // Normalize common alternate keys returned by different API variants.
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

    // Now coerce numeric values
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
