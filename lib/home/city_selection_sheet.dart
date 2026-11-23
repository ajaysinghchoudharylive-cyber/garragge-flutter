import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Select your city" sheet, a port of the Android CitySelectionBottomSheet
/// (bottom_sheet_city_selection.xml + CitySelectionViewModel). Data: GET cars/cities ->
/// {popular: [{name, image, state}], other: [name], states: {city: state}}.
class CitySelectionSheet extends StatefulWidget {
  const CitySelectionSheet({super.key});

  /// Opens the sheet; resolves to true when the user picked or detected a city.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const FractionallySizedBox(heightFactor: 1, child: CitySelectionSheet()),
    );
  }

  @override
  State<CitySelectionSheet> createState() => _CitySelectionSheetState();
}

class _PopularCity {
  final String name;
  final String image;
  final String state;
  _PopularCity(this.name, this.image, this.state);
}

class _CitySelectionSheetState extends State<CitySelectionSheet> {
  static const _purple = Color(0xFF5832E0);
  static const _otherCollapsedLimit = 6;

  List<_PopularCity> _popular = [];
  List<String> _other = [];
  Map<String, String> _states = {};
  String _query = '';
  String _selected = '';
  bool _loading = true;
  bool _detecting = false;
  bool _otherExpanded = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _selected = prefs.getString('city') ?? '';
    try {
      final res = await ApiClient.dio.get<dynamic>('cars/cities');
      final data = res.data;
      if (data is Map) {
        final pop = data['popular'];
        final oth = data['other'];
        final st = data['states'];
        _popular = pop is List
            ? pop
                .whereType<Map>()
                .map((m) => _PopularCity(m['name']?.toString() ?? '', m['image']?.toString() ?? '',
                    m['state']?.toString() ?? ''))
                .where((c) => c.name.isNotEmpty)
                .toList()
            : [];
        final popularNames = _popular.map((p) => p.name.trim().toLowerCase()).toSet();
        // A city in both lists stays only in the popular grid (Android otherWithoutPopular).
        _other = oth is List
            ? oth
                .map((e) => e.toString())
                .where((c) => c.trim().isNotEmpty && !popularNames.contains(c.trim().toLowerCase()))
                .toList()
            : [];
        _states = st is Map
            ? {for (final e in st.entries) e.key.toString(): e.value.toString()}
            : <String, String>{};
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _stateFor(String city) {
    for (final e in _states.entries) {
      if (e.key.toLowerCase() == city.toLowerCase()) return e.value;
    }
    for (final p in _popular) {
      if (p.name.toLowerCase() == city.toLowerCase()) return p.state;
    }
    return '';
  }

  /// Typo-tolerant match on city or state (Android FuzzyMatch): substring, or the query's letters
  /// in order (so "ahmdb" finds "Ahmedabad").
  bool _matches(String text, String q) {
    final t = text.toLowerCase();
    if (t.contains(q)) return true;
    var i = 0;
    for (final ch in q.replaceAll(' ', '').split('')) {
      i = t.indexOf(ch, i);
      if (i < 0) return false;
      i++;
    }
    return q.length >= 3;
  }

  bool _cityMatches(String city) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final state = _stateFor(city);
    return _matches(city, q) || (state.isNotEmpty && _matches(state, q));
  }

  Future<void> _select(String city, {bool close = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final state = _stateFor(city);
    await prefs.setString('city', city);
    await prefs.setString('selected_address_title', city);
    await prefs.setString('selected_address', state.isNotEmpty ? '$city, $state' : city);
    if (state.isNotEmpty) await prefs.setString('state', state);
    _changed = true;
    if (!mounted) return;
    setState(() => _selected = city);
    if (close) Navigator.of(context).pop(true);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast('Location permission is needed to detect your city');
        return;
      }
      final pos = await LocationService.getCurrentPosition();
      if (pos == null) {
        _toast("Couldn't detect your location. Try again.");
        return;
      }
      String? city;
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final m = marks.first;
          for (final s in [m.locality, m.subAdministrativeArea, m.administrativeArea]) {
            if ((s ?? '').trim().isNotEmpty) {
              city = s;
              break;
            }
          }
        }
      } catch (_) {}
      if (city == null || city.trim().isEmpty) {
        _toast("Couldn't resolve your city. Please search instead.");
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      // Coordinates let the Buy feed rank cars nearest-first.
      await prefs.setDouble('latitude', pos.latitude);
      await prefs.setDouble('longitude', pos.longitude);
      final name = city.trim();
      final known = _popular.any((p) => p.name.toLowerCase() == name.toLowerCase()) ||
          _other.any((o) => o.toLowerCase() == name.toLowerCase());
      if (!known) _other = [name, ..._other];
      _query = '';
      // Android keeps the sheet open so the detected city shows as selected.
      await _select(name, close: false);
    } catch (_) {
      _toast("Couldn't detect your location. Try again.");
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final popular = _popular.where((p) => _cityMatches(p.name)).toList();
    final other = _other.where(_cityMatches).toList();
    final showToggle = other.length > _otherCollapsedLimit;
    final visibleOther =
        _otherExpanded || !showToggle ? other : other.take(_otherCollapsedLimit).toList();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  color: const Color(0xFFD1D1D1),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 16),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(_changed),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF1F1F1), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20, color: Colors.black),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text('Select your city',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Text('Choose your city to see best deals near you',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 20, color: Color(0xFF999999)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                textInputAction: TextInputAction.search,
                                onChanged: (v) => setState(() {
                                  _query = v;
                                  _otherExpanded = false;
                                }),
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Search for your city',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _detecting ? null : _detect,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('Detect my location',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  children: [
                    if (!_loading && _query.trim().isNotEmpty && popular.isEmpty && other.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text('No matching city found',
                              style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
                        ),
                      ),
                    if (popular.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: popular.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                        ),
                        itemBuilder: (_, i) => _popularCell(popular[i]),
                      ),
                    if (popular.isNotEmpty && other.isNotEmpty) const SizedBox(height: 24),
                    if (other.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFF1F1F1), shape: BoxShape.circle),
                              child: const Icon(Icons.location_on, size: 14, color: _purple),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Other cities',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black)),
                                Text('More cities coming soon',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final c in visibleOther) _otherRow(c),
                      if (showToggle)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => setState(() => _otherExpanded = !_otherExpanded),
                            child: Text(_otherExpanded ? 'View less' : 'View more',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: _purple)),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_loading || _detecting) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _popularCell(_PopularCity c) {
    final selected = c.name.toLowerCase() == _selected.toLowerCase();
    return GestureDetector(
      onTap: () => _select(c.name),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _purple : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Expanded(
                    child: c.image.isEmpty
                        ? const Icon(Icons.location_city, color: Colors.black26)
                        : Image.network(c.image,
                            fit: BoxFit.contain,
                            frameBuilder: (_, child, frame, sync) => sync || frame != null
                                ? child
                                : const Center(
                                    child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2))),
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.location_city, color: Colors.black26)),
                  ),
                  const SizedBox(height: 4),
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black)),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check_circle, size: 16, color: _purple),
              ),
          ],
        ),
      ),
    );
  }

  Widget _otherRow(String city) {
    final selected = city.toLowerCase() == _selected.toLowerCase();
    final state = _stateFor(city);
    return InkWell(
      onTap: () => _select(city),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20, color: _purple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(city,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? _purple : Colors.black)),
                  if (state.isNotEmpty)
                    Text(state, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.chevron_right,
                size: 20, color: selected ? _purple : const Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
