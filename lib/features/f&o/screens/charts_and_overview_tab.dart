import 'package:bullxchange/features/stock_market/widgets/native_stock_chart.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/provider/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../widgets/market_range_slider.dart';

class ChartsAndOverviewTab extends StatelessWidget {
  const ChartsAndOverviewTab({super.key});

  String _formatNum(double? val) {
    if (val == null || val == 0) return "-";
    return NumberFormat("#,##0.00", "en_US").format(val);
  }

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
          body: RefreshIndicator(
            onRefresh: () async => await provider.fetchOptionChain(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. Professional Header
                  _buildProfessionalHeader(provider.symbol, provider.overviewData),
                  
                  const SizedBox(height: 24),
                  
                  // 4. The Chart (Fixed height)
                  SizedBox(
                    height: 300,
                    child: NativeStockChart(instrument: instrument),
                  ),
                  
                  // 5. Overview Section
                  if (provider.overviewData != null) _buildOverviewSection(provider),
                ],
              ),
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
                color: trendColor.withValues(alpha: 0.12), // Subtle glow background
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

  Widget _buildOverviewSection(OptionChainProvider provider) {
    final data = provider.overviewData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Text(
              "Market Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
          ],
        ),
        
        const SizedBox(height: 20),

        // Performance Section
        Row(
          children: [
            const Text(
              "Performance",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.trending_up, size: 18, color: Colors.grey[600]),
          ],
        ),
        const SizedBox(height: 20),

        // Today's Range
        _RangeLabels(
          labelLow: "Today's Low",
          labelHigh: "Today's High",
          valLow: data.dayLow,
          valHigh: data.dayHigh,
        ),
        const SizedBox(height: 8),
        MarketRangeSlider(
          low: data.dayLow,
          high: data.dayHigh,
          current: data.currentPrice,
        ),

        const SizedBox(height: 24),

        // 52 Week Range
        _RangeLabels(
          labelLow: "52 Week Low",
          labelHigh: "52 Week High",
          valLow: data.yearLow,
          valHigh: data.yearHigh,
        ),
        const SizedBox(height: 8),
        MarketRangeSlider(
          low: data.yearLow,
          high: data.yearHigh,
          current: data.currentPrice,
        ),

        const SizedBox(height: 24),
        const Divider(color: Colors.grey, thickness: 0.2),
        const SizedBox(height: 16),

        // Open & Prev Close
        Row(
          children: [
            Expanded(
              child: _StatItem(label: "Open", value: _formatNum(data.open)),
            ),
            Expanded(
              child: _StatItem(
                label: "Prev. Close",
                value: _formatNum(data.prevClose),
                alignEnd: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(color: Colors.grey, thickness: 0.2),

        // Additional Stats
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: "Day Change", 
                value: "${data.priceChange >= 0 ? '+' : ''}${_formatNum(data.priceChange)}"
              ),
            ),
            Expanded(
              child: _StatItem(
                label: "% Change",
                value: "${data.percentChange >= 0 ? '+' : ''}${data.percentChange.toStringAsFixed(2)}%",
                alignEnd: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(color: Colors.grey, thickness: 0.2),

        // Lists
        _ListRow(title: "${provider.symbol} Companies"),
        _ListRow(title: "${provider.symbol} ETFs"),
      ],
    );
  }
}

// --- Helper Widgets ---

class _RangeLabels extends StatelessWidget {
  final String labelLow, labelHigh;
  final double valLow, valHigh;
  const _RangeLabels({
    required this.labelLow,
    required this.labelHigh,
    required this.valLow,
    required this.valHigh,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat("#,##0.00", "en_US");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labelLow,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              valLow == 0 ? "-" : f.format(valLow),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              labelHigh,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              valHigh == 0 ? "-" : f.format(valHigh),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final bool alignEnd;
  const _StatItem({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  final String title;
  const _ListRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
        Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
      ],
    );
  }
}
