import 'dart:async';
import 'dart:convert';
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
      setState(() { _predictions = []; _error = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'json',
          'limit': '8',
          'countrycodes': 'in',
          'addressdetails': '1',
        },
      );
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
            latLng: LatLng(
              double.parse(r['lat'] as String),
              double.parse(r['lon'] as String),
            ),
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
    Navigator.of(context).pop(LocationResult(
      address: prediction.fullText,
      latLng: prediction.latLng,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            hintText: widget.title,
            hintStyle: const TextStyle(color: Colors.black38),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black38, size: 20),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _predictions = []);
                    },
                  )
                : null,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: _isLoading
              ? const LinearProgressIndicator(minHeight: 2)
              : const Divider(height: 1),
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          : _predictions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 48, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text(
                    _controller.text.isEmpty
                        ? 'Type to search for a location'
                        : 'No results found',
                    style: const TextStyle(color: Colors.black45),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _predictions.length,
              separatorBuilder: (_, i) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (context, i) {
                final p = _predictions[i];
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        size: 18, color: Colors.black54),
                  ),
                  title: Text(
                    p.mainText,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: p.secondaryText.isNotEmpty
                      ? Text(
                          p.secondaryText,
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () => _select(p),
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
  final LatLng latLng;

  const _PlacePrediction({
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
    required this.latLng,
  });
}
