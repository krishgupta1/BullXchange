import 'dart:math';
import 'dart:ui' as ui;
import 'package:bullxchange/models/instrument_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NativeStockChart extends StatefulWidget {
  final Instrument instrument;
  const NativeStockChart({super.key, required this.instrument});

  @override
  State<NativeStockChart> createState() => _NativeStockChartState();
}

class _NativeStockChartState extends State<NativeStockChart>
    with SingleTickerProviderStateMixin {
  // Data
  List<FlSpot> _spots = [];
  List<FlSpot> _volumeSpots = [];
  List<FlSpot> _ma20Spots = [];
  
  // UI State
  bool _isLoading = true;
  String _selectedTimeframe = '1D';
  final bool _showVolume = true;
  
  // Interaction State
  double? _touchedPrice;
  int? _touchedIndex; 

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Colors
  final Color _positiveColor = const Color(0xFF00E676);
  final Color _negativeColor = const Color(0xFFFF5252);
  late Color _chartColor; 

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeData();
  }

  @override
  void didUpdateWidget(NativeStockChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instrument.liveData['ltp'] != widget.instrument.liveData['ltp'] ||
        oldWidget.instrument.liveData['tradeVolume'] != widget.instrument.liveData['tradeVolume']) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final netChange = (widget.instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
    _chartColor = netChange >= 0 ? _positiveColor : _negativeColor;

    final ltp = (widget.instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    if (ltp == 0.0) {
      _isLoading = true;
      return;
    }

    _calculateChartDataPoints(ltp);
    _isLoading = false;
  }

  void _refreshData() {
    final netChange = (widget.instrument.liveData['netChange'] as num?)?.toDouble() ?? 0.0;
    final ltp = (widget.instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    if (ltp == 0.0) return;

    _calculateChartDataPoints(ltp);

    if (mounted) {
      setState(() {
        _chartColor = netChange >= 0 ? _positiveColor : _negativeColor;
        _isLoading = false;
      });
    }
  }

  void _calculateChartDataPoints(double ltp) {
    final volume = (widget.instrument.liveData['tradeVolume'] as num?)?.toInt() ?? 0;
    final high = (widget.instrument.liveData['high'] as num?)?.toDouble() ?? ltp;
    final low = (widget.instrument.liveData['low'] as num?)?.toDouble() ?? ltp;
    final open = (widget.instrument.liveData['open'] as num?)?.toDouble() ?? ltp;

    final random = Random(widget.instrument.symbol.hashCode ^ _selectedTimeframe.hashCode);
    int dataPoints = _selectedTimeframe == '1D' ? 100 : 80;
    
    List<FlSpot> newSpots = [];
    List<FlSpot> newVolSpots = [];
    List<double> rawPrices = [];
    
    double currentPrice = open;
    double volatility = (high - low) / ltp * 0.4; 
    if (volatility == 0) volatility = 0.02;

    for (int i = 0; i < dataPoints; i++) {
      double randomWalk = (random.nextDouble() - 0.5) * volatility * ltp;
      if (i > 0) {
        double momentum = (currentPrice - rawPrices[i-1]) * 0.2;
        currentPrice += momentum;
      }
      currentPrice += randomWalk;
      rawPrices.add(currentPrice);
    }

    double generatedEnd = rawPrices.last;
    double gap = ltp - generatedEnd;

    for (int i = 0; i < dataPoints; i++) {
      double progress = i / (dataPoints - 1);
      double correctedPrice = rawPrices[i] + (gap * progress);
      newSpots.add(FlSpot(i.toDouble(), correctedPrice));

      double baseVolume = volume / dataPoints;
      double volumeValue = baseVolume * (0.5 + random.nextDouble());
      newVolSpots.add(FlSpot(i.toDouble(), volumeValue));
    }

    _spots = newSpots;
    _volumeSpots = newVolSpots;
    _ma20Spots = _calculateMovingAverage(_spots, 20);
  }

  List<FlSpot> _calculateMovingAverage(List<FlSpot> spots, int period) {
    if (spots.length < period) return [];
    List<FlSpot> maSpots = [];
    for (int i = period - 1; i < spots.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += spots[i - j].y;
      }
      maSpots.add(FlSpot(spots[i].x, sum / period));
    }
    return maSpots;
  }

  // --- FIXED DATE LOGIC: Clamps 1D chart to 3:30 PM ---
  String _getDateLabel(int index) {
    final now = DateTime.now();
    if (_spots.isEmpty) return "";
    
    final int totalPoints = _spots.length;
    final double percent = index / (totalPoints - 1); 

    if (_selectedTimeframe == '1D') {
      // 1. Define Market Hours
      final marketOpen = DateTime(now.year, now.month, now.day, 9, 15);
      final marketClose = DateTime(now.year, now.month, now.day, 15, 30); // 3:30 PM

      // 2. Determine effective End Time
      // If it's 7 PM, clamp to 3:30 PM. If it's 11 AM, use 11 AM.
      DateTime chartEndTime = now.isAfter(marketClose) ? marketClose : now;
      
      // Edge case: If called before 9:15 AM
      if (chartEndTime.isBefore(marketOpen)) chartEndTime = marketOpen;

      // 3. Calculate total minutes in the displayed chart
      final int totalMinutes = chartEndTime.difference(marketOpen).inMinutes;
      
      // 4. Calculate exact time for this specific index
      final int minutesToAdd = (totalMinutes * percent).toInt();
      final time = marketOpen.add(Duration(minutes: minutesToAdd));
      
      final period = time.hour >= 12 ? 'PM' : 'AM';
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      return "$hour:${time.minute.toString().padLeft(2, '0')} $period";
    } 
    else if (_selectedTimeframe == '1W') {
      final int daysFromEnd = (7 * (1 - percent)).toInt();
      final date = now.subtract(Duration(days: daysFromEnd));
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return "${weekdays[date.weekday - 1]} ${date.day}";
    }
    else if (_selectedTimeframe == '1M') {
       final int daysFromEnd = (30 * (1 - percent)).toInt();
       final date = now.subtract(Duration(days: daysFromEnd));
       return "${date.day} ${_getMonthName(date.month)}";
    }
    else {
      final int daysFromEnd = (365 * (1 - percent)).toInt();
      final date = now.subtract(Duration(days: daysFromEnd));
      return "${date.day} ${_getMonthName(date.month)} '${date.year.toString().substring(2)}";
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ltp = (widget.instrument.liveData['ltp'] as num?)?.toDouble() ?? 0.0;
    
    final double minY = _calculateMinY();
    final double maxY = _calculateMaxY();

    if (_isLoading) {
      return const SizedBox(height: 250, child: Center(child: SizedBox()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeframeSelector(theme),
        const SizedBox(height: 12),
        
        SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildPriceChart(theme, ltp, minY, maxY),
                        
                        if (_spots.isNotEmpty)
                          _buildFloatingBadge(
                            _touchedPrice ?? ltp, 
                            availableHeight, 
                            minY, 
                            maxY,
                            isLive: _touchedPrice == null,
                          ),
                      ],
                    );
                  }
                ),
              ),
              
              if (_showVolume) ...[
                const SizedBox(height: 4),
                Expanded(
                  flex: 1,
                  child: _buildVolumeChart(theme),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector(ThemeData theme) {
    final timeframes = ['1D', '1W', '1M', '3M', '1Y', '5Y'];
    return SizedBox(
      height: 28, 
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: timeframes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tf = timeframes[index];
          final isSelected = tf == _selectedTimeframe;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeframe = tf;
                _refreshData(); 
              });
            },
            child: Text(
              tf,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceChart(ThemeData theme, double ltp, double minY, double maxY) {
    final double lineY = _touchedPrice ?? ltp;
    final Color lineColor = _touchedPrice != null 
        ? theme.colorScheme.onSurface.withOpacity(0.5)
        : _chartColor.withOpacity(0.8); 
        
    final double dataMaxX = _spots.last.x;
    final double viewMaxX = dataMaxX + (dataMaxX * 0.15); 

    return LineChart(
      duration: Duration.zero, 
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if ((value - lineY).abs() < (maxY - minY) * 0.1) return const SizedBox();
                if (value <= minY || value >= maxY) return const SizedBox(); 

                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    value.toStringAsFixed(2),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: theme.colorScheme.onSurface.withOpacity(0.2), strokeWidth: 1),
                FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                   return FlDotCirclePainter(
                     radius: 4, 
                     color: theme.colorScheme.surface, 
                     strokeWidth: 2, 
                     strokeColor: _chartColor
                   );
                }),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
             getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
             fitInsideHorizontally: true,
             getTooltipItems: (List<LineBarSpot> touchedSpots) {
               return touchedSpots.map((spot) {
                 final dateStr = _getDateLabel(spot.x.toInt());
                 return LineTooltipItem(
                   dateStr,
                   TextStyle(
                     color: theme.colorScheme.onSurface,
                     fontWeight: FontWeight.bold,
                     fontSize: 10,
                   ),
                 );
               }).toList();
             }
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
             if (event is FlPanEndEvent || event is FlTapUpEvent) {
               setState(() {
                 _touchedPrice = null;
                 _touchedIndex = null;
               });
             } else {
               if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
                 final spot = response.lineBarSpots![0];
                 setState(() {
                   _touchedPrice = spot.y;
                   _touchedIndex = spot.spotIndex;
                 });
               }
             }
          }
        ),
        
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: false,
            color: _chartColor,
            barWidth: 1.5,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _chartColor.withOpacity(0.1),
                  _chartColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: lineY, 
              color: lineColor,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
        minY: minY,
        maxY: maxY,
        maxX: viewMaxX, 
      ),
    );
  }

  static List<LineTooltipItem?> _emptyTooltip(List<LineBarSpot> spots) {
    return spots.map((_) => null).toList();
  }

  Widget _buildFloatingBadge(double price, double height, double minY, double maxY, {bool isLive = true}) {
    if (maxY == minY) return const SizedBox();

    double relativeY = (price - minY) / (maxY - minY);
    double yPos = height * (1 - relativeY);
    double centeredY = (yPos - 9.5).clamp(0.0, height - 24.0);
    
    final bg = isLive ? _chartColor : const Color(0xFF303030);
    final fg = Colors.white;

    return Positioned(
      right: 0, 
      top: centeredY, 
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isLive)
            FadeTransition(
              opacity: _pulseAnimation,
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle, boxShadow: [BoxShadow(color: bg.withOpacity(0.5), blurRadius: 4)]),
              ),
            ),
          
          Container(width: 6, height: 1.5, color: bg),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2, offset: const Offset(0, 1))
              ]
            ),
            child: Text(
              price.toStringAsFixed(2),
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.1, 
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChart(ThemeData theme) {
    if (_spots.isEmpty) return const SizedBox();

    final double dataMaxX = _spots.last.x;
    final double viewMaxX = dataMaxX + (dataMaxX * 0.15);

    return Padding(
      padding: EdgeInsets.zero, 
      child: BarChart(
        duration: Duration.zero,
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false), 
          barGroups: _volumeSpots.asMap().entries.map((entry) {
            final index = entry.key;
            final volume = entry.value.y;
            final maxVolume = _volumeSpots.isEmpty ? 1.0 : _volumeSpots.map((e) => e.y).reduce(max);
            final normalized = maxVolume == 0 ? 0.0 : volume / maxVolume;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: normalized,
                  color: (entry.value.y > (index > 0 ? _volumeSpots[index-1].y : 0) 
                      ? _positiveColor 
                      : _negativeColor).withOpacity(0.2), 
                  width: 2,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _calculateMinY() {
    if (_spots.isEmpty) return 0;
    double minVal = _spots.map((e) => e.y).reduce(min);
    return minVal - (minVal * 0.005); 
  }

  double _calculateMaxY() {
    if (_spots.isEmpty) return 100;
    double maxVal = _spots.map((e) => e.y).reduce(max);
    return maxVal + (maxVal * 0.005);
  }
}