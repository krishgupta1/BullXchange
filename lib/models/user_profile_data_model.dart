import 'package:bullxchange/models/stock_holding_model.dart';
import 'package:bullxchange/models/option_holding_model.dart';

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
  final List<OptionHoldingModel> optionHoldings;

  // ⭐️ NEW FIELDS FOR REFERRAL SYSTEM
  final String? myReferralCode; // The code this user shares
  final String? referredBy; // The code this user used to sign up

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
    // Add to constructor
    this.myReferralCode,
    this.referredBy,
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
    'optionHoldings': optionHoldings.map((o) => o.toJson()).toList(),
    // ⭐️ SAVE NEW FIELDS TO FIREBASE
    'myReferralCode': myReferralCode,
    'referredBy': referredBy,
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
      // Added safety checks (?? '') to prevent crashes if data is missing
      name: json['name'] as String? ?? '',
      emailId: json['emailId'] as String? ?? '',
      mobileNo: json['mobileNo'] as String? ?? '',
      accountCreationTime:
          DateTime.tryParse(json['accountCreationTime'] ?? '') ??
          DateTime.now(),
      availableFunds: (json['availableFunds'] as num?)?.toDouble() ?? 0.0,
      stocks: parseStocks('stocks'),
      positions: parseStocks('positions'),
      watchlist: List<String>.from(json['watchlist'] ?? []),
      optionHoldings: parseOptions('optionHoldings'),
      // ⭐️ READ NEW FIELDS FROM FIREBASE
      myReferralCode: json['myReferralCode'] as String?,
      referredBy: json['referredBy'] as String?,
    );
  }
}
