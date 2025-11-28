class OptionHoldingModel {
  final String symbol; // e.g., "NIFTY"
  final String contractSymbol; // e.g., "NIFTY 26000 CE" - Unique ID
  final String optionType; // "CE" or "PE"
  final double strikePrice;
  final String expiryDate;

  final int quantity; // Total Qty (Lots * LotSize)
  final int lotSize;
  final double averagePrice; // Avg Buy Price
  final double investedAmount;
  final double currentLtp; // For Portfolio display tracking

  final String transactionType; // "NRML" or "MIS"
  final String exchange; // "F&O" or "BFO"

  // ⭐️ NEW: TARGET & STOP LOSS
  final double? target;
  final double? stopLoss;

  OptionHoldingModel({
    required this.symbol,
    required this.contractSymbol,
    required this.optionType,
    required this.strikePrice,
    required this.expiryDate,
    required this.quantity,
    required this.lotSize,
    required this.averagePrice,
    required this.investedAmount,
    required this.currentLtp,
    required this.transactionType,
    required this.exchange,
    this.target,
    this.stopLoss,
  });

  OptionHoldingModel copyWith({
    int? quantity,
    double? averagePrice,
    double? investedAmount,
    double? currentLtp,
    double? target,
    double? stopLoss,
  }) {
    return OptionHoldingModel(
      symbol: symbol,
      contractSymbol: contractSymbol,
      optionType: optionType,
      strikePrice: strikePrice,
      expiryDate: expiryDate,
      quantity: quantity ?? this.quantity,
      lotSize: lotSize,
      averagePrice: averagePrice ?? this.averagePrice,
      investedAmount: investedAmount ?? this.investedAmount,
      currentLtp: currentLtp ?? this.currentLtp,
      transactionType: transactionType,
      exchange: exchange,
      // ⭐️ UPDATE OR KEEP EXISTING
      target: target ?? this.target,
      stopLoss: stopLoss ?? this.stopLoss,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'contractSymbol': contractSymbol,
    'optionType': optionType,
    'strikePrice': strikePrice,
    'expiryDate': expiryDate,
    'quantity': quantity,
    'lotSize': lotSize,
    'averagePrice': averagePrice,
    'investedAmount': investedAmount,
    'currentLtp': currentLtp,
    'transactionType': transactionType,
    'exchange': exchange,
    // ⭐️ SAVE NEW FIELDS
    'target': target,
    'stopLoss': stopLoss,
  };

  factory OptionHoldingModel.fromJson(Map<String, dynamic> json) {
    return OptionHoldingModel(
      symbol: json['symbol'] ?? '',
      contractSymbol: json['contractSymbol'] ?? '',
      optionType: json['optionType'] ?? 'CE',
      strikePrice: (json['strikePrice'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiryDate'] ?? '',
      quantity: json['quantity'] ?? 0,
      lotSize: json['lotSize'] ?? 1,
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      investedAmount: (json['investedAmount'] as num?)?.toDouble() ?? 0.0,
      currentLtp: (json['currentLtp'] as num?)?.toDouble() ?? 0.0,
      transactionType: json['transactionType'] ?? 'NRML',
      exchange: json['exchange'] ?? 'F&O',
      // ⭐️ LOAD NEW FIELDS
      target: (json['target'] as num?)?.toDouble(),
      stopLoss: (json['stopLoss'] as num?)?.toDouble(),
    );
  }
}
