// Helper intentionally simplified as part of reverting API-name feature.
// It provides minimal, predictable fallbacks so the app displays the
// original symbol/name behavior if this file is still imported anywhere.

import 'package:bullxchange/models/instrument_model.dart';

String companyDisplayNameForInstrument(Instrument instrument) {
  // Return the symbol (cleaned) first. If that's empty, use the scrip master name.
  final cleaned = instrument.symbol.replaceAll('-EQ', '').trim();
  if (cleaned.isNotEmpty) return cleaned;
  if (instrument.name.trim().isNotEmpty) return instrument.name.trim();
  return '';
}

String companyDisplayNameForHolding({
  required String stockSymbol,
  required String stockName,
}) {
  final cleaned = stockSymbol.replaceAll('-EQ', '').trim();
  if (cleaned.isNotEmpty) return cleaned;
  if (stockName.trim().isNotEmpty) return stockName.trim();
  return '';
}
