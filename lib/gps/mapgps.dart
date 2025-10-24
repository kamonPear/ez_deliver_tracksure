import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
// +++ [NEW IMPORT] +++
import 'package:geolocator/geolocator.dart'; 
// +++

class Mapgps extends StatefulWidget {
  final LatLng? initialLocation;
  const Mapgps({super.key, this.initialLocation});

  @override
  State<Mapgps> createState() => _MapgpsState();
}

class _MapgpsState extends State<Mapgps> {
  final MapController _mapController = MapController();
  
  // ตำแหน่งที่ถูกเลือก/ตำแหน่งกึ่งกลางปัจจุบัน
  LatLng? _currentCenterLocation; 
  String _selectedAddress = 'กรุณาเลือกตำแหน่งบนแผนที่';
  bool _isGeocoding = false;
  bool _isPopping = false;
  
  // Debouncing timer เพื่อป้องกันการเรียก API ถี่เกินไปขณะลากแผนที่
  Timer? _debounce; 

  @override
  void initState() {
    super.initState();
    // กำหนดตำแหน่งเริ่มต้น
    _currentCenterLocation = widget.initialLocation ?? const LatLng(16.244249, 103.249615);

    // ดึงที่อยู่เริ่มต้น (ถ้ามี)
    if (_currentCenterLocation != null) {
      _getAddressFromLatLng(_currentCenterLocation!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // --- ฟังก์ชันค้นหาที่อยู่โดยใช้ OpenStreetMap (Nominatim API) ---
  Future<void> _getAddressFromLatLng(LatLng point) async {
    if (_isGeocoding || _isPopping) return;
    
    if (mounted) {
      setState(() {
        _isGeocoding = true;
        _currentCenterLocation = point;
        // ป้องกันการทับซ้อนข้อความถ้าตำแหน่งเดิมเป็น null
        if(_selectedAddress != 'กำลังค้นหาที่อยู่...') {
           _selectedAddress = 'กำลังค้นหาที่อยู่...';
        }
      });
    }

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}&accept-language=th');

      final response = await http.get(
        url,
        headers: {
          // *** ต้องใส่ User-Agent ตามข้อกำหนดของ Nominatim ***
          'User-Agent': 'com.example.deliver_tracksure', 
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)); 
        if (data != null && data['display_name'] != null) {
          _selectedAddress = data['display_name'];
        } else {
          _selectedAddress = 'ไม่พบข้อมูลที่อยู่สำหรับพิกัดนี้';
        }
      } else {
        _selectedAddress = 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์ (Code: ${response.statusCode})';
      }
    } catch (e) {
      _selectedAddress = 'เกิดข้อผิดพลาดในการค้นหาที่อยู่';
      print("Geocoding Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
        });
      }
    }
  }
  
  // --- ตัวจัดการเหตุการณ์แผนที่สำหรับการ Debounce ---
  void _handleMapEvent(MapEvent event) {
    // ยกเลิก Timer ก่อนหน้าเมื่อมีการเคลื่อนที่ใดๆ
    if (event is MapEventMove) {
      _debounce?.cancel();
    } 
    // เมื่อการเคลื่อนที่สิ้นสุด ให้เริ่ม Timer
    else if (event is MapEventMoveEnd) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          // ดึงตำแหน่งกึ่งกลางปัจจุบันของแผนที่
          final LatLng newCenter = _mapController.camera.center;
          _getAddressFromLatLng(newCenter);
        }
      });
    }
  }
  
  // +++ [NEW FUNCTION: Get Current Location] +++
  Future<void> _getCurrentLocation() async {
    try {
      // 1. ตรวจสอบสิทธิ์
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่สามารถเข้าถึงตำแหน่งปัจจุบันได้ กรุณาเปิดการอนุญาตตำแหน่ง')),
            );
          }
          return;
        }
      }

      if (_isGeocoding) return; 

      // 2. แสดงสถานะกำลังโหลด
      setState(() {
        _isGeocoding = true;
        _selectedAddress = 'กำลังค้นหาตำแหน่งปัจจุบัน...';
      });

      // 3. ดึงตำแหน่ง
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      final LatLng newLocation = LatLng(position.latitude, position.longitude);

      // 4. เลื่อนแผนที่
      _mapController.move(newLocation, 16.0); 

      // 5. ค้นหาที่อยู่และอัปเดตสถานะ
      await _getAddressFromLatLng(newLocation);

    } catch (e) {
      print("Error getting current location: $e");
       if (mounted) {
        setState(() {
          _isGeocoding = false;
          _selectedAddress = 'ไม่สามารถระบุตำแหน่งปัจจุบันได้';
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการระบุตำแหน่ง: ${e.toString()}')),
      );
    }
  }
  // +++ [END NEW FUNCTION] +++


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ส่วน Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50.0, bottom: 20.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 30, 182, 112),
                  Color.fromARGB(255, 27, 155, 120)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Text('TRACK-SURE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alumniSansInlineOne(
                      fontSize: 65,
                      color: Colors.white,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          // ส่วนแผนที่
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    // ใช้ตำแหน่งกึ่งกลางเริ่มต้นที่กำหนดไว้
                    initialCenter: _currentCenterLocation!, 
                    initialZoom: widget.initialLocation != null ? 16.0 : 15.0, 
                    // ใช้ onMapEvent แทน onTap เพื่ออัปเดตตำแหน่งเมื่อแผนที่หยุดลาก
                    onMapEvent: _handleMapEvent,
                  ),
                  children: [ 
                    // *** แก้ไข: ลบ 'const' ที่นำหน้า TileLayer ออกไป ***
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.deliver_tracksure',
                    ),
                    // ไม่ใช้ MarkerLayer อีกต่อไป เพราะ Marker ถูกตรึงที่กึ่งกลางหน้าจอ
                  ],
                ),
                
                // --- Fixed Center Marker (หมุดตรึงกึ่งกลาง) ---
                const Center(
                  child: Padding(
                    // เลื่อนหมุดขึ้นเล็กน้อยเพื่อให้ปลายหมุดชี้ตรงกลางจอ
                    padding: EdgeInsets.only(bottom: 40), 
                    child: Icon(
                      Icons.location_on,
                      size: 45,
                      color: Colors.red,
                    ),
                  ),
                ),
                // --- End Fixed Center Marker ---
                
                // +++ [NEW: Floating Action Button for Current Location] +++
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton(
                    heroTag: "currentLocationBtn", // เพิ่ม heroTag เพื่อหลีกเลี่ยง error
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color.fromARGB(255, 30, 182, 112),
                    onPressed: _isGeocoding ? null : _getCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                // +++ [END NEW] +++

                // ส่วนแสดงผลลัพธ์และปุ่มยืนยัน
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, -2))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isGeocoding
                            ? const CircularProgressIndicator(color: Color.fromARGB(255, 30, 182, 112))
                            : Text(
                                _selectedAddress,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.prompt(fontSize: 14),
                              ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('ยืนยันตำแหน่งนี้'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              textStyle: GoogleFonts.prompt(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          onPressed: _isPopping || _isGeocoding || _currentCenterLocation == null
                              ? null
                              : () {
                                  setState(() => _isPopping = true);
                                  // ใช้ตำแหน่งล่าสุดที่ถูกยืนยันโดยการลากแผนที่
                                  Navigator.of(context).pop({
                                    'latlng': _currentCenterLocation,
                                    'address': _selectedAddress,
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
