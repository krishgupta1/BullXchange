// ✨ NEW, MORE COMPLEX LOGO WIDGET (USING DIO) ✨
import 'package:bullxchange/models/instrument_model.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // 1. Import Dio

class SmartLogo extends StatefulWidget {
  final Instrument instrument;
  const SmartLogo({super.key, required this.instrument});

  @override
  State<SmartLogo> createState() => _SmartLogoState();
}

class _SmartLogoState extends State<SmartLogo> {
  // 2. Create a Dio instance
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
      // 3. Use dio.head to make the network request
      final response = await _dio.head(logoUrl);
      if (mounted) {
        setState(() {
          _logoExists = response.statusCode == 200;
          _isLoading = false;
        });
      }
    } on DioException {
      // 4. Catch Dio-specific exceptions
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
    if (_isLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      );
    }

    if (_logoExists) {
      // Image.network uses http internally, which is fine.
      // The pre-check is what we converted to dio.
      return Image.network(logoUrl, width: 40, height: 40);
    } else {
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
