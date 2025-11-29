import 'package:bullxchange/models/instrument_model.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart'; // 💡 Import Shimmer for the effect

class SmartLogo extends StatefulWidget {
  final Instrument instrument;
  const SmartLogo({super.key, required this.instrument, required int radius});

  @override
  State<SmartLogo> createState() => _SmartLogoState();
}

class _SmartLogoState extends State<SmartLogo> {
  final Dio _dio = Dio();

  bool _logoExists = false;
  bool _isLoading = true;
  late final String logoUrl;

  @override
  void initState() {
    super.initState();
    final companyName = widget.instrument.name.split(' ')[0].toLowerCase();
    logoUrl = 'https://logo.clearbit.com/$companyName.com';
    _checkLogo();
  }

  Future<void> _checkLogo() async {
    try {
      // Use dio.head to check if the logo exists without downloading it entirely
      final response = await _dio.head(logoUrl);
      if (mounted) {
        setState(() {
          // Check for status code 200 (OK)
          _logoExists = response.statusCode == 200;
          _isLoading = false;
        });
      }
    } on DioException {
      // Catch Dio-specific exceptions (e.g., 404, network error)
      if (mounted) {
        setState(() {
          _logoExists = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Catch any other unexpected errors
      if (mounted) {
        setState(() {
          _logoExists = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 MODIFIED: Show Shimmer while _isLoading is true
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            // Use BoxShape.circle to match the final alternate logo shape
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    // Display actual logo if it exists
    if (_logoExists) {
      return Image.network(logoUrl, width: 40, height: 40);
    } else {
      // Display initial letter fallback logo
      final letter = widget.instrument.name.isNotEmpty
          ? widget.instrument.name[0].toUpperCase()
          : '?';
      final color = Colors
          .primaries[widget.instrument.name.hashCode % Colors.primaries.length];
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}


