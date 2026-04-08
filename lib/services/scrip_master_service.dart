import 'dart:convert';
import 'dart:io';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// Centralized service for loading and caching ScripMaster data.
/// Downloads fresh data from Angel One daily and falls back to bundled asset.
class ScripMasterService {
  static ScripMasterService? _instance;
  static ScripMasterService get instance =>
      _instance ??= ScripMasterService._();

  ScripMasterService._();

  List<Instrument>? _cachedInstruments;

  static const String _downloadUrl =
      'https://margincalculator.angelbroking.com/OpenAPI_File/files/OpenAPIScripMaster.json';
  static const String _cacheFileName = 'OpenAPIScripMaster_cached.json';

  /// Returns cached instruments, or loads them (download first, then fallback).
  Future<List<Instrument>> getInstruments({bool forceRefresh = false}) async {
    // Return cached if available and not forcing refresh
    if (_cachedInstruments != null && !forceRefresh) {
      return _cachedInstruments!;
    }

    // Try to load from local cache file first (if downloaded today)
    if (!forceRefresh) {
      final cached = await _loadFromLocalCache();
      if (cached != null) {
        _cachedInstruments = cached;
        AppLog.i(
          '✅ Loaded ${cached.length} instruments from local cache',
        );
        return _cachedInstruments!;
      }
    }

    // Try downloading fresh data
    final downloaded = await _downloadAndCache();
    if (downloaded != null) {
      _cachedInstruments = downloaded;
      AppLog.i(
        '✅ Loaded ${downloaded.length} instruments from fresh download',
      );
      return _cachedInstruments!;
    }

    // Fallback to bundled asset
    final bundled = await _loadFromBundledAsset();
    _cachedInstruments = bundled;
    AppLog.i(
      '✅ Loaded ${bundled.length} instruments from bundled asset (fallback)',
    );
    return _cachedInstruments!;
  }

  /// Clear the in-memory cache (useful for forcing a refresh)
  void clearCache() {
    _cachedInstruments = null;
  }

  /// Try to load from locally cached file (if downloaded today)
  Future<List<Instrument>?> _loadFromLocalCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_cacheFileName');

      if (!await file.exists()) return null;

      // Check if file was modified today
      final lastModified = await file.lastModified();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final fileDate = DateTime(
        lastModified.year,
        lastModified.month,
        lastModified.day,
      );

      if (fileDate.isBefore(today)) {
        AppLog.i('📅 Local cache is stale (from $fileDate), will re-download');
        return null;
      }

      final jsonString = await file.readAsString();
      final List<dynamic> data = jsonDecode(jsonString);
      return data
          .map((e) => Instrument.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLog.w('⚠️ Failed to load local cache: $e');
      return null;
    }
  }

  /// Download fresh ScripMaster data from Angel One
  Future<List<Instrument>?> _downloadAndCache() async {
    try {
      AppLog.i('🔄 Downloading fresh ScripMaster data...');
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));

      final response = await dio.get(_downloadUrl);

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> data;
        if (response.data is String) {
          data = jsonDecode(response.data);
        } else if (response.data is List) {
          data = response.data;
        } else {
          AppLog.w('⚠️ Unexpected response type: ${response.data.runtimeType}');
          return null;
        }

        AppLog.i('✅ Downloaded ${data.length} instruments');

        // Save to local cache
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$_cacheFileName');
          final jsonString = jsonEncode(data);
          await file.writeAsString(jsonString);
          AppLog.i('💾 Saved ScripMaster to local cache');
        } catch (e) {
          AppLog.w('⚠️ Failed to save cache: $e');
        }

        return data
            .map((e) => Instrument.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLog.w('⚠️ Failed to download ScripMaster: $e');
    }
    return null;
  }

  /// Load from bundled asset as final fallback
  Future<List<Instrument>> _loadFromBundledAsset() async {
    final s = await rootBundle.loadString('assets/OpenAPIScripMaster.json');
    final List<dynamic> d = jsonDecode(s);
    return d
        .map((e) => Instrument.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
