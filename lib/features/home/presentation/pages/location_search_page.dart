import 'dart:async';

import 'package:acepool/core/services/places_service.dart';
import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/address/domain/entities/address_record.dart';
import 'package:acepool/features/address/presentation/bloc/addresses_bloc.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationResult {
  final String address;
  final LatLng latLng;

  const LocationResult({required this.address, required this.latLng});
}

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({
    super.key,
    required this.title,
    this.initialValue,
    this.biasLat,
    this.biasLng,
  });

  final String title;
  final String? initialValue;
  final double? biasLat;
  final double? biasLng;

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _places = PlacesService();
  late final AddressesBloc _addressesBloc;

  List<_PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _isResolvingSelection = false;
  String? _error;
  Timer? _debounce;
  late String _sessionToken;

  @override
  void initState() {
    super.initState();
    _addressesBloc = sl<AddressesBloc>()..add(const AddressesStarted());
    _sessionToken = PlacesService.newSessionToken();
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
    _addressesBloc.close();
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
    _debounce = Timer(const Duration(seconds: 1), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _places.autocomplete(
        query,
        sessionToken: _sessionToken,
        biasLat: widget.biasLat,
        biasLng: widget.biasLng,
      );
      if (!mounted) return;
      setState(() {
        _predictions = results
            .map(
              (r) => _PlacePrediction(
                placeId: r.placeId,
                mainText: r.mainText,
                secondaryText: r.secondaryText,
                fullText: r.description,
              ),
            )
            .toList();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _select(_PlacePrediction prediction) async {
    setState(() => _isResolvingSelection = true);
    final details = await _places.getPlaceDetails(
      prediction.placeId,
      sessionToken: _sessionToken,
    );
    if (!mounted) return;
    setState(() => _isResolvingSelection = false);

    if (details == null) {
      setState(
        () => _error = 'Could not resolve that location. Please try again.',
      );
      return;
    }

    Navigator.of(context).pop(
      PickedLocation(
        address: details.formattedAddress.isNotEmpty
            ? details.formattedAddress
            : prediction.fullText,
        lat: details.lat,
        lng: details.lng,
      ),
    );
  }

  void _selectSavedAddress(AddressRecord address) {
    Navigator.of(context).pop(
      PickedLocation(
        address: address.address,
        lat: address.lat,
        lng: address.lng,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Home':
        return Icons.home_outlined;
      case 'Office':
        return Icons.business_outlined;
      default:
        return Icons.location_on_outlined;
    }
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
              // Scoped to just this icon (via the controller's own
              // ValueListenable) so typing never triggers a full-page
              // rebuild, which was interrupting the text field's focus.
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.black38,
                      size: 18,
                    ),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _predictions = []);
                    },
                  );
                },
              ),
            ),
          ),
        ),
        bottom: _isLoading || _isResolvingSelection
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
      body: BlocBuilder<AddressesBloc, AddressesState>(
        bloc: _addressesBloc,
        builder: (context, addressState) {
          if (_error != null) {
            return Center(
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
            );
          }

          final query = _controller.text.toLowerCase().trim();
          final matchingSaved = addressState.addresses.where((a) {
            if (query.isEmpty) return true;
            return a.category.toLowerCase().contains(query) ||
                a.address.toLowerCase().contains(query);
          }).toList();

          if (_isLoading && _predictions.isEmpty && matchingSaved.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.black),
            );
          }

          if (query.isEmpty &&
              matchingSaved.isEmpty &&
              addressState.status == AddressesStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.black),
            );
          }

          if (matchingSaved.isEmpty && _predictions.isEmpty) {
            return Center(
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
                    query.isEmpty
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
            );
          }

          return ListView(
            children: [
              if (matchingSaved.isNotEmpty) ...[
                if (query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'SAVED PLACES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey600,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ...matchingSaved.map((address) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _selectSavedAddress(address),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
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
                                  child: Icon(
                                    _getCategoryIcon(address.category),
                                    size: 20,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        address.category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        address.address,
                                        style: const TextStyle(
                                          color: AppColors.black45,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 0, color: AppColors.grey200),
                      ],
                    )),
              ],
              if (_predictions.isNotEmpty) ...[
                if (matchingSaved.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'SEARCH RESULTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey600,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ..._predictions.map((p) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _isResolvingSelection ? null : () => _select(p),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                        ),
                        Divider(height: 0, color: AppColors.grey200),
                      ],
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;

  const _PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });
}
