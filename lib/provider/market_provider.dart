// lib/provider/market_provider.dart

import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/services/scrip_master_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';

class StocksProvider extends ChangeNotifier {
  final String jwtToken;
  final String apiKey;
  final String clientIP;

  StocksProvider({
    required this.jwtToken,
    required this.apiKey,
    required this.clientIP,
  }) {
    _initialize();
  }

  late final Dio _dio;
  Timer? _refreshTimer;

  bool isLoading = false;
  String? errorMessage;

  List<Instrument> allStocks = [];
  List<Instrument> filteredStocks = [];
  List<Instrument> displayedStocks = [];

  final int batchSize = 50;
  int currentIndex = 0;
  bool isLoadingMore = false;

  // ---------------------------------------------------------------------------
  // ✅ NEW HELPER: Checks if Market is Open
  // ---------------------------------------------------------------------------
  bool get _isMarketOpen {
    final now = DateTime.now();

    // Check Weekend
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }

    // Check Time (09:15 - 15:30)
    final int totalMinutes = now.hour * 60 + now.minute;
    final int openMinutes = 9 * 60 + 15; // 09:15 AM
    final int closeMinutes = 15 * 60 + 30; // 03:30 PM

    return totalMinutes >= openMinutes && totalMinutes < closeMinutes;
  }

  // ---------------------------------------------------------------------------
  // ✅ UPDATED INITIALIZE
  // ---------------------------------------------------------------------------
  void _initialize() {
    _initializeDio();
    loadInstruments().then((_) {
      if (allStocks.isNotEmpty) {
        // 1. Always fetch data once immediately
        _updateVisibleStocksData();

        // 2. Start timer only if Market is Open
        if (_isMarketOpen) {
          print("🟢 Market Open. Starting StocksProvider timer (5s).");

          _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
            // Check inside timer
            if (!_isMarketOpen) {
              print("🔴 Market Closed. Stopping StocksProvider timer.");
              timer.cancel();
              // One last update to ensure data is fresh
              _updateVisibleStocksData();
            } else {
              _updateVisibleStocksData();
            }
          });
        } else {
          print("🔴 Market Closed. StocksProvider timer not started.");
        }
      }
    });
  }

  void _initializeDio() {
    final baseOptions = BaseOptions(
      baseUrl:
          "https://apiconnect.angelone.in/rest/secure/angelbroking/market/v1",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        "Authorization": "Bearer $jwtToken",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-UserType": "USER",
        "X-SourceID": "WEB",
        "X-ClientLocalIP": clientIP,
        "X-ClientPublicIP": clientIP,
        "X-MACAddress": "00:00:00:00:00:00",
        "X-PrivateKey": apiKey,
      },
    );
    _dio = Dio(baseOptions);
  }

  Future<void> loadInstruments() async {
    isLoading = true;
    notifyListeners();

    try {
      final allInstruments = await ScripMasterService.instance.getInstruments();

      final equityList = allInstruments
          .where((inst) => inst.exchSeg == 'NSE' && inst.symbol.endsWith('-EQ'))
          .toList();

      allStocks = equityList;
      filteredStocks = equityList;
      _resetLazyLoading();
      errorMessage = null;
    } catch (e, st) {
      errorMessage = "Error loading local data.";
      print("Error loading instruments: $e \n$st");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------- Lazy Loading -----------------------------
  void _resetLazyLoading() {
    currentIndex = 0;
    displayedStocks.clear();
    _loadMoreItems();
  }

  void _loadMoreItems() {
    if (isLoadingMore) return;
    isLoadingMore = true;

    final nextIndex = currentIndex + batchSize;
    final end = nextIndex > filteredStocks.length;
    final nextBatch = filteredStocks.sublist(
      currentIndex,
      end ? filteredStocks.length : nextIndex,
    );

    displayedStocks.addAll(nextBatch);
    currentIndex += nextBatch.length;
    isLoadingMore = false;

    // Fetch live data for the new batch
    fetchAndUpdateData(nextBatch.map((s) => s.token).toList());
    notifyListeners();
  }

  void loadMoreItems() {
    _loadMoreItems();
  }

  // ----------------------------- Search -----------------------------
  void searchStocks(String query) {
    final searchQuery = query.toLowerCase();
    if (searchQuery.isEmpty) {
      filteredStocks = allStocks;
    } else {
      filteredStocks = allStocks.where((s) {
        return s.symbol.toLowerCase().contains(searchQuery) ||
            s.name.toLowerCase().contains(searchQuery);
      }).toList();
    }
    _resetLazyLoading();
  }

  // ----------------------------- Live Data Fetching -----------------------------
  Future<void> fetchAndUpdateData(List<String> tokens) async {
    if (tokens.isEmpty) return;

    final payload = {
      "mode": "FULL",
      "exchangeTokens": {"NSE": tokens},
    };

    try {
      final response = await _dio.post("/market/v1/market_data", data: payload);

      final List<dynamic> fetchedData =
          response.data?['data']?['fetched'] ?? [];

      for (var quote in fetchedData) {
        final token = quote['symbolToken'].toString();

        final instrumentIndex = displayedStocks.indexWhere(
          (i) => i.token == token,
        );

        if (instrumentIndex != -1) {
          final instrument = displayedStocks[instrumentIndex];

          instrument.liveData = {
            'ltp': (quote['ltp'] as num?)?.toDouble(),
            'change': (quote['netChange'] as num?)?.toDouble(),
            'percentChange': (quote['percentChange'] as num?)?.toDouble(),
          };
        }
      }

      errorMessage = null;
    } on DioException catch (e) {
      errorMessage =
          "Failed to fetch live data: ${e.response?.statusCode ?? e.message}";
      print("Dio Error during fetch: ${e.message}");
    } catch (e, st) {
      print("CRITICAL ERROR: $e \n$st");
      errorMessage = "Data update failed!";
    } finally {
      notifyListeners();
    }
  }

  void _updateVisibleStocksData() {
    final tokens = displayedStocks
        .map((s) => s.token)
        .where((t) => t.isNotEmpty)
        .toList();
    fetchAndUpdateData(tokens);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
