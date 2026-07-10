import 'dart:async';
import 'dart:convert';

import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final String address;
  final LatLng latLng;

  const LocationResult({required this.address, required this.latLng});
}

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key, required this.title, this.initialValue});

  final String title;
  final String? initialValue;

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<_PlacePrediction> _predictions = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _focusNode.requestFocus();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '8',
        'countrycodes': 'in',
        'addressdetails': '1',
      });
      final response = await http.get(
        uri,
        headers: {'Accept-Language': 'en', 'User-Agent': 'AcePool/1.0'},
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        final predictions = results.map((r) {
          final address = r['address'] as Map<String, dynamic>? ?? {};
          final mainText = (r['name'] as String?)?.isNotEmpty == true
              ? r['name'] as String
              : r['display_name'] as String;
          final parts = <String>[];
          for (final key in ['suburb', 'city', 'state']) {
            final val = address[key] as String?;
            if (val != null && val.isNotEmpty) parts.add(val);
          }
          return _PlacePrediction(
            mainText: mainText,
            secondaryText: parts.join(', '),
            fullText: r['display_name'] as String,
            lat: double.tryParse(r['lat']?.toString() ?? ''),
            lng: double.tryParse(r['lon']?.toString() ?? ''),
          );
        }).toList();
        setState(() => _predictions = predictions);
      } else {
        setState(() => _error = 'Search failed (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _select(_PlacePrediction prediction) {
    Navigator.of(context).pop(
      PickedLocation(
        address: prediction.fullText,
        lat: prediction.lat,
        lng: prediction.lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 15, color: AppColors.black87),
            decoration: InputDecoration(
              hintText: 'Search location',
              hintStyle: const TextStyle(color: AppColors.black38),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.grey600,
                size: 20,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.black38,
                        size: 18,
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _predictions = []);
                      },
                    )
                  : null,
            ),
          ),
        ),
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.black,
                  backgroundColor: AppColors.transparent,
                ),
              )
            : null,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: AppColors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.black54),
                    ),
                  ],
                ),
              ),
            )
          : _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.black),
            )
          : _predictions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 40,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _controller.text.isEmpty
                        ? 'Type to search for a location'
                        : 'No results found',
                    style: const TextStyle(
                      color: AppColors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _predictions.length,
              separatorBuilder: (_, i) =>
                  Divider(height: 0, color: AppColors.grey200),
              itemBuilder: (context, i) {
                final p = _predictions[i];
                return InkWell(
                  onTap: () => _select(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.mainText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (p.secondaryText.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  p.secondaryText,
                                  style: const TextStyle(
                                    color: AppColors.black45,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PlacePrediction {
  final String mainText;
  final String secondaryText;
  final String fullText;
  final double? lat;
  final double? lng;

  const _PlacePrediction({
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
    this.lat,
    this.lng,
  });
}
