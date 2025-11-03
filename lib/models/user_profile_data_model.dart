import 'package:bullxchange/models/stock_holding_model.dart';
// NOTE: Assuming you replace the import above with the new, lighter model:
// import 'package:bullxchange/models/watchlist_item_model.dart'; // <--- ASSUMED NEW IMPORT

// WARNING: If you use the code below, you MUST update the import line above
// to use WatchlistItemModel (or whatever you name your light model).

class UserProfileDataModel {
  final String uid;
  final String name;
  final String emailId;
  final String mobileNo;
  final DateTime accountCreationTime;
  final double availableFunds;
  final List<StockHoldingModel> stocks;
  final List<StockHoldingModel> positions;

  // ✨ CHANGE TYPE TO THE MINIMAL MODEL (WatchlistItemModel) HERE! ✨
  final List<StockHoldingModel> watchlist; // <--- This type must be changed

  UserProfileDataModel({
    required this.uid,
    required this.name,
    required this.emailId,
    required this.mobileNo,
    required this.accountCreationTime,
    required this.availableFunds,
    required this.stocks,
    required this.positions,
    // ✨ ADD TO CONSTRUCTOR ✨
    required this.watchlist, // <--- This type must be changed
  });

  UserProfileDataModel copyWith({
    List<StockHoldingModel>? watchlist, // <--- This type must be changed
  }) {
    return UserProfileDataModel(
      uid: uid,
      name: name,
      emailId: emailId,
      mobileNo: mobileNo,
      accountCreationTime: accountCreationTime,
      availableFunds: availableFunds,
      stocks: stocks,
      positions: positions,
      watchlist: watchlist ?? this.watchlist,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'emailId': emailId,
    'mobileNo': mobileNo,
    'accountCreationTime': accountCreationTime.toIso8601String(),
    'availableFunds': availableFunds,
    'stocks': stocks.map((stock) => stock.toJson()).toList(),
    'positions': positions.map((pos) => pos.toJson()).toList(),
    // ✨ JSON SERIALIZATION USES THE WATCHLIST MODEL'S toJson() ✨
    // (This line is correct even with the type change, assuming the new model has toJson)
    'watchlist': watchlist.map((w) => w.toJson()).toList(),
  };

  factory UserProfileDataModel.fromJson(String uid, Map<String, dynamic> json) {
    // Helper to safely parse lists
    // This helper must be updated to use the new model's .fromJson factory
    List<StockHoldingModel> parseHoldings(String key) {
      // <--- Return type must be changed
      if (json[key] != null && json[key] is List) {
        final List<dynamic> jsonData = json[key] as List;
        return jsonData
            .map(
              (item) =>
                  // ✨ USE THE NEW WATCHLIST MODEL'S FROMJSON FACTORY HERE! ✨
                  StockHoldingModel.fromJson(
                    item as Map<String, dynamic>,
                  ), // <--- This model must be changed
            )
            .toList();
      }
      return [];
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
      stocks: parseHoldings('stocks'),
      positions: parseHoldings('positions'),
      // ✨ WATCHLIST PARSING USES THE NEW MODEL'S FACTORY ✨
      watchlist: parseHoldings('watchlist'), // <--- Return type must be changed
    );
  }
}
