class ChargeCalculatorService {
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
