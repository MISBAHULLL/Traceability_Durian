import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/cahyadsn_region_service.dart';
import '../data/farmer_repository.dart';

// [FE - Component Rendering] Screen ini adalah form pembuatan kebun baru —
// field wajib divalidasi sebelum disimpan ke FarmerRepository, dan kebun
// baru langsung tersedia di dropdown AddBatchScreen via notifyListeners.
/// Layar form untuk membuat kebun durian baru (Req 5.3–5.6).
///
/// Field wajib: nama kebun, provinsi, kota/kabupaten, kecamatan, desa, alamat.
/// Field opsional: latitude, longitude.
///
/// Alur submit (Req 5.4, 5.5):
/// 1. Validasi via [FarmerValidator.validateCreateFarm].
/// 2. Bila gagal → tampilkan [TopNotification] error berbahasa Indonesia.
/// 3. Bila valid → panggil [FarmerRepository.addFarm], tampilkan banner sukses,
///    lalu pop. Kebun baru langsung tersedia di dropdown Tambah Batch (Req 5.6)
///    karena repo memanggil [notifyListeners].
class CreateFarmScreen extends StatefulWidget {
  const CreateFarmScreen({super.key});

  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final _repo = FarmerRepository.instance;
  final _notification = TopNotification();
  final _regionService = CahyadsnRegionService.instance;

  final _nameCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingRegions = true;
  bool _isLocatingAddress = false;
  String? _regionLoadError;
  String? _addressLocationError;
  String? _provinceCode;
  String? _cityCode;
  String? _districtCode;
  String? _villageCode;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      await _regionService.load();
      if (!mounted) return;
      setState(() {
        _isLoadingRegions = false;
        _regionLoadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRegions = false;
        _regionLoadError =
            'Data wilayah tidak dapat dimuat. Kamu tetap bisa mengetik manual.';
      });
    }
  }

  List<CahyadsnRegion> get _provinceOptions =>
      _isLoadingRegions ? const [] : _regionService.provinces;

  List<CahyadsnRegion> get _cityOptions =>
      _isLoadingRegions ? const [] : _regionService.childrenOf(_provinceCode);

  List<CahyadsnRegion> get _districtOptions =>
      _isLoadingRegions ? const [] : _regionService.childrenOf(_cityCode);

  List<CahyadsnRegion> get _villageOptions =>
      _isLoadingRegions ? const [] : _regionService.childrenOf(_districtCode);

  /// The deepest selected region code (village > district > city > province).
  String? get _deepestCode =>
      _villageCode ?? _districtCode ?? _cityCode ?? _provinceCode;

  /// Returns the administrative level of the deepest selection (1–4).
  int get _regionLevel {
    final code = _deepestCode;
    if (code == null) return 0;
    return CahyadsnRegionService.levelOf(code);
  }

  /// Walks up the hierarchy to find the nearest coordinate for the deepest
  /// selected region. E.g. if a village is selected but only city-level
  /// coordinates exist, use the city coordinate.
  CahyadsnRegionMap? get _selectedRegionMap =>
      _regionService.mapForClosest(_deepestCode);

  _GeoPoint? get _farmPoint {
    final latitude = double.tryParse(_latCtrl.text.trim());
    final longitude = double.tryParse(_lngCtrl.text.trim());
    if (latitude == null || longitude == null) return null;
    return _GeoPoint(latitude, longitude);
  }

  void _setFarmPoint(_GeoPoint point) {
    setState(() {
      _latCtrl.text = point.latitude.toStringAsFixed(6);
      _lngCtrl.text = point.longitude.toStringAsFixed(6);
      _addressLocationError = null;
    });
  }

  void _clearFarmPoint() {
    _latCtrl.clear();
    _lngCtrl.clear();
    _addressLocationError = null;
  }

  Future<void> _locateAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      setState(() {
        _addressLocationError = 'Masukkan alamat kebun terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isLocatingAddress = true;
      _addressLocationError = null;
    });
    final query = [
      address,
      _villageCtrl.text.trim(),
      _districtCtrl.text.trim(),
      _cityCtrl.text.trim(),
      _provinceCtrl.text.trim(),
      'Indonesia',
    ].where((part) => part.isNotEmpty).join(', ');
    final location = await _regionService.findAddress(query);
    if (!mounted) return;

    setState(() {
      _isLocatingAddress = false;
      if (location == null) {
        _addressLocationError =
            'Alamat belum ditemukan. Lengkapi alamat atau pilih titik pada peta.';
      } else {
        _latCtrl.text = location.latitude.toStringAsFixed(6);
        _lngCtrl.text = location.longitude.toStringAsFixed(6);
      }
    });
  }

  CahyadsnRegionBoundary? _currentBoundary;
  bool _isLoadingBoundary = false;

  Future<void> _updateBoundary() async {
    final code = _deepestCode;
    if (code == null) {
      setState(() {
        _currentBoundary = null;
        _isLoadingBoundary = false;
      });
      return;
    }
    setState(() {
      _currentBoundary = null;
      _isLoadingBoundary = true;
    });
    final boundary = await _regionService.loadBoundaryFor(code);
    if (!mounted) return;
    if (_deepestCode == code) {
      setState(() {
        _currentBoundary = boundary;
        _isLoadingBoundary = false;
      });
    }
  }

  void _onProvinceChanged(String value) {
    final match = _regionService.findExact(_provinceOptions, value);
    if (match?.code == _provinceCode) return;
    setState(() {
      _clearFarmPoint();
      _provinceCode = match?.code;
      _cityCode = null;
      _districtCode = null;
      _villageCode = null;
      _cityCtrl.clear();
      _districtCtrl.clear();
      _villageCtrl.clear();
    });
    _updateBoundary();
  }

  void _onCityChanged(String value) {
    final match = _regionService.findExact(_cityOptions, value);
    if (match?.code == _cityCode) return;
    setState(() {
      _clearFarmPoint();
      _cityCode = match?.code;
      _districtCode = null;
      _villageCode = null;
      _districtCtrl.clear();
      _villageCtrl.clear();
    });
    _updateBoundary();
  }

  void _onDistrictChanged(String value) {
    final match = _regionService.findExact(_districtOptions, value);
    if (match?.code == _districtCode) return;
    setState(() {
      _clearFarmPoint();
      _districtCode = match?.code;
      _villageCode = null;
      _villageCtrl.clear();
    });
    _updateBoundary();
  }

  void _onVillageChanged(String value) {
    final match = _regionService.findExact(_villageOptions, value);
    if (match?.code == _villageCode) return;
    setState(() {
      _clearFarmPoint();
      _villageCode = match?.code;
    });
    _updateBoundary();
  }

  @override
  void dispose() {
    _notification.dispose();
    _nameCtrl.dispose();
    _provinceCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _villageCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  // [FE - Event Handler] _submit menangani aksi simpan kebun: validasi →
  // error banner atau addFarm + sukses banner + pop kembali ke pemanggil.
  Future<void> _submit() async {
    // Validasi semua field
    final error = FarmerValidator.validateCreateFarm(
      name: _nameCtrl.text,
      province: _provinceCtrl.text,
      city: _cityCtrl.text,
      district: _districtCtrl.text,
      village: _villageCtrl.text,
      address: _addressCtrl.text,
      latitudeText: _latCtrl.text.isEmpty ? null : _latCtrl.text,
      longitudeText: _lngCtrl.text.isEmpty ? null : _lngCtrl.text,
    );

    if (error != null) {
      _notification.show(context, error, isError: true);
      return;
    }

    // Semua valid — mulai proses simpan
    setState(() => _isSubmitting = true);

    // Simulasi async singkat agar indikator loading terlihat
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Parse koordinat opsional
    final lat = _latCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_latCtrl.text.trim());
    final lng = _lngCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_lngCtrl.text.trim());

    _repo.addFarm(
      name: _nameCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: lat,
      longitude: lng,
    );

    setState(() => _isSubmitting = false);

    // Banner sukses (Req 5.5)
    _notification.show(
      context,
      'Kebun "${_nameCtrl.text.trim()}" berhasil ditambahkan.',
      isError: false,
    );

    // Tunggu banner auto-dismiss (3 detik) sebelum pop agar tidak terpotong.
    await Future.delayed(const Duration(milliseconds: 3200));

    if (mounted) Navigator.maybePop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar dengan tombol back (Req 8.2)
            const AppTopBar(title: 'Buat Kebun'),

            // Form scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nama Kebun (wajib) ─────────────────────────────────
                    _FormField(
                      label: 'Nama Kebun',
                      hint: 'Contoh: Kebun Pak Risqi',
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // ── Provinsi (wajib) ───────────────────────────────────
                    _SearchableRegionField(
                      label: 'Provinsi',
                      hint: 'Ketik atau pilih provinsi',
                      controller: _provinceCtrl,
                      options: _provinceOptions,
                      isLoading: _isLoadingRegions,
                      onChanged: _onProvinceChanged,
                      onSelected: (region) => _onProvinceChanged(region.name),
                    ),
                    if (_regionLoadError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _regionLoadError!,
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // ── Kota/Kabupaten (wajib) ─────────────────────────────
                    _SearchableRegionField(
                      label: 'Kota/Kabupaten',
                      hint: _provinceCode == null
                          ? 'Pilih provinsi atau ketik manual'
                          : 'Ketik atau pilih kota/kabupaten',
                      controller: _cityCtrl,
                      options: _cityOptions,
                      isLoading: _isLoadingRegions,
                      requiresParent: true,
                      onChanged: _onCityChanged,
                      onSelected: (region) => _onCityChanged(region.name),
                    ),
                    const SizedBox(height: 16),

                    // ── Kecamatan (wajib) ──────────────────────────────────
                    _SearchableRegionField(
                      label: 'Kecamatan',
                      hint: _cityCode == null
                          ? 'Pilih kota/kabupaten atau ketik manual'
                          : 'Ketik atau pilih kecamatan',
                      controller: _districtCtrl,
                      options: _districtOptions,
                      isLoading: _isLoadingRegions,
                      requiresParent: true,
                      onChanged: _onDistrictChanged,
                      onSelected: (region) => _onDistrictChanged(region.name),
                    ),
                    const SizedBox(height: 16),

                    // ── Desa (wajib) ───────────────────────────────────────
                    _SearchableRegionField(
                      label: 'Desa/Kelurahan',
                      hint: _districtCode == null
                          ? 'Pilih kecamatan atau ketik manual'
                          : 'Ketik atau pilih desa/kelurahan',
                      controller: _villageCtrl,
                      options: _villageOptions,
                      isLoading: _isLoadingRegions,
                      requiresParent: true,
                      onChanged: _onVillageChanged,
                      onSelected: (region) => _onVillageChanged(region.name),
                    ),
                    const SizedBox(height: 16),

                    // ── Alamat (wajib) ─────────────────────────────────────
                    _FormField(
                      label: 'Alamat',
                      hint: 'Contoh: Jl. Raya Pakis No. 1',
                      controller: _addressCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) {
                        if (_farmPoint != null) {
                          setState(_clearFarmPoint);
                        } else if (_addressLocationError != null) {
                          setState(() => _addressLocationError = null);
                        }
                      },
                      onSubmitted: (_) => _locateAddress(),
                      suffixIcon: _isLocatingAddress
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Cari lokasi alamat',
                              onPressed: _locateAddress,
                              icon: const Icon(
                                Icons.travel_explore_rounded,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                    ),
                    if (_addressLocationError != null) ...[
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _addressLocationError!,
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    _RegionMapPreview(
                      region: _selectedRegionMap,
                      regionLevel: _regionLevel,
                      boundary: _currentBoundary,
                      isLoadingBoundary: _isLoadingBoundary,
                      farmPoint: _farmPoint,
                      onTap: _setFarmPoint,
                    ),
                    const SizedBox(height: 20),

                    // ── Divider opsional ───────────────────────────────────
                    const _SectionDivider(label: 'Titik Kebun (Opsional)'),
                    const SizedBox(height: 16),

                    // ── Latitude (opsional) ────────────────────────────────
                    _FormField(
                      label: 'Latitude',
                      hint: 'Contoh: -8.1234',
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // ── Longitude (opsional) ───────────────────────────────
                    _FormField(
                      label: 'Longitude',
                      hint: 'Contoh: 113.7234',
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 32),

                    // ── Tombol Simpan ──────────────────────────────────────
                    PrimaryPillButton(
                      label: 'SIMPAN KEBUN',
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable form field
// ─────────────────────────────────────────────────────────────────────────────

/// Field teks bergaya konsisten dengan layar lain (border tipis, label atas).
class _SearchableRegionField extends StatefulWidget {
  const _SearchableRegionField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.options,
    required this.isLoading,
    this.requiresParent = false,
    this.onChanged,
    this.onSelected,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final List<CahyadsnRegion> options;
  final bool isLoading;
  final bool requiresParent;
  final ValueChanged<String>? onChanged;
  final ValueChanged<CahyadsnRegion>? onSelected;

  @override
  State<_SearchableRegionField> createState() => _SearchableRegionFieldState();
}

class _SearchableRegionFieldState extends State<_SearchableRegionField> {
  final FocusNode _focusNode = FocusNode();
  final MenuController _menuController = MenuController();
  String _query = '';
  bool _isOpeningMenu = false;

  @override
  void initState() {
    super.initState();
    _query = widget.controller.text;
  }

  @override
  void didUpdateWidget(covariant _SearchableRegionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_query != widget.controller.text) {
      _query = widget.controller.text;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasExactMatch {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return widget.options.any((option) => option.name.toLowerCase() == query);
  }

  Iterable<CahyadsnRegion> _filterOptions(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return widget.options.take(40);

    final startsWith = <CahyadsnRegion>[];
    final contains = <CahyadsnRegion>[];
    for (final option in widget.options) {
      final name = option.name.toLowerCase();
      if (name.startsWith(normalized)) {
        startsWith.add(option);
      } else if (name.contains(normalized)) {
        contains.add(option);
      }
      if (startsWith.length + contains.length >= 60) break;
    }
    return [...startsWith, ...contains].take(60);
  }

  void _selectOption(CahyadsnRegion option) {
    widget.controller.value = TextEditingValue(
      text: option.name,
      selection: TextSelection.collapsed(offset: option.name.length),
    );
    setState(() => _query = option.name);
    widget.onSelected?.call(option);
    _menuController.close();
  }

  Future<void> _openMenu() async {
    if (widget.isLoading || _menuController.isOpen || _isOpeningMenu) return;

    _isOpeningMenu = true;
    _focusNode.requestFocus();

    // Sisakan ruang di bawah field agar Material tidak membalik menu ke atas.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.16,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );

    if (mounted && !_menuController.isOpen) {
      _menuController.open();
    }
    _isOpeningMenu = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final options = _filterOptions(_query).take(60).toList();
            final menuChildren = <Widget>[
              if (widget.isLoading)
                _regionMenuMessage(
                  const CircularProgressIndicator(strokeWidth: 2),
                )
              else if (options.isEmpty)
                _regionMenuMessage(
                  Text(
                    widget.options.isEmpty
                        ? widget.requiresParent
                              ? 'Pilih wilayah sebelumnya atau ketik manual.'
                              : 'Data wilayah belum tersedia. Coba buka kembali.'
                        : 'Wilayah tidak ditemukan. Teks manual tetap disimpan.',
                    style: const TextStyle(
                      color: AppColors.placeholder,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                for (final option in options)
                  MenuItemButton(
                    onPressed: () => _selectOption(option),
                    style: ButtonStyle(
                      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(50),
                      ),
                      maximumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(50),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        final isSelected =
                            option.name.toLowerCase() ==
                            widget.controller.text.trim().toLowerCase();
                        if (isSelected) return const Color(0xFFEDF7E9);
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.focused)) {
                          return const Color(0xFFF5F9F3);
                        }
                        return Colors.transparent;
                      }),
                      overlayColor: const WidgetStatePropertyAll(
                        Color(0x1458A835),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    child: _RegionMenuItem(
                      option: option,
                      width: constraints.maxWidth - 20,
                      isSelected:
                          option.name.toLowerCase() ==
                          widget.controller.text.trim().toLowerCase(),
                    ),
                  ),
            ];

            return MenuAnchor(
              controller: _menuController,
              alignmentOffset: const Offset(0, 4),
              style: MenuStyle(
                backgroundColor: const WidgetStatePropertyAll(AppColors.white),
                surfaceTintColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                shadowColor: const WidgetStatePropertyAll(Color(0x52000000)),
                elevation: const WidgetStatePropertyAll(14),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                ),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: Color(0xFFDCE5D8)),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maximumSize: WidgetStatePropertyAll(
                  Size(constraints.maxWidth, 300),
                ),
                minimumSize: WidgetStatePropertyAll(
                  Size(constraints.maxWidth, 0),
                ),
              ),
              menuChildren: menuChildren,
              builder: (context, controller, child) {
                return TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  scrollPadding: const EdgeInsets.only(bottom: 340),
                  textCapitalization: TextCapitalization.words,
                  onTap: _openMenu,
                  onChanged: (value) {
                    setState(() => _query = value);
                    widget.onChanged?.call(value);
                    if (!widget.isLoading && !controller.isOpen) {
                      _openMenu();
                    }
                  },
                  style: const TextStyle(fontSize: 14, color: AppColors.black),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.placeholder,
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: Color(0xFF82A476),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    suffixIcon: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Buka pilihan ${widget.label}',
                            onPressed: () {
                              controller.isOpen
                                  ? controller.close()
                                  : _openMenu();
                            },
                            icon: Icon(
                              controller.isOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.placeholder,
                            ),
                          ),
                    border: _regionBorder(),
                    enabledBorder: _regionBorder(),
                    focusedBorder: _regionBorder(focused: true),
                  ),
                );
              },
            );
          },
        ),
        if (_query.trim().isNotEmpty && !_hasExactMatch)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  Icons.edit_location_alt_outlined,
                  size: 14,
                  color: AppColors.placeholder,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tidak ditemukan? Teks ini tetap akan disimpan.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _regionBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: focused ? AppColors.primaryContainer : const Color(0xFFE5E7EB),
        width: focused ? 2 : 1,
      ),
    );
  }

  Widget _regionMenuMessage(Widget child) {
    return MenuItemButton(
      onPressed: null,
      child: SizedBox(width: 260, height: 44, child: Center(child: child)),
    );
  }
}

class _RegionMenuItem extends StatelessWidget {
  const _RegionMenuItem({
    required this.option,
    required this.width,
    required this.isSelected,
  });

  final CahyadsnRegion option;
  final double width;
  final bool isSelected;

  String get _levelLabel {
    final depth = '.'.allMatches(option.code).length;
    return switch (depth) {
      0 => 'Provinsi',
      1 => 'Kabupaten / Kota',
      2 => 'Kecamatan',
      _ => 'Desa / Kelurahan',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFDCEFD4)
                    : const Color(0xFFF0F4EE),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.location_on_outlined,
                size: 18,
                color: isSelected
                    ? AppColors.primaryContainer
                    : const Color(0xFF66815D),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.subtitle,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _levelLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.placeholder,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeoPoint {
  const _GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

// ─── Polygon boundary painter ────────────────────────────────────────────────

class _BoundaryPainter extends CustomPainter {
  _BoundaryPainter({
    required this.rings,
    required this.viewportOrigin,
    required this.zoom,
  });

  final List<List<CahyadsnBoundaryPoint>> rings;
  final Offset viewportOrigin;
  final int zoom;

  static const _tileSize = 256.0;

  Offset _toScreen(double lat, double lng) {
    final scale = math.pow(2, zoom).toDouble() * _tileSize;
    final cLat = lat.clamp(-85.05112878, 85.05112878);
    final radians = cLat * math.pi / 180;
    final x = (lng + 180) / 360 * scale;
    final y =
        (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) /
        2 *
        scale;
    return Offset(x - viewportOrigin.dx, y - viewportOrigin.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    final fillPaint = Paint()
      ..color = const Color(0x3658A835)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;

    final boundaryPath = Path()..fillType = PathFillType.evenOdd;
    for (final ring in rings) {
      if (ring.length < 3) continue;
      final first = _toScreen(ring[0].latitude, ring[0].longitude);
      boundaryPath.moveTo(first.dx, first.dy);
      for (var i = 1; i < ring.length; i++) {
        final pt = _toScreen(ring[i].latitude, ring[i].longitude);
        boundaryPath.lineTo(pt.dx, pt.dy);
      }
      boundaryPath.close();
    }
    canvas.drawPath(boundaryPath, fillPaint);
    canvas.drawPath(boundaryPath, strokePaint);
  }

  @override
  bool shouldRepaint(_BoundaryPainter old) =>
      old.zoom != zoom ||
      old.viewportOrigin != viewportOrigin ||
      old.rings != rings;
}

// ─── OSM tile map widget ─────────────────────────────────────────────────────

class _OsmTiles extends StatefulWidget {
  const _OsmTiles({
    super.key,
    required this.center,
    required this.initialZoom,
    required this.markerPoint,
    required this.onTap,
    this.boundary,
  });

  final _GeoPoint center;
  final int initialZoom;
  final _GeoPoint? markerPoint;
  final ValueChanged<_GeoPoint> onTap;
  final List<List<CahyadsnBoundaryPoint>>? boundary;

  @override
  State<_OsmTiles> createState() => _OsmTilesState();
}

class _OsmTilesState extends State<_OsmTiles> {
  static const _tileSize = 256.0;
  late int _zoom;
  late _GeoPoint _center;
  int _gestureStartZoom = 0;
  Offset? _gestureAnchorWorld;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom.clamp(3, 17);
    _center = widget.center;
  }

  @override
  void didUpdateWidget(covariant _OsmTiles old) {
    super.didUpdateWidget(old);
    if (old.initialZoom != widget.initialZoom ||
        old.center.latitude != widget.center.latitude ||
        old.center.longitude != widget.center.longitude) {
      _zoom = widget.initialZoom.clamp(3, 17);
      _center = widget.center;
    }
  }

  void _zoomBy(int delta, Size viewportSize) {
    final nextZoom = (_zoom + delta).clamp(3, 17);
    if (nextZoom == _zoom) return;

    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final anchor = widget.markerPoint ?? _center;
    final anchorScreen =
        _worldPointAt(anchor, _zoom) -
        _worldPointAt(_center, _zoom) +
        viewportCenter;
    final nextCenterWorld =
        _worldPointAt(anchor, nextZoom) - (anchorScreen - viewportCenter);

    setState(() {
      _zoom = nextZoom;
      _center = _geoPointAt(nextCenterWorld, nextZoom);
    });
  }

  void _resetView() {
    setState(() {
      _center = widget.center;
      _zoom = widget.initialZoom.clamp(3, 17);
    });
  }

  void _startGesture(ScaleStartDetails details, Size viewportSize) {
    _gestureStartZoom = _zoom;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    _gestureAnchorWorld =
        _worldPointAt(_center, _zoom) +
        (details.localFocalPoint - viewportCenter);
  }

  void _updateGesture(ScaleUpdateDetails details, Size viewportSize) {
    final anchor = _gestureAnchorWorld;
    if (anchor == null) return;

    final zoomDelta = math.log(details.scale) / math.ln2;
    final nextZoom = (_gestureStartZoom + zoomDelta).round().clamp(3, 17);
    final scaleFactor = math.pow(2, nextZoom - _gestureStartZoom).toDouble();
    final anchorAtZoom = anchor * scaleFactor;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final nextCenterWorld =
        anchorAtZoom - (details.localFocalPoint - viewportCenter);

    setState(() {
      _zoom = nextZoom;
      _center = _geoPointAt(nextCenterWorld, nextZoom);
    });
  }

  Offset _worldPointAt(_GeoPoint point, int zoom) {
    final scale = math.pow(2, zoom).toDouble() * _tileSize;
    final latitude = point.latitude.clamp(-85.05112878, 85.05112878);
    final radians = latitude * math.pi / 180;
    final x = (point.longitude + 180) / 360 * scale;
    final y =
        (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) /
        2 *
        scale;
    return Offset(x, y);
  }

  Offset _worldPoint(_GeoPoint point) => _worldPointAt(point, _zoom);

  _GeoPoint _geoPointAt(Offset world, int zoom) {
    final tiles = math.pow(2, zoom).toDouble();
    final worldSize = _tileSize * tiles;
    final wrappedX = ((world.dx % worldSize) + worldSize) % worldSize;
    final clampedY = world.dy.clamp(0.0, worldSize);
    final longitude = wrappedX / worldSize * 360 - 180;
    final normalizedY = clampedY / worldSize;
    final mercator = math.pi * (1 - 2 * normalizedY);
    final latitude =
        math.atan((math.exp(mercator) - math.exp(-mercator)) / 2) *
        180 /
        math.pi;
    return _GeoPoint(latitude, longitude);
  }

  _GeoPoint _geoPoint(Offset world) => _geoPointAt(world, _zoom);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = _worldPoint(_center);
        final viewportOrigin = Offset(
          center.dx - size.width / 2,
          center.dy - size.height / 2,
        );
        final firstX = (viewportOrigin.dx / _tileSize).floor();
        final lastX = ((viewportOrigin.dx + size.width) / _tileSize).floor();
        final firstY = (viewportOrigin.dy / _tileSize).floor();
        final lastY = ((viewportOrigin.dy + size.height) / _tileSize).floor();
        final tileCount = math.pow(2, _zoom).toInt();

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _zoomBy(event.scrollDelta.dy > 0 ? -1 : 1, size);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) => _startGesture(details, size),
            onScaleUpdate: (details) => _updateGesture(details, size),
            onScaleEnd: (_) => _gestureAnchorWorld = null,
            onTapUp: (details) {
              final world = viewportOrigin + details.localPosition;
              widget.onTap(_geoPoint(world));
            },
            child: ColoredBox(
              color: const Color(0xFFE8ECEF),
              child: Stack(
                children: [
                  for (var x = firstX; x <= lastX; x++)
                    for (var y = firstY; y <= lastY; y++)
                      if (y >= 0 && y < tileCount)
                        Positioned(
                          left: x * _tileSize - viewportOrigin.dx,
                          top: y * _tileSize - viewportOrigin.dy,
                          width: _tileSize,
                          height: _tileSize,
                          child: Image.network(
                            'https://tile.openstreetmap.org/$_zoom/${((x % tileCount) + tileCount) % tileCount}/$y.png',
                            key: ValueKey(
                              'tile_${_zoom}_${((x % tileCount) + tileCount) % tileCount}_$y',
                            ),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) =>
                                const ColoredBox(color: Color(0xFFE8ECEF)),
                          ),
                        ),
                  // ── Boundary polygon overlay ─────────────────────────────
                  if (widget.boundary != null && widget.boundary!.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BoundaryPainter(
                          rings: widget.boundary!,
                          viewportOrigin: viewportOrigin,
                          zoom: _zoom,
                        ),
                      ),
                    ),
                  // ── Location marker ──────────────────────────────────────
                  if (widget.markerPoint != null)
                    Positioned(
                      left:
                          _worldPoint(widget.markerPoint!).dx -
                          viewportOrigin.dx -
                          21,
                      top:
                          _worldPoint(widget.markerPoint!).dy -
                          viewportOrigin.dy -
                          42,
                      child: const IgnorePointer(
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 42,
                          color: AppColors.primaryContainer,
                          shadows: [
                            Shadow(
                              color: Color(0x55000000),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // ── Zoom controls ────────────────────────────────────────
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      children: [
                        _MapIconButton(
                          icon: Icons.add,
                          tooltip: 'Perbesar peta',
                          onPressed: _zoom >= 17
                              ? null
                              : () => _zoomBy(1, size),
                        ),
                        const SizedBox(height: 4),
                        _MapIconButton(
                          icon: Icons.remove,
                          tooltip: 'Perkecil peta',
                          onPressed: _zoom <= 3
                              ? null
                              : () => _zoomBy(-1, size),
                        ),
                        const SizedBox(height: 4),
                        _MapIconButton(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Kembali ke wilayah terpilih',
                          onPressed: _resetView,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(6),
        elevation: 2,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 19,
              color: onPressed == null
                  ? AppColors.placeholder
                  : AppColors.subtitle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Region map preview (with boundary) ──────────────────────────────────────

// Kept temporarily as a fallback reference while the Google Maps renderer is
// used by the form.
// ignore: unused_element
class _LegacyRegionMapPreview extends StatelessWidget {
  const _LegacyRegionMapPreview({
    required this.region,
    required this.regionLevel,
    required this.boundary,
    required this.isLoadingBoundary,
    required this.farmPoint,
    required this.onTap,
  });

  final CahyadsnRegionMap? region;

  /// 0 = none, 1 = province, 2 = city, 3 = district, 4 = village.
  final int regionLevel;
  final CahyadsnRegionBoundary? boundary;
  final bool isLoadingBoundary;
  final _GeoPoint? farmPoint;
  final ValueChanged<_GeoPoint> onTap;

  /// Computes the center and zoom that fits the boundary polygon.
  ({_GeoPoint center, int zoom}) _fitBounds(Size viewportSize) {
    if (boundary == null || boundary!.rings.isEmpty) {
      return (
        center: region == null
            ? const _GeoPoint(-2.5, 118)
            : _GeoPoint(region!.latitude, region!.longitude),
        zoom: region == null ? 5 : _fallbackZoom(),
      );
    }

    // Compute bounding box of all polygon rings.
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final ring in boundary!.rings) {
      for (final pt in ring) {
        if (pt.latitude < minLat) minLat = pt.latitude;
        if (pt.latitude > maxLat) maxLat = pt.latitude;
        if (pt.longitude < minLng) minLng = pt.longitude;
        if (pt.longitude > maxLng) maxLng = pt.longitude;
      }
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Calculate the zoom level that fits the bounding box into the viewport.
    // Mercator projection: x = (lng + 180) / 360 * 2^zoom * 256
    const tileSize = 256.0;
    const padding = 24.0; // px padding on each side
    final effWidth = (viewportSize.width - padding * 2).clamp(1.0, 4096.0);
    final effHeight = (viewportSize.height - padding * 2).clamp(1.0, 4096.0);

    // Longitude span → zoom
    final lngSpan = (maxLng - minLng).abs();
    final zoomLng = lngSpan > 0
        ? (math.log(effWidth / tileSize * 360 / lngSpan) / math.ln2)
        : 17.0;

    // Latitude span → zoom (need Mercator conversion)
    double latToY(double lat) {
      final r = lat.clamp(-85.05112878, 85.05112878) * math.pi / 180;
      return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2;
    }

    final ySpan = (latToY(minLat) - latToY(maxLat)).abs();
    final zoomLat = ySpan > 0
        ? (math.log(effHeight / tileSize / ySpan) / math.ln2)
        : 17.0;

    final zoom = math.min(zoomLng, zoomLat).floor().clamp(3, 17);

    return (center: _GeoPoint(centerLat, centerLng), zoom: zoom);
  }

  int _fallbackZoom() {
    return switch (regionLevel) {
      1 => 7,
      2 => 10,
      3 => 12,
      _ => 14,
    };
  }

  @override
  Widget build(BuildContext context) {
    // If the user has placed a farm point, always show that at high zoom.
    if (farmPoint != null) {
      return _buildMap(center: farmPoint!, zoom: 14, markerPoint: farmPoint);
    }

    // Auto-fit boundary.
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth,
          220, // height of the map container
        );
        final fit = _fitBounds(viewportSize);
        return _buildMap(center: fit.center, zoom: fit.zoom);
      },
    );
  }

  Widget _buildMap({
    required _GeoPoint center,
    required int zoom,
    _GeoPoint? markerPoint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Kebun',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                _OsmTiles(
                  key: ValueKey(
                    '${boundary?.code ?? region?.code}-'
                    '${farmPoint?.latitude}-${farmPoint?.longitude}',
                  ),
                  center: center,
                  initialZoom: zoom,
                  markerPoint: markerPoint,
                  boundary: boundary?.rings,
                  onTap: onTap,
                ),
                if (isLoadingBoundary)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66FFFFFF),
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'Memuat batas wilayah...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 6,
                  bottom: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      child: Text(
                        '(c) OpenStreetMap contributors',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.touch_app_outlined,
              size: 15,
              color: AppColors.placeholder,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                region == null
                    ? 'Pilih provinsi untuk menampilkan wilayah pada peta.'
                    : farmPoint == null
                    ? boundary == null
                          ? 'Peta menampilkan pusat ${region!.name}. Ketuk peta untuk memasang penanda.'
                          : 'Zona ${boundary!.name} ditampilkan sesuai batas wilayah. Ketuk peta untuk memasang penanda.'
                    : 'Penanda kebun sudah dipilih. Ketuk lokasi lain untuk memindahkannya.',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.placeholder,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RegionMapPreview extends StatefulWidget {
  const _RegionMapPreview({
    required this.region,
    required this.regionLevel,
    required this.boundary,
    required this.isLoadingBoundary,
    required this.farmPoint,
    required this.onTap,
  });

  final CahyadsnRegionMap? region;
  final int regionLevel;
  final CahyadsnRegionBoundary? boundary;
  final bool isLoadingBoundary;
  final _GeoPoint? farmPoint;
  final ValueChanged<_GeoPoint> onTap;

  @override
  State<_RegionMapPreview> createState() => _RegionMapPreviewState();
}

class _RegionMapPreviewState extends State<_RegionMapPreview> {
  GoogleMapController? _controller;
  MapType _mapType = MapType.normal;

  LatLng get _initialCenter {
    final point = widget.farmPoint;
    if (point != null) return LatLng(point.latitude, point.longitude);
    final region = widget.region;
    if (region != null) return LatLng(region.latitude, region.longitude);
    return const LatLng(-2.5, 118);
  }

  double get _fallbackZoom => switch (widget.regionLevel) {
    0 => 5,
    1 => 7,
    2 => 10,
    3 => 12,
    _ => 14,
  };

  LatLngBounds? get _boundaryBounds {
    final boundary = widget.boundary;
    if (boundary == null || boundary.rings.isEmpty) return null;

    var minLat = 90.0;
    var maxLat = -90.0;
    var minLng = 180.0;
    var maxLng = -180.0;
    for (final ring in boundary.rings) {
      for (final point in ring) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    if (minLat > maxLat || minLng > maxLng) return null;
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Set<Polygon> get _polygons {
    final boundary = widget.boundary;
    if (boundary == null) return const {};

    return {
      for (var index = 0; index < boundary.rings.length; index++)
        if (boundary.rings[index].length >= 3)
          Polygon(
            polygonId: PolygonId('${boundary.code}-$index'),
            points: boundary.rings[index]
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(growable: false),
            fillColor: const Color(0x3858A835),
            strokeColor: AppColors.primary,
            strokeWidth: 3,
          ),
    };
  }

  Set<Marker> get _markers {
    final point = widget.farmPoint;
    if (point == null) return const {};

    return {
      Marker(
        markerId: const MarkerId('farm-location'),
        position: LatLng(point.latitude, point.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Lokasi kebun'),
      ),
    };
  }

  Future<void> _focusSelection({bool animate = true}) async {
    final controller = _controller;
    if (controller == null) return;

    final bounds = _boundaryBounds;
    final update = bounds == null
        ? CameraUpdate.newLatLngZoom(_initialCenter, _fallbackZoom)
        : CameraUpdate.newLatLngBounds(bounds, 28);

    try {
      if (animate) {
        await controller.animateCamera(update);
      } else {
        await controller.moveCamera(update);
      }
    } on PlatformException {
      await controller.moveCamera(
        CameraUpdate.newLatLngZoom(_initialCenter, _fallbackZoom),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _RegionMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final regionChanged =
        oldWidget.region?.code != widget.region?.code ||
        oldWidget.boundary?.code != widget.boundary?.code;
    final markerChanged =
        oldWidget.farmPoint?.latitude != widget.farmPoint?.latitude ||
        oldWidget.farmPoint?.longitude != widget.farmPoint?.longitude;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _controller == null) return;
      if (regionChanged) {
        await _focusSelection();
      } else if (markerChanged && widget.farmPoint != null) {
        final point = widget.farmPoint!;
        await _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(point.latitude, point.longitude),
            16,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = widget.region;
    final boundary = widget.boundary;
    final farmPoint = widget.farmPoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Kebun',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 240,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialCenter,
                    zoom: farmPoint == null ? _fallbackZoom : 16,
                  ),
                  mapType: _mapType,
                  polygons: _polygons,
                  markers: _markers,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  onMapCreated: (controller) {
                    _controller = controller;
                    Future<void>.delayed(const Duration(milliseconds: 180), () {
                      if (mounted) _focusSelection(animate: false);
                    });
                  },
                  onTap: (point) =>
                      widget.onTap(_GeoPoint(point.latitude, point.longitude)),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: _MapTypeControl(
                    mapType: _mapType,
                    onChanged: (value) => setState(() => _mapType = value),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: _MapFocusButton(onPressed: _focusSelection),
                ),
                if (widget.isLoadingBoundary)
                  const Positioned.fill(child: _MapBoundaryLoader()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.touch_app_outlined,
              size: 15,
              color: AppColors.placeholder,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                region == null
                    ? 'Pilih provinsi untuk menampilkan wilayah pada peta.'
                    : farmPoint == null
                    ? boundary == null
                          ? 'Peta menampilkan pusat ${region.name}. Ketuk peta untuk memasang penanda.'
                          : 'Zona ${boundary.name} ditampilkan sesuai batas wilayah. Geser atau cubit peta, lalu ketuk untuk memasang penanda.'
                    : 'Penanda kebun sudah dipilih. Geser dan cubit peta tanpa mengubah titik, atau ketuk lokasi lain untuk memindahkannya.',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.placeholder,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapTypeControl extends StatelessWidget {
  const _MapTypeControl({required this.mapType, required this.onChanged});

  final MapType mapType;
  final ValueChanged<MapType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 3,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapTypeOption(
            label: 'Peta',
            selected: mapType == MapType.normal,
            onTap: () => onChanged(MapType.normal),
          ),
          _MapTypeOption(
            label: 'Satelit',
            selected: mapType == MapType.hybrid,
            onTap: () => onChanged(MapType.hybrid),
          ),
        ],
      ),
    );
  }
}

class _MapTypeOption extends StatelessWidget {
  const _MapTypeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        color: selected ? AppColors.primary : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.subtitle,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MapFocusButton extends StatelessWidget {
  const _MapFocusButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Fokus ke wilayah terpilih',
      child: Material(
        color: Colors.white.withValues(alpha: 0.96),
        elevation: 3,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              Icons.center_focus_strong_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapBoundaryLoader extends StatelessWidget {
  const _MapBoundaryLoader();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x66FFFFFF),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryContainer,
                  ),
                ),
                SizedBox(width: 9),
                Text(
                  'Memuat batas wilayah...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 14, color: AppColors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.placeholder,
            ),
            filled: true,
            fillColor: AppColors.white,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryContainer,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section divider
// ─────────────────────────────────────────────────────────────────────────────

/// Pemisah visual dengan label untuk memisahkan bagian wajib dan opsional.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.placeholder,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }
}
