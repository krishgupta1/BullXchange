import 'package:flutter/material.dart';

class StockListItemShimmer extends StatelessWidget {
  const StockListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 12,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(width: 150, height: 12, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 50,
                height: 12,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 4),
              ),
              Container(width: 40, height: 12, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
