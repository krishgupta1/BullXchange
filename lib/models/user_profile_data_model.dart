// lib/models/user_profile_data_model.dart
import 'package:bullxchange/models/stock_holding_model.dart';

class UserProfileDataModel {
  final String uid;
  final String name;
  final String emailId;
  final String mobileNo;
  final DateTime accountCreationTime;
  final double availableFunds;
  final List<StockHoldingModel> stocks; // These are your 'Holdings'

  // --- 1. ADD THIS NEW FIELD ---
  final List<StockHoldingModel> positions; // These are for 'Intraday'

  UserProfileDataModel({
    required this.uid,
    required this.name,
    required this.emailId,
    required this.mobileNo,
    required this.accountCreationTime,
    required this.availableFunds,
    required this.stocks,

    // --- 2. ADD TO CONSTRUCTOR ---
    required this.positions,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'emailId': emailId,
    'mobileNo': mobileNo,
    'accountCreationTime': accountCreationTime.toIso8601String(),
    'availableFunds': availableFunds,
    'stocks': stocks.map((stock) => stock.toJson()).toList(),

    // --- 3. ADD TO JSON ---
    'positions': positions.map((pos) => pos.toJson()).toList(),
  };

  factory UserProfileDataModel.fromJson(String uid, Map<String, dynamic> json) {
    // Helper to safely parse lists
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

      // --- 4. UPDATE FROMJSON LOGIC ---
      stocks: parseHoldings('stocks'),
      positions: parseHoldings('positions'),
    );
  }
}
