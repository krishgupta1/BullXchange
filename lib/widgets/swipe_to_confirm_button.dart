import 'package:flutter/material.dart';

class SwipeToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String label;
  final Color color;
  final IconData icon;

  const SwipeToConfirmButton({
    super.key,
    required this.onConfirmed,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  State<SwipeToConfirmButton> createState() => _SwipeToConfirmButtonState();
}

class _SwipeToConfirmButtonState extends State<SwipeToConfirmButton> {
  double _position = 0.0;
  bool _isConfirmed = false;
  final double _height = 56.0;
  final double _padding = 4.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxDrag = maxWidth - _height; // Width minus knob size

        return Container(
          height: _height,
          width: maxWidth,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Text Background
              Center(
                child: Opacity(
                  opacity: (1 - (_position / maxDrag)).clamp(0.0, 1.0),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // 2. Active Track Fill
              Container(
                width: _position + _height,
                height: _height,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Or a fill color if desired
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              // 3. Sliding Knob
              Positioned(
                left: _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _position += details.delta.dx;
                      // Clamp position
                      if (_position < 0) _position = 0;
                      if (_position > maxDrag) _position = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isConfirmed) return;
                    // Threshold check (e.g., 70% of width)
                    if (_position > maxDrag * 0.7) {
                      setState(() {
                        _position = maxDrag;
                        _isConfirmed = true;
                      });
                      widget.onConfirmed();
                      // Optional: Reset after delay if validation fails externally
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _isConfirmed = false;
                            _position = 0;
                          });
                        }
                      });
                    } else {
                      // Snap back
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    height: _height - (_padding * 2),
                    width: _height - (_padding * 2),
                    margin: EdgeInsets.only(left: _padding),
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
