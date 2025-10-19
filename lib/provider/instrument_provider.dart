import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../api/angel_one_api_service.dart';
import '../models/instrument_model.dart';

List<dynamic> _parseJson(String jsonString) {
  return jsonDecode(jsonString) as List<dynamic>;
}

class InstrumentProvider with ChangeNotifier {
  // This instance is now your dio-based service
  final AngelOneApiService _apiService = AngelOneApiService();

  List<Instrument> _allInstruments = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Instrument> get allNSEStocks {
    return _allInstruments.where((stock) {
      if (stock.exchSeg != 'NSE' ||
          !stock.symbol.endsWith('-EQ') ||
          stock.name.isEmpty) {
        return false;
      }
      final baseSymbol = stock.symbol.replaceAll('-EQ', '');
      final lowerCaseName = stock.name.toLowerCase();
      if (baseSymbol.contains(RegExp(r'[0-9]'))) return false;
      const excludedKeywords = [
        'etf',
        'bees',
        'nifty',
        'gold',
        'bond',
        'debenture',
        'index',
        'pref',
      ];
      if (excludedKeywords.any((keyword) => lowerCaseName.contains(keyword)))
        return false;
      if (!RegExp(r'^[A-Z]+$').hasMatch(baseSymbol) || baseSymbol.length < 3)
        return false;
      return true;
    }).toList();
  }

  Instrument? get nifty50 => _allInstruments.firstWhere(
    (inst) => inst.symbol == 'Nifty 50',
    orElse: () => Instrument.fromJson({}),
  );
  Instrument? get bankNifty => _allInstruments.firstWhere(
    (inst) => inst.symbol == 'Nifty Bank',
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

      await _startPeriodicFetches();
    } catch (e, stackTrace) {
      print("❌ ERROR in _initialize: $e\n$stackTrace");
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

  Future<void> _fetchEssentialData() async {
    // Call 1: For indices
    await _updateInstruments([nifty50, bankNifty]);

    // Call 2: For stocks
    await _updateInstruments(allNSEStocks.take(200).toList());
  }

  Future<void> _updateInstruments(List<Instrument?> instruments) async {
    final uniqueInstruments = instruments
        .whereType<Instrument>()
        .toSet()
        .toList();
    if (uniqueInstruments.isEmpty) return;

    final Map<String, List<String>> tokensByExchange = {};
    for (var inst in uniqueInstruments) {
      tokensByExchange.putIfAbsent(inst.exchSeg, () => []).add(inst.token);
    }

    final liveDataList = await _apiService.fetchLiveMarketData(
      tokensByExchange,
    );

    if (liveDataList.isNotEmpty) {
      final liveDataMap = {
        for (var stock in liveDataList)
          if (stock['symbolToken'] is String)
            stock['symbolToken'] as String: stock,
      };

      for (var instrument in _allInstruments) {
        if (liveDataMap.containsKey(instrument.token)) {
          instrument.liveData = _sanitizeLiveData(
            liveDataMap[instrument.token]!,
          );
        }
      }
      notifyListeners();
    }
  }

  Future<void> fetchLiveDataFor(List<Instrument> instruments) async {
    await _updateInstruments(instruments);
  }

  Map<String, dynamic> _sanitizeLiveData(Map<String, dynamic> rawData) {
    final sanitizedData = Map<String, dynamic>.from(rawData);
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
