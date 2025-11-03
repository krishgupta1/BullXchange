import 'package:bullxchange/models/stock_holding_model.dart';

class UserProfileDataModel {
  final String uid;
  final String name;
  final String emailId;
  final String mobileNo;
  final DateTime accountCreationTime;
  final double availableFunds;

  final List<StockHoldingModel> stocks; // These are your 'Holdings'
  final List<StockHoldingModel> positions; // These are for 'Intraday'
  final List<String> watchlist; // These are for bookmarked stock tokens

  UserProfileDataModel({
    required this.uid,
    required this.name,
    required this.emailId,
    required this.mobileNo,
    required this.accountCreationTime,
    required this.availableFunds,
    required this.stocks,
    required this.positions,
    required this.watchlist, // <-- ADDED
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'emailId': emailId,
    'mobileNo': mobileNo,
    'accountCreationTime': accountCreationTime.toString(),
    'availableFunds': availableFunds,
    'stocks': stocks.map((stock) => stock.toJson()).toList(),
    'positions': positions.map((pos) => pos.toJson()).toList(),
    'watchlist': watchlist, // <-- ADDED
  };

  factory UserProfileDataModel.fromJson(String uid, Map<String, dynamic> json) {
    // Helper to safely parse lists of StockHoldingModel
    List<StockHoldingModel> parseHoldings(String key) {
      if (json[key] != null && json[key] is List) {
        final List<dynamic> jsonData = json[key] as List;
        return jsonData
            .map(
              (item) =>
                  StockHoldingModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return []; // Return empty list if null or not a list
    }

    return UserProfileDataModel(
      uid: uid,
      name: json['name'] as String,
      emailId: json['emailId'] as String,
      mobileNo: json['mobileNo'] as String,
      accountCreationTime: DateTime.parse(
        json['accountCreationTime'] as String,
      ),
      availableFunds: (json['availableFunds'] as num).toDouble(),

      // Use the safe helper
      stocks: parseHoldings('stocks'),
      positions: parseHoldings('positions'),

      // Helper to safely parse list of String
      watchlist: List<String>.from(json['watchlist'] ?? []), // <-- ADDED
    );
  }
}
