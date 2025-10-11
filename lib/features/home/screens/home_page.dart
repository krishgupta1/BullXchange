import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 🧩 Replace this with your current valid token
  final String jwtToken =
      "eyJhbGciOiJIUzUxMiJ9.eyJ1c2VybmFtZSI6IkFBQU83ODQzOTMiLCJyb2xlcyI6MCwidXNlcnR5cGUiOiJVU0VSIiwidG9rZW4iOiJleUpoYkdjaU9pSlNVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKMWMyVnlYM1I1Y0dVaU9pSmpiR2xsYm5RaUxDSjBiMnRsYmw5MGVYQmxJam9pZEhKaFpHVmZZV05qWlhOelgzUnZhMlZ1SWl3aVoyMWZhV1FpT2pNc0luTnZkWEpqWlNJNklqTWlMQ0prWlhacFkyVmZhV1FpT2lJNE16a3paVEl5T0MweE1ESXhMVE0zTmpJdE9URmtZUzAwWlRNNU1HRTVOVE0yTWpRaUxDSnJhV1FpT2lKMGNtRmtaVjlyWlhsZmRqSWlMQ0p2Ylc1bGJXRnVZV2RsY21sa0lqb3pMQ0p3Y205a2RXTjBjeUk2ZXlKa1pXMWhkQ0k2ZXlKemRHRjBkWE1pT2lKaFkzUnBkbVVpZlN3aWJXWWlPbnNpYzNSaGRIVnpJam9pWVdOMGFYWmxJbjE5TENKcGMzTWlPaUowY21Ga1pWOXNiMmRwYmw5elpYSjJhV05sSWl3aWMzVmlJam9pUVVGQlR6YzRORE01TXlJc0ltVjRjQ0k2TVRjMk1ESTJOalF4T0N3aWJtSm1Jam94TnpZd01UYzVPRE00TENKcFlYUWlPakUzTmpBeE56azRNemdzSW1wMGFTSTZJamMzT0dGaE4yTXhMVGhqWkdVdE5EY3pZaTA0T0RKbExUQm1ZalE0TldaaFlqYzVNeUlzSWxSdmEyVnVJam9pSW4wLkFWVjJodnBxR25teFNjV1ViY01NZ2R6Y1ZDcXZ1dHNMeUROOGpRSWx3UEZ3dmdNUHhXNGxseDZCSjJFQ1F6VkpwdHluV3g3NngwbmNNZElCQ3BZbWZMbzdKLUlQdXhPS0xuYzh2UVR0OGxMbTg3UHNFQlV6MDFrVzRwZWpEZ3ZvNGtqMXlVTnA0Q2xxdUw2WlEzcVZfb0pBWE9NVFRWWlBfc21YVjlPTWpYVSIsIkFQSS1LRVkiOiJOZGNvUFhCSyIsIlgtT0xELUFQSS1LRVkiOmZhbHNlLCJpYXQiOjE3NjAxODAwMTgsImV4cCI6MTc2MDIwNzQwMH0.VgSRbJ5x8f0bfuGoQsBVd8wny9S-QUyPUTvvPfucYi6uwEaAlFNGaMOOfFRwA0v-yILmQhFU_ipML884MGU26Q";

  final String apiKey = "NdcoPXBK";
  final String clientIP = "104.28.222.179";

  bool isLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> allStocks = [];
  List<Map<String, dynamic>> filteredStocks = [];

  final TextEditingController searchController = TextEditingController();

  Future<void> fetchStockData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      allStocks = [];
      filteredStocks = [];
    });

    final url = Uri.parse(
      "https://apiconnect.angelone.in/rest/secure/angelbroking/market/v1/quote/",
    );

    // ✅ Headers with correct Bearer + AngelOne requirements
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $jwtToken",
      "X-UserType": "USER",
      "X-SourceID": "WEB",
      "X-ClientLocalIP": clientIP,
      "X-ClientPublicIP": clientIP,
      "X-MACAddress": "00:00:00:00:00:00",
      "X-PrivateKey": apiKey,
      "Accept": "application/json",
    };

    // ✅ NSE stock tokens
    final body = jsonEncode({
      "mode": "FULL",
      "exchangeTokens": {
        "NSE": ["3045", "11536", "1594", "2885", "467", "5258"],
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final decoded = jsonDecode(response.body);

      print("🔍 Full API Response: $decoded");

      if (response.statusCode != 200 || decoded["success"] == false) {
        setState(() {
          errorMessage =
              "API Error: ${decoded["message"] ?? "Unknown error"} (${decoded["errorCode"] ?? ""})";
        });
        return;
      }

      final data = decoded["data"];

      if (data is Map && data["fetched"] != null) {
        final fetchedData = data["fetched"];
        List<Map<String, dynamic>> parsedList = [];

        if (fetchedData is Map) {
          final nseData = fetchedData["NSE"];
          if (nseData is Map) {
            parsedList = nseData.values
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          } else if (nseData is List) {
            parsedList = nseData
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        } else if (fetchedData is List) {
          parsedList = fetchedData
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        if (parsedList.isEmpty) {
          setState(() {
            errorMessage = "No stock data found.";
          });
        } else {
          setState(() {
            allStocks = parsedList;
            filteredStocks = parsedList;
          });
        }
      } else {
        setState(() {
          errorMessage = "Invalid or empty response format.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void searchStocks(String query) {
    final results = allStocks.where((stock) {
      final symbol = (stock["tradingSymbol"] ?? "").toString().toLowerCase();
      return symbol.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredStocks = results;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchStockData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Market Watch"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            onPressed: fetchStockData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: searchStocks,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by stock symbol (e.g. INFY, TCS, RELIANCE)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredStocks.length,
                    itemBuilder: (context, index) {
                      final stock = filteredStocks[index];
                      return buildStockCard(stock);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildStockCard(Map<String, dynamic> stock) {
    final ltp = stock["ltp"]?.toString() ?? "--";
    final change = stock["netChange"]?.toString() ?? "0";
    final percent = stock["percentChange"]?.toString() ?? "0";
    final positive = (double.tryParse(change) ?? 0) >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text(
            stock["tradingSymbol"] ?? "Unknown",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("LTP: ₹$ltp"),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                change,
                style: TextStyle(
                  color: positive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$percent%",
                style: TextStyle(
                  color: positive ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
