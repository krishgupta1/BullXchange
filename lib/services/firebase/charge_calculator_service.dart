class ChargeCalculatorService {
  // ---------------------------------------------------------------------------
  // 1. STOCK (EQUITY) CALCULATIONS
  // ---------------------------------------------------------------------------

  /// Calculates all charges for a BUY transaction (Delivery).
  Map<String, double> calculateBuyCharges(double tradeValue) {
    if (tradeValue <= 0) return _emptyCharges();

    const brokerage = 0.0;
    final stt = 0.001 * tradeValue;
    final exchangeCharges = 0.0000345 * tradeValue;
    final sebiCharges = 0.00001 * tradeValue;
    final stampDuty = 0.00015 * tradeValue;
    final gst = 0.18 * (brokerage + exchangeCharges);

    final totalCharges =
        brokerage + stt + exchangeCharges + sebiCharges + stampDuty + gst;

    return {
      'brokerage': brokerage,
      'stt': stt,
      'exchangeCharges': exchangeCharges,
      'sebiCharges': sebiCharges,
      'stampDuty': stampDuty,
      'gst': gst,
      'total': totalCharges,
    };
  }

  /// Calculates all charges for a SELL transaction (Delivery).
  Map<String, double> calculateSellCharges(double tradeValue) {
    if (tradeValue <= 0) return _emptyCharges();

    const brokerage = 0.0;
    final stt = 0.001 * tradeValue;
    final exchangeCharges = 0.0000345 * tradeValue;
    final sebiCharges = 0.00001 * tradeValue;
    const stampDuty = 0.0; // Stamp duty is 0 on sell
    final gst = 0.18 * (brokerage + exchangeCharges);

    final totalCharges =
        brokerage + stt + exchangeCharges + sebiCharges + stampDuty + gst;

    return {
      'brokerage': brokerage,
      'stt': stt,
      'exchangeCharges': exchangeCharges,
      'sebiCharges': sebiCharges,
      'stampDuty': stampDuty,
      'gst': gst,
      'total': totalCharges,
    };
  }

  // ---------------------------------------------------------------------------
  // 2. OPTION (F&O) CALCULATIONS
  // ---------------------------------------------------------------------------

  /// STT is only applicable on SELL side for Options (on premium value)
  Map<String, double> calculateOptionCharges(double tradeValue, bool isBuy) {
    if (tradeValue <= 0) return _emptyCharges();

    // Mock Brokerage: Flat ₹20 per order
    const brokerage = 20.0;

    // STT: 0.0625% on Sell only
    final stt = isBuy ? 0.0 : (0.000625 * tradeValue);

    // Exchange Txn: ~0.05%
    final exchangeCharges = 0.0005 * tradeValue;

    // SEBI
    final sebiCharges = 0.000001 * tradeValue;

    // Stamp Duty (Buy Only): ~0.003%
    final stampDuty = isBuy ? (0.00003 * tradeValue) : 0.0;

    final gst = 0.18 * (brokerage + exchangeCharges);

    final totalCharges =
        brokerage + stt + exchangeCharges + sebiCharges + stampDuty + gst;

    return {
      'brokerage': brokerage,
      'stt': stt,
      'exchangeCharges': exchangeCharges,
      'sebiCharges': sebiCharges,
      'stampDuty': stampDuty,
      'gst': gst,
      'total': totalCharges,
    };
  }

  Map<String, double> _emptyCharges() {
    return {
      'brokerage': 0.0,
      'stt': 0.0,
      'exchangeCharges': 0.0,
      'sebiCharges': 0.0,
      'stampDuty': 0.0,
      'gst': 0.0,
      'total': 0.0,
    };
  }
}
