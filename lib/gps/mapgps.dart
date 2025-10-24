// lib/pages/mapgps.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class Mapgps extends StatefulWidget {
  final LatLng? initialLocation;
  const Mapgps({super.key, this.initialLocation});

  @override
  State<Mapgps> createState() => _MapgpsState();
}

class _MapgpsState extends State<Mapgps> {
  final MapController _mapController = MapController();

  LatLng? _currentCenterLocation;
  String _selectedAddress = 'กรุณาเลือกตำแหน่งบนแผนที่';
  bool _isGeocoding = false;
  bool _isPopping = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentCenterLocation = widget.initialLocation ?? const LatLng(16.244249, 103.249615);
    if (_currentCenterLocation != null) {
      Future.microtask(() => _getAddressFromLatLng(_currentCenterLocation!));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng point) async {
    if (_isGeocoding || _isPopping) return;
    if (mounted) {
      setState(() {
        _isGeocoding = true;
        _currentCenterLocation = point;
        if (_selectedAddress != 'กำลังค้นหาที่อยู่...') _selectedAddress = 'กำลังค้นหาที่อยู่...';
      });
    }
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}&accept-language=th');
      final response = await http.get(url, headers: { 'User-Agent': 'com.example.deliver_tracksure' });
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _selectedAddress = (data != null && data['display_name'] != null) ? data['display_name'] : 'ไม่พบข้อมูลที่อยู่สำหรับพิกัดนี้';
      } else {
        _selectedAddress = 'เชื่อมต่อเซิร์ฟเวอร์ผิดพลาด (Code: ${response.statusCode})';
      }
    } catch (e) {
      _selectedAddress = 'เกิดข้อผิดพลาดในการค้นหาที่อยู่';
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _handleMapEvent(MapEvent event) {
    if (event is MapEventMove) {
      _debounce?.cancel();
    } else if (event is MapEventMoveEnd) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          final LatLng newCenter = _mapController.camera.center;
          _getAddressFromLatLng(newCenter);
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isGeocoding) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเข้าถึงตำแหน่งปัจจุบันได้ กรุณาเปิดการอนุญาตตำแหน่ง')));
        }
        return;
      }
    }

    setState(() { _isGeocoding = true; _selectedAddress = 'กำลังค้นหาตำแหน่งปัจจุบัน...'; });

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('ไม่สามารถระบุตำแหน่งได้ทันเวลา (Timeout)');
        });

      final LatLng newLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(newLocation, 16.0);
      _getAddressFromLatLng(newLocation);
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() { _selectedAddress = 'ไม่สามารถระบุตำแหน่งได้ทันเวลา กรุณาลองอีกครั้ง'; _isGeocoding = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _selectedAddress = 'ไม่สามารถระบุตำแหน่งปัจจุบันได้'; _isGeocoding = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการระบุตำแหน่ง: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 50, bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color.fromARGB(255, 30, 182, 112), Color.fromARGB(255, 27, 155, 120)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            bottom: false,
            child: Text('TRACK-SURE', textAlign: TextAlign.center,
              style: GoogleFonts.alumniSansInlineOne(fontSize: 65, color: Colors.white, letterSpacing: 3, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenterLocation!,
                initialZoom: widget.initialLocation != null ? 16.0 : 15.0,
                onMapEvent: _handleMapEvent,
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.deliver_tracksure'),
              ],
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, size: 45, color: Colors.red),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: FloatingActionButton(
                heroTag: "currentLocationBtn",
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color.fromARGB(255, 30, 182, 112),
                onPressed: _isGeocoding ? null : _getCurrentLocation,
                child: _isGeocoding ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color.fromARGB(255, 30, 182, 112)))
                                    : const Icon(Icons.my_location),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _isGeocoding
                      ? const CircularProgressIndicator(color: Color.fromARGB(255, 30, 182, 112))
                      : Text(_selectedAddress, textAlign: TextAlign.center, style: GoogleFonts.prompt(fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('ยืนยันตำแหน่งนี้'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      textStyle: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isPopping || _isGeocoding || _currentCenterLocation == null ? null : () {
                      setState(() => _isPopping = true);
                      Navigator.of(context).pop({'latlng': _currentCenterLocation, 'address': _selectedAddress});
                    },
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
