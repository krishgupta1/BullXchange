import 'package:flutter/foundation.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:bullxchange/api/angel_one_option_chain_service.dart';
import 'package:bullxchange/models/market_overview_data.dart';

class OptionChainRow {
  final double strikePrice;
  final String expiryDate;
  final Map<String, dynamic>? ce;
  final Map<String, dynamic>? pe;

  OptionChainRow({
    required this.strikePrice,
    required this.expiryDate,
    this.ce,
    this.pe,
  });

  factory OptionChainRow.fromMap(
    Map<String, dynamic> map, {
    String defaultExpiry = "",
  }) {
    String exp =
        map['expiryDate']?.toString() ??
        map['expiry']?.toString() ??
        defaultExpiry;

    // Helper to safely convert dynamic maps to Map<String, dynamic>
    Map<String, dynamic>? safeConvert(dynamic data) {
      if (data == null) return null;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    }

    return OptionChainRow(
      strikePrice: double.tryParse(map['strikePrice'].toString()) ?? 0.0,
      expiryDate: exp,
      ce: _normalize(safeConvert(map['CE'])),
      pe: _normalize(safeConvert(map['PE'])),
    );
  }

  static Map<String, dynamic>? _normalize(Map<String, dynamic>? input) {
    if (input == null) return null;
    double getD(String key) =>
        double.tryParse(input[key]?.toString() ?? "0") ?? 0.0;

    // Fix: Add zero-division check for percentage calculations
    double getPercentChange() {
      double pChange = getD('pChange');
      if (pChange != 0) return pChange;

      double percentChange = getD('percentChange');
      if (percentChange != 0) return percentChange;

      // Calculate percent change from netChange if available
      double netChange = getD('netChange');
      double lastPrice = getD('lastPrice');
      if (netChange != 0 && lastPrice > 0) {
        return (netChange / lastPrice) * 100;
      }

      return 0.0;
    }

    return {
      ...input,
      'lastPrice': getD('lastPrice'),
      'openInterest': getD('openInterest'),
      'change': getD('change'),
      'percentChange': getPercentChange(),
      'volume': getD('volume'),
      'totalTradedVolume': getD('totalTradedVolume'),
      'impliedVolatility': getD('impliedVolatility'),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'strikePrice': strikePrice,
      'expiryDate': expiryDate,
      'ce': ce,
      'pe': pe,
    };
  }
}

class OptionChainProvider extends ChangeNotifier {
  final String symbol;
  final AngelOneOptionChainService _apiService = AngelOneOptionChainService();

  OptionChainProvider({required this.symbol});

  bool _isLoading = false;
  String? _errorMessage;
  List<OptionChainRow> _optionChainData = [];
  String? _selectedExpiry;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<OptionChainRow> get optionChainData => _optionChainData;
  String? get selectedExpiry => _selectedExpiry;

  // Additional getters for compatibility
  MarketOverviewData get overviewData => marketOverview;
  bool get isOverviewLoading => _isLoading;
  List<String> get expiryDates => [_selectedExpiry ?? ''];
  List<OptionChainRow> get rows => _optionChainData;
  double get underlyingLtp =>
      0.0; // Will be updated with actual underlying price

  // ATM (At-The-Money) index calculation
  int get atmIndex {
    if (_optionChainData.isEmpty) return 0;

    // Find the strike price closest to the underlying price
    // For now, return the middle index as a placeholder
    return _optionChainData.length ~/ 2;
  }

  // Computed properties
  List<OptionChainRow> get callOptions =>
      _optionChainData.where((row) => row.ce != null).toList();

  List<OptionChainRow> get putOptions =>
      _optionChainData.where((row) => row.pe != null).toList();

  // Market overview calculations
  MarketOverviewData get marketOverview {
    if (_optionChainData.isEmpty) {
      return MarketOverviewData();
    }

    // Create a simple overview data with basic market info
    // The option chain specific data will be handled separately
    return MarketOverviewData(
      currentPrice: 0.0, // Will be updated with actual underlying price
      priceChange: 0.0,
      percentChange: 0.0,
      dayLow: 0.0,
      dayHigh: 0.0,
      yearLow: 0.0,
      yearHigh: 0.0,
      open: 0.0,
      prevClose: 0.0,
    );
  }

  // Public methods
  Future<void> fetchOptionChain({String? expiryDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLog.i("🔄 Fetching option chain for $symbol");

      final data = await _apiService.fetchOptionChainData(
        symbol: symbol,
        expiryDate: expiryDate ?? '',
      );

      _optionChainData = data
          .map((item) => OptionChainRow.fromMap(item))
          .toList();
      _selectedExpiry = expiryDate;

      // Sort by strike price
      _optionChainData.sort((a, b) => a.strikePrice.compareTo(b.strikePrice));

      AppLog.i(
        "✅ Successfully fetched ${_optionChainData.length} option chain rows",
      );
    } catch (e) {
      _errorMessage = "Failed to fetch option chain: $e";
      AppLog.e("❌ Error in option chain: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchOptionChain(expiryDate: _selectedExpiry);
  }

  void setSelectedExpiry(String expiry) {
    if (_selectedExpiry != expiry) {
      _selectedExpiry = expiry;
      fetchOptionChain(expiryDate: expiry);
    }
  }

  // Alias for setSelectedExpiry for compatibility
  void selectExpiry(String expiry) {
    setSelectedExpiry(expiry);
  }

  Future<void> fetchMarketOverview() async {
    // This method is for compatibility - market overview is already calculated
    await fetchOptionChain(expiryDate: _selectedExpiry);
  }

  // Private helper methods
  double _calculateMaxPain() {
    if (_optionChainData.isEmpty) return 0.0;

    double maxPain = 0.0;
    double minPainValue = double.infinity;

    for (var row in _optionChainData) {
      double painValue = 0.0;

      // Calculate pain at this strike price
      for (var testRow in _optionChainData) {
        double callLoss = 0.0;
        double putLoss = 0.0;

        if (testRow.ce != null) {
          double intrinsicValue = (testRow.strikePrice - row.strikePrice).clamp(
            0.0,
            double.infinity,
          );
          callLoss = (testRow.ce!['lastPrice'] ?? 0.0) - intrinsicValue;
          callLoss = callLoss.clamp(
            0.0,
            double.infinity,
          ); // Only positive losses
        }

        if (testRow.pe != null) {
          double intrinsicValue = (row.strikePrice - testRow.strikePrice).clamp(
            0.0,
            double.infinity,
          );
          putLoss = (testRow.pe!['lastPrice'] ?? 0.0) - intrinsicValue;
          putLoss = putLoss.clamp(0.0, double.infinity); // Only positive losses
        }

        double oi =
            (testRow.ce?['openInterest'] ?? 0.0) +
            (testRow.pe?['openInterest'] ?? 0.0);
        painValue += (callLoss + putLoss) * oi;
      }

      if (painValue < minPainValue) {
        minPainValue = painValue;
        maxPain = row.strikePrice;
      }
    }

    return maxPain;
  }

  double _findSupport() {
    if (_optionChainData.isEmpty) return 0.0;

    double maxPutOI = 0.0;
    double supportLevel = 0.0;

    for (var row in _optionChainData) {
      if (row.pe != null) {
        double putOI = row.pe!['openInterest'] ?? 0.0;
        if (putOI > maxPutOI) {
          maxPutOI = putOI;
          supportLevel = row.strikePrice;
        }
      }
    }

    return supportLevel;
  }

  double _findResistance() {
    if (_optionChainData.isEmpty) return 0.0;

    double maxCallOI = 0.0;
    double resistanceLevel = 0.0;

    for (var row in _optionChainData) {
      if (row.ce != null) {
        double callOI = row.ce!['openInterest'] ?? 0.0;
        if (callOI > maxCallOI) {
          maxCallOI = callOI;
          resistanceLevel = row.strikePrice;
        }
      }
    }

    return resistanceLevel;
  }
}
