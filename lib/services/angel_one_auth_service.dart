import 'package:dio/dio.dart';
import 'package:bullxchange/services/firebase/angel_one_service.dart';
import 'package:bullxchange/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class AngelOneAuthService {
  static final Dio _dio = Dio();
  
  /// Authenticate with Angel One and store JWT token in Firebase
  static Future<Map<String, dynamic>> authenticateAndStoreToken({
    required String password,
    required String totp,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 Starting Angel One authentication...');
      }
      
      // Angel One login endpoint
      const String loginUrl = "https://apiconnect.angelone.in/rest/auth/angelbroking/user/v1/loginByPassword";
      
      final Map<String, dynamic> loginData = {
        "clientcode": "AAAO784393", // From your Firebase config
        "password": password,
        "totp": totp,
      };
      
      final response = await _dio.post(
        loginUrl,
        data: loginData,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-UserType": "USER",
            "X-SourceID": "WEB",
            "X-ClientLocalIP": ApiConstants.clientIP,
            "X-ClientPublicIP": ApiConstants.clientIP,
            "X-MACAddress": "00:00:00:00:00:00",
            "X-PrivateKey": ApiConstants.apiKey,
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['status'] == true && data['data'] != null) {
          final jwtToken = data['data']['jwtToken'] as String?;
          final clientCode = data['data']['clientcode'] as String?;
          
          if (jwtToken != null && jwtToken.isNotEmpty) {
            // Store JWT token in Firebase
            final success = await AngelOneService.storeJwtToken(jwtToken, clientCode ?? "AAAO784393");
            
            if (success) {
              if (kDebugMode) {
                print('✅ Angel One authentication successful and token stored in Firebase');
              }
              return {
                'success': true,
                'message': 'Authentication successful! JWT token stored in Firebase.',
                'jwtToken': jwtToken,
                'clientCode': clientCode,
              };
            } else {
              if (kDebugMode) {
                print('❌ Failed to store JWT token in Firebase');
              }
              return {
                'success': false,
                'message': 'Authentication successful but failed to store JWT token in Firebase.',
              };
            }
          } else {
            return {
              'success': false,
              'message': 'JWT token not found in response.',
            };
          }
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Authentication failed.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Invalid response from Angel One API.',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred.';
      if (e.response?.data != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        errorMessage = errorData?['message'] ?? errorMessage;
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      if (kDebugMode) {
        print('❌ Angel One authentication error: $errorMessage');
      }
      
      return {
        'success': false,
        'message': 'Authentication failed: $errorMessage',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during Angel One authentication: $e');
      }
      
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }
  
  /// Check if Angel One is authenticated by trying to get JWT token from Firebase
  static Future<bool> isAuthenticated() async {
    try {
      final jwtToken = await AngelOneService.getJwtToken();
      return jwtToken != null && jwtToken.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking Angel One authentication status: $e');
      }
      return false;
    }
  }
  
  /// Get authentication status message
  static Future<String> getAuthStatusMessage() async {
    final isAuth = await isAuthenticated();
    return isAuth ? 'Authenticated' : 'Not Authenticated';
  }
}
