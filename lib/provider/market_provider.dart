// lib/provider/market_provider.dart

import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/utils/json_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  void _initialize() {
    _initializeDio();
    loadInstruments().then((_) {
      if (allStocks.isNotEmpty) {
        _updateVisibleStocksData();
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _updateVisibleStocksData(),
        );
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
      final String jsonString = await rootBundle.loadString(
        'assets/OpenAPIScripMaster.json',
      );
      final List<dynamic> data = await compute(parseJson, jsonString);

      final equityList = data
          .map((item) => Instrument.fromJson(item as Map<String, dynamic>))
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

  // ----------------------------- Live Data Fetching (The Fix) -----------------------------
  Future<void> fetchAndUpdateData(List<String> tokens) async {
    if (tokens.isEmpty) return;

    final payload = {
      "mode": "FULL",
      "exchangeTokens": {"NSE": tokens},
    };

    try {
      final response = await _dio.post("/market/v1/market_data", data: payload);

      // Safe access to nested JSON structure
      final List<dynamic> fetchedData =
          response.data?['data']?['fetched'] ?? [];

      for (var quote in fetchedData) {
        final token = quote['symbolToken'].toString();

        final instrumentIndex = displayedStocks.indexWhere(
          (i) => i.token == token,
        );

        if (instrumentIndex != -1) {
          final instrument = displayedStocks[instrumentIndex];

          // ⭐️ FIX: Safely cast the incoming values to num/double
          // to prevent 'String is not a subtype of int' and 'String is not a subtype of double' errors.
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
      // Keep this block for final debugging, as it tells you the exact line number.
      print("====================================");
      print("CRITICAL UNKNOWN ERROR: $e");
      print("STACK TRACE: $st");
      print("====================================");

      errorMessage = "Data update failed! (Check console for error details.)";
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
