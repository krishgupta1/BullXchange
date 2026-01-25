import 'package:bullxchange/features/stock_market/widgets/native_stock_chart.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

class ChartsTab extends StatelessWidget {
  const ChartsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OptionChainProvider>(
      builder: (context, provider, child) {
        // 1. Create Instrument
        final instrument = Instrument(
          token: '',
          symbol: provider.symbol,
          name: provider.symbol,
          exchSeg: 'NSE',
          expiry: '',
          strike: '',
          instrumentType: 'INDEX',
          lotSize: '1',
          outstandingShares: 0,
          avgVolume: 0,
        );

        // 2. Populate Data
        if (provider.overviewData != null) {
          instrument.liveData = {
            'ltp': provider.overviewData!.currentPrice,
            'netChange': provider.overviewData!.priceChange,
            'high': provider.overviewData!.dayHigh,
            'low': provider.overviewData!.dayLow,
            'open': provider.overviewData!.open,
            'tradeVolume': 0, 
          };
        } else {
          instrument.liveData = {
            'ltp': 0.0, 'netChange': 0.0, 'high': 0.0, 'low': 0.0, 'open': 0.0, 'tradeVolume': 0,
          };
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. Pro Header
                _buildProfessionalHeader(provider.symbol, provider.overviewData),
                
                const SizedBox(height: 24), // Tighter spacing
                
                // 4. The Chart
                // Use Expanded so it fills the remaining space without scrolling issues
                Expanded(
                  child: NativeStockChart(instrument: instrument),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalHeader(String symbol, dynamic overviewData) {
    if (overviewData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
        ],
      );
    }

    final double price = overviewData.currentPrice;
    final double change = overviewData.priceChange;
    final double percent = overviewData.percentChange;
    final bool isPositive = change >= 0;
    
    // Premium Finance Colors (Neon-ish)
    final Color trendColor = isPositive 
        ? const Color(0xFF26A69A) // Kite/Binance Green
        : const Color(0xFFEF5350); // Kite/Binance Red

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symbol Label (Small & Subtle)
        Text(
          symbol.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500], // Professional Grey
            letterSpacing: 1.0,
          ),
        ),
        
        const SizedBox(height: 6),
        
        // Price Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Big Price
            Text(
              '₹${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 34, // Large Hero Text
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.0,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Change Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.12), // Subtle glow background
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: trendColor,
                    size: 20,
                  ),
                  Text(
                    '${change.abs().toStringAsFixed(2)} (${percent.abs().toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold, // Bold for readability
                      color: trendColor,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}