// lib/models/user_profile_data_model.dart
import 'stock_holding_model.dart'; // Import the detailed transaction model

class UserProfileDataModel {
  final String uid; 
  final String name; 
  final String emailId; 
  final String mobileNo; 
  final DateTime accountCreationTime; // CURR TIME OF USER CREATED ACCOUNT
  
  // This array holds transaction records (detailed StockHoldingModel objects).
  final List<StockHoldingModel> stocks; 

  UserProfileDataModel({
    required this.uid,
    required this.name,
    required this.emailId,
    required this.mobileNo,
    required this.accountCreationTime,
    this.stocks = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'emailId': emailId,
        'mobileNo': mobileNo,
        'accountCreationTime': accountCreationTime.toIso8601String(), 
        'stocks': stocks.map((s) => s.toJson()).toList(),
      };

  factory UserProfileDataModel.fromJson(String uid, Map<String, dynamic> json) {
    DateTime creationTime;
    final timeData = json['accountCreationTime'];
    if (timeData is String) {
        creationTime = DateTime.parse(timeData);
    } else {
        creationTime = DateTime.now();
    }

    return UserProfileDataModel(
      uid: uid,
      name: json['name'] as String,
      emailId: json['emailId'] as String,
      mobileNo: json['mobileNo'] as String,
      accountCreationTime: creationTime,
      stocks: (json['stocks'] as List?)
              ?.map((s) => StockHoldingModel.fromJson(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
    );
  }
}
