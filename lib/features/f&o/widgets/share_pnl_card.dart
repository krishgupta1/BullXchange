import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SharePnlCard extends StatefulWidget {
  final String symbol;
  final double pnl;
  final double roi;
  final double entryPrice;
  final double lastPrice;
  final bool isIntraday;

  const SharePnlCard({
    super.key,
    required this.symbol,
    required this.pnl,
    required this.roi,
    required this.entryPrice,
    required this.lastPrice,
    required this.isIntraday,
  });

  @override
  State<SharePnlCard> createState() => _SharePnlCardState();
}

class _SharePnlCardState extends State<SharePnlCard> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);
    try {
      // 1. Capture the widget as an image
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // High quality
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/pnl_share_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      // 3. Share the file
      final String text = "Check out my ${widget.roi >= 0 ? 'Profit' : 'P&L'} on BullXchange! 📈 #Trading #BullXchange";
      await Share.shareXFiles([XFile(file.path)], text: text);
    } catch (e) {
      debugPrint("Error sharing P&L: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sharing failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isProfit = widget.pnl >= 0;
    final bool isSuperProfit = widget.roi > 50.0;

    List<Color> gradientColors;
    IconData statusIcon;

    if (isSuperProfit) {
      gradientColors = [
        const Color(0xFF0F0C29),
        const Color(0xFF302B63),
        const Color(0xFF24243E),
      ];
      statusIcon = Icons.rocket_launch_rounded;
    } else if (isProfit) {
      gradientColors = isDark 
          ? [const Color(0xFF1B4D3E), const Color(0xFF0F2027)]
          : [const Color(0xFF00C853).withValues(alpha: 0.9), const Color(0xFF00E676)];
      statusIcon = Icons.trending_up_rounded;
    } else {
      gradientColors = isDark
          ? [const Color(0xFF4D1B1B), const Color(0xFF200F0F)]
          : [const Color(0xFFFF3D00).withValues(alpha: 0.9), const Color(0xFFFF5252)];
      statusIcon = Icons.trending_down_rounded;
    }

    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        children: [
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        statusIcon,
                        size: 250,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "BullXchange",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  widget.isIntraday ? "INTRADAY" : "OPTIONS",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.symbol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          Column(
                            children: [
                              Text(
                                "${isProfit ? '+' : ''}${widget.roi.toStringAsFixed(2)}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                  height: 1,
                                ),
                              ),
                              const Text(
                                "RETURN",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),

                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _detailItem("ENTRY", f.format(widget.entryPrice)),
                                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                                _detailItem("LTP", f.format(widget.lastPrice)),
                                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                                _detailItem(
                                  "PNL",
                                  "${isProfit ? '+' : ''}${f.format(widget.pnl)}",
                                  activeColor: isProfit ? Colors.greenAccent : Colors.orangeAccent,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isSharing ? null : _shareImage,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isSharing 
                                    ? const SizedBox(
                                        width: 18, 
                                        height: 18, 
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                                      )
                                    : const Icon(Icons.share_rounded, size: 18),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isSharing ? "Processing..." : "Share with Friends",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Close button positioned outside the RepaintBoundary so it's not in the share image
          Positioned(
            right: 12,
            top: 12,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, {Color? activeColor}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: activeColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
