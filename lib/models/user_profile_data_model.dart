import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/option_holding_model.dart'; // Import new model

class UserProfileDataModel {
  final String uid;
  final String name;
  final String emailId;
  final String mobileNo;
  final DateTime accountCreationTime;
  final double availableFunds;

  final List<StockHoldingModel> stocks;
  final List<StockHoldingModel> positions;
  final List<String> watchlist;

  // ⭐️ NEW LIST
  final List<OptionHoldingModel> optionHoldings;

  UserProfileDataModel({
    required this.uid,
    required this.name,
    required this.emailId,
    required this.mobileNo,
    required this.accountCreationTime,
    required this.availableFunds,
    required this.stocks,
    required this.positions,
    required this.watchlist,
    required this.optionHoldings,
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
    'watchlist': watchlist,
    // ⭐️ SAVE OPTIONS
    'optionHoldings': optionHoldings.map((o) => o.toJson()).toList(),
  };

  factory UserProfileDataModel.fromJson(String uid, Map<String, dynamic> json) {
    List<StockHoldingModel> parseStocks(String key) {
      if (json[key] != null && json[key] is List) {
        return (json[key] as List)
            .map((item) => StockHoldingModel.fromJson(item))
            .toList();
      }
      return [];
    }

    // ⭐️ PARSE OPTIONS
    List<OptionHoldingModel> parseOptions(String key) {
      if (json[key] != null && json[key] is List) {
        return (json[key] as List)
            .map((item) => OptionHoldingModel.fromJson(item))
            .toList();
      }
      return [];
    }

    return UserProfileDataModel(
      uid: uid,
      name: json['name'] as String,
      emailId: json['emailId'] as String,
      mobileNo: json['mobileNo'] as String,
      accountCreationTime:
          DateTime.tryParse(json['accountCreationTime'] ?? '') ??
          DateTime.now(),
      availableFunds: (json['availableFunds'] as num).toDouble(),
      stocks: parseStocks('stocks'),
      positions: parseStocks('positions'),
      watchlist: List<String>.from(json['watchlist'] ?? []),
      optionHoldings: parseOptions('optionHoldings'),
    );
  }
}
