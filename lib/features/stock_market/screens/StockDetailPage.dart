import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// --- Stock Detail UI Implementation with FIXES ---
// ---------------------------------------------------------------------------

class StockDetailPage extends StatelessWidget {
  const StockDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Custom colors extracted from your input and the image
    const Color primaryPink = Color(0xFFF61C7A); // Buy Button/Up change color
    const Color primaryBlue = Color(0xFF3500D4); // Sell Button color
    const Color darkTextColor = Color(
      0xFF03314B,
    ); // Darker text for titles/prices
    const Color spotifyGreen = Color(0xFF1DB954); // Spotify logo color
    const Color lightGreyBg = Color(0xFFF5F5F5); // Statistics card background

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Left arrow button (Exact design)
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "Stock Detail",
          style: TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  // Compute reserved space for system inset + bottom bar
                  final double reservedBottom =
                      MediaQuery.of(context).padding.bottom + 88.0;
                  // Compute available screen height above app bar + reserved bottom
                  final double screenHeight = MediaQuery.of(
                    context,
                  ).size.height;
                  final double topBarHeight =
                      kToolbarHeight + MediaQuery.of(context).padding.top;
                  final double minHeight =
                      (screenHeight - topBarHeight - reservedBottom).clamp(
                        0.0,
                        double.infinity,
                      );

                  return Padding(
                    // Keep small bottom padding (visual gap) but rely on ConstrainedBox
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Company Header ---
                          _buildCompanyHeader(
                            spotifyGreen,
                            primaryPink,
                            darkTextColor,
                          ),
                          const SizedBox(height: 10),

                          // --- Price Details ---
                          _buildPriceDetails(darkTextColor, primaryPink),
                          const SizedBox(height: 20),

                          // --- Time Range Selector (1W is selected) ---
                          _buildTimeRangeSelector(primaryPink),
                          const SizedBox(height: 20),

                          // --- Chart Placeholder (Maintaining vertical space) ---
                          _buildChartPlaceholder(
                            context,
                            primaryPink,
                            primaryBlue,
                          ),
                          const SizedBox(height: 30),

                          // --- Statistics Header ---
                          const Text(
                            "Statistics",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkTextColor,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // --- Statistics Card (Correct Alignment) ---
                          _buildStatisticsCard(lightGreyBg, darkTextColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // --- Bottom Buy/Sell Buttons are placed in Scaffold.bottomNavigationBar
          // (handled below) to avoid layout overflow inside the Column.
        ],
      ),
      // Place the buttons in a fixed-height container inside SafeArea so
      // the layout is consistent and the body can reserve exact space.
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 88.0,
          child: _buildBottomButtons(context, primaryPink, primaryBlue),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // --- UI Component Builders ---
  // ---------------------------------------------------------------------------

  Widget _buildCompanyHeader(
    Color logoColor,
    Color changeColor,
    Color darkTextColor,
  ) {
    return Row(
      children: [
        // Spotify Logo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: logoColor, shape: BoxShape.circle),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SPOT",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkTextColor,
              ),
            ),
            const Text(
              "(Spotify)",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        // Change Percentage Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: changeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.arrow_drop_up, color: changeColor, size: 24),
              Text(
                "0.90%",
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDetails(Color darkTextColor, Color changeColor) {
    const Color greenAccent = Color(0xFF1EAB58);

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price (main large text)
              Text(
                "\$226",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              Text(
                ".90",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              // Daily change (smaller text)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 4),
                child: Text(
                  "+2.02",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: greenAccent,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                "\$224.88",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Text("+2.02", style: TextStyle(fontSize: 16, color: changeColor)),
              const SizedBox(width: 4),
              const Text(
                "(Today)",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(Color selectedColor) {
    const List<String> ranges = ["12H", "1D", "1W", "1M", "1Y"];
    const String selectedRange = "1W";

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ranges.map((range) {
        final bool isSelected = range == selectedRange;
        return Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Column(
            children: [
              Text(
                range,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              if (isSelected)
                Container(
                  width: 25,
                  height: 3,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartPlaceholder(
    BuildContext context,
    Color downColor,
    Color upColor,
  ) {
    // Placeholder that simulates the space and visual complexity of the chart.
    return Container(
      height: 250, // Height matching the original chart's space
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          // Simulated vertical and horizontal grid lines
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              "\$280",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            child: Text(
              "\$260",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          Positioned(
            top: 100,
            left: 0,
            child: Text(
              "\$240",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          Positioned(
            top: 150,
            left: 0,
            child: Text(
              "\$220",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          Positioned(
            top: 200,
            left: 0,
            child: Text(
              "\$200",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),

          // Simplified Candlestick/Volume visualization (for alignment only)
          Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final isDown = index == 1 || index == 3;
                final barHeight = 100.0 + (index * 10) % 50;
                final candleHeight = 20.0 + (index * 5) % 15;
                final color = isDown ? downColor : upColor;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Volume bar placeholder
                    Container(
                      height: barHeight * 0.3,
                      width: 12,
                      color: color.withOpacity(0.5),
                      margin: const EdgeInsets.only(bottom: 2),
                    ),
                    // Candlestick placeholder
                    Container(
                      height: candleHeight,
                      width: 6,
                      color: color,
                      margin: const EdgeInsets.only(bottom: 15),
                    ),
                  ],
                );
              }),
            ),
          ),

          // X-Axis Labels (Mo-Su)
          const Positioned(
            bottom: 0,
            left: 35,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Mo", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Tu", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("We", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Th", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Fr", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Sa", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Su", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          // Tooltip simulation (for image fidelity)
          Positioned(
            top: 120,
            left: MediaQuery.of(context).size.width / 2.5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "\$244.21",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(Color lightGreyBg, Color darkTextColor) {
    final List<Map<String, String>> stats = [
      {"label": "Open", "value": "224.54"},
      {"label": "High", "value": "227.29"},
      {"label": "Low", "value": "224.10"},
      {"label": "Volume", "value": "834,146"},
      {"label": "Avg. Volume", "value": "1,461,009"},
      {"label": "Market Cap", "value": "43.419B"},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGreyBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: GridView.builder(
        // Fix: Use a very high childAspectRatio to prevent the grid cells
        // from stretching vertically, keeping the text compact.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10, // Adjusted vertical spacing
          // Use a fixed tile height so the grid height is predictable and
          // children don't overflow vertically inside the card.
          mainAxisExtent: 60.0,
        ),
        itemBuilder: (context, index) {
          final stat = stats[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat['label']!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              // No highlight: render value with normal styling and no background
              Text(
                stat['value']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: darkTextColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    Color buyColor,
    Color sellColor,
  ) {
    // Buttons are placed in Scaffold.bottomNavigationBar wrapped in SafeArea
    // so they shouldn't add manual bottom safe-area insets themselves.
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: buyColor, // New Pink
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Buy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: sellColor, // New Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Sell",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
