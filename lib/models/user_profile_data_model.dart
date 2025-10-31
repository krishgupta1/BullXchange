import 'stock_holding_model.dart'; // Make sure this import is correct

class UserProfileDataModel {
  final String uid;
  final String name;
  final String emailId;
  final String mobileNo;
  final DateTime accountCreationTime;
  final double availableFunds; // <-- ADDED: To track virtual money
  final List<StockHoldingModel> stocks;

  UserProfileDataModel({
    required this.uid,
    required this.name,
    required this.emailId,
    required this.mobileNo,
    required this.accountCreationTime,
    required this.availableFunds, // <-- ADDED
    this.stocks = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'emailId': emailId,
    'mobileNo': mobileNo,
    'accountCreationTime': accountCreationTime.toIso8601String(),
    'availableFunds': availableFunds, // <-- ADDED
    'stocks': stocks.map((s) => s.toJson()).toList(),
  };

  factory UserProfileDataModel.fromJson(String uid, Map<String, dynamic> json) {
    DateTime creationTime;
    final timeData = json['accountCreationTime'];
    if (timeData is String) {
      creationTime = DateTime.parse(timeData);
    } else {
      // Fallback for older data or different formats
      creationTime = DateTime.now();
    }

    return UserProfileDataModel(
      uid: uid,
      name: json['name'] as String,
      emailId: json['emailId'] as String,
      mobileNo: json['mobileNo'] as String,
      accountCreationTime: creationTime,
      // <-- ADDED: Read funds, default to 1 lakh for existing users without this field
      availableFunds: (json['availableFunds'] as num?)?.toDouble() ?? 100000.0,
      stocks:
          (json['stocks'] as List?)
              ?.map(
                (s) => StockHoldingModel.fromJson(Map<String, dynamic>.from(s)),
              )
              .toList() ??
          [],
    );
  }
}
