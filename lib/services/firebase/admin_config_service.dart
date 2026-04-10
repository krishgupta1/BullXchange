import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullxchange/utils/logger.dart';

class AdminConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the Angel One configuration from Firestore.
  /// Path: admin_config/angelone
  Future<Map<String, dynamic>?> fetchAngelOneConfig() async {
    try {
      AppLog.i("🔍 Fetching Angel One config from Firestore...");
      final doc = await _firestore.collection('admin_config').doc('angelone').get();
      
      if (doc.exists && doc.data() != null) {
        AppLog.i("✅ Angel One config fetched successfully");
        return doc.data();
      } else {
        AppLog.w("⚠️ Angel One config document does not exist in Firestore");
        return null;
      }
    } catch (e) {
      AppLog.e("❌ Error fetching Angel One config: $e");
      return null;
    }
  }
}
