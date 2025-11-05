// lib/models/future_option_instrument_model.dart

class FutureOptionInstrument {
  final String token;
  final String symbol;
  final String name;
  final String exchSeg;
  final String instrumentType;
  final String expiry;
  final double strikePrice;
  final int lotSize;
  final String underlyingSymbol;

  Map<String, dynamic> liveData = {};

  FutureOptionInstrument({
    required this.token,
    required this.symbol,
    required this.name,
    required this.exchSeg,
    required this.instrumentType,
    required this.expiry,
    required this.strikePrice,
    required this.lotSize,
    required this.underlyingSymbol,
  });

  factory FutureOptionInstrument.fromJson(Map<String, dynamic> json) {
    // Helper to parse numbers that might be strings or numbers
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return FutureOptionInstrument(
      token: json['token'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchSeg: json['exch_seg'] ?? '',

      // --- F&O Specific Fields ---
      instrumentType: json['instrumenttype'] ?? '',
      expiry: json['expiry_date'] ?? '',
      strikePrice: parseDouble(json['strike_price']),
      lotSize: parseInt(json['lot_size']),

      //
      // --- 🔽 THIS IS THE FIX 🔽 ---
      //
      // We are using 'name' because 'underlying' was returning an empty string.
      // If 'name' doesn't work, try 'symbol'.
      underlyingSymbol: json['name'] ?? '',
      //
      // --- 🔼 END OF FIX 🔼 ---
      //
    );
  }
}
