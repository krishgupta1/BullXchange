import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math; // Used for maxOi

// Model for a single row in the chain
class OptionChainRow {
  final double strikePrice;
  final Map<String, dynamic>? ce; // Call Option data
  final Map<String, dynamic>? pe; // Put Option data

  OptionChainRow({required this.strikePrice, this.ce, this.pe});

  // Factory to parse the clean JSON from your backend
  factory OptionChainRow.fromJson(Map<dynamic, dynamic> json) {
    return OptionChainRow(
      strikePrice: (json['strikePrice'] as num).toDouble(),
      ce: json['ce'] != null ? Map<String, dynamic>.from(json['ce']) : null,
      pe: json['pe'] != null ? Map<String, dynamic>.from(json['pe']) : null,
    );
  }
}

class OptionChainProvider with ChangeNotifier {
  final String symbol; // e.g., "Nifty 50"
  late DatabaseReference _dbRef;
  StreamSubscription<DatabaseEvent>? _dbSubscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  double? _underlyingLtp;
  double? get underlyingLtp => _underlyingLtp;

  double? _underlyingLtpChange;
  double? get underlyingLtpChange => _underlyingLtpChange;

  double? _underlyingLtpPercent;
  double? get underlyingLtpPercent => _underlyingLtpPercent;

  // ✨ NEW FIELDS FOR APP BAR
  String _expiry = '';
  String get expiry => _expiry;
  String _currency = '₹';
  String get currency => _currency;
  // ✨ --- ✨

  List<OptionChainRow> _rows = [];
  List<OptionChainRow> get rows => _rows;

  int? _atmIndex;
  int? get atmIndex => _atmIndex;

  // ✨ NEW: This is the highest OI on the screen,
  // used for scaling the bar graphs.
  double _maxOi = 0;
  double get maxOi => _maxOi;

  OptionChainProvider({required this.symbol}) {
    _dbRef = FirebaseDatabase.instance.ref("option_chain/$symbol");
    _listenToData();
  }

  void _listenToData() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _dbSubscription = _dbRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;

        if (data != null && data is Map) {
          try {
            final mapData = data;

            // ✨ NEW: Parse all the new data from the backend
            _underlyingLtp = (mapData['underlyingLtp'] as num?)?.toDouble();
            _underlyingLtpChange = (mapData['underlyingLtpChange'] as num?)
                ?.toDouble();
            _underlyingLtpPercent = (mapData['underlyingLtpPercent'] as num?)
                ?.toDouble();
            _expiry = mapData['expiry'] as String? ?? '';
            _currency = mapData['currency'] as String? ?? '₹';
            // ✨ --- ✨

            if (mapData['rows'] != null) {
              final List<dynamic> rawRows = mapData['rows'] as List;
              _rows = rawRows
                  .map(
                    (row) =>
                        OptionChainRow.fromJson(row as Map<dynamic, dynamic>),
                  )
                  .toList();
            }

            _calculateAtmAndMaxOi(); // ✨ NEW: Call new helper
            _isLoading = false;
            _error = null;
          } catch (e) {
            _error = "Error parsing data. Is the backend running? \n($e)";
            _isLoading = false;
          }
        } else {
          _error =
              "No option chain data found for '$symbol'. (Waiting for backend...)";
          _isLoading = false;
        }
        notifyListeners(); // Tell the UI to rebuild
      },
      onError: (Object o) {
        _error = "Database connection error: $o";
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ✨ NEW: This helper now finds both ATM and Max OI
  void _calculateAtmAndMaxOi() {
    if (_rows.isEmpty) {
      _atmIndex = null;
      _maxOi = 0;
      return;
    }

    double maxOiFound = 0;
    int foundIndex = -1; // Default to -1 (not found)

    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];

      // 1. Find Max OI
      final double ceOi = (row.ce?['openInterest'] as num?)?.toDouble() ?? 0;
      final double peOi = (row.pe?['openInterest'] as num?)?.toDouble() ?? 0;
      maxOiFound = math.max(maxOiFound, ceOi);
      maxOiFound = math.max(maxOiFound, peOi);

      // 2. Find ATM Index
      // This is now the index of the strike *just below* the LTP
      if (_underlyingLtp != null) {
        if (_rows[i].strikePrice < _underlyingLtp!) {
          // Keep updating the index as long as the strike is below the LTP
          foundIndex = i;
        }
      }
    }

    _atmIndex = foundIndex;
    _maxOi = maxOiFound;
  }

  Future<void> fetchOptionChain() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }
}
