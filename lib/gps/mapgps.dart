import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // Use for free API calls
import 'dart:convert'; // Use for JSON data conversion

class Mapgps extends StatefulWidget {
  final LatLng? initialLocation;
  const Mapgps({super.key, this.initialLocation});

  @override
  State<Mapgps> createState() => _MapgpsState();
}

class _MapgpsState extends State<Mapgps> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String _selectedAddress = 'กรุณาเลือกตำแหน่งบนแผนที่';
  bool _isGeocoding = false;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _getAddressFromLatLng(widget.initialLocation!);
    } else {
      // ถ้าไม่มีค่าเริ่มต้น ให้ตั้งค่าเป็นตำแหน่งของมหาวิทยาลัยมหาสารคาม (เขตพื้นที่ในเมือง)
      // Coordinates for Mahasarakham University (Urban Campus): 16.2001, 103.2847
      _selectedLocation = const LatLng(16.244249, 103.249615);
    }
  }

  // ฟังก์ชันค้นหาที่อยู่โดยใช้ OpenStreetMap (Nominatim API)
  Future<void> _getAddressFromLatLng(LatLng point) async {
    if (_isGeocoding) return;
    setState(() {
      _isGeocoding = true;
      _selectedLocation = point;
      _selectedAddress = 'กำลังค้นหาที่อยู่...';
    });

    try {
      // สร้าง URL สำหรับเรียกใช้ Nominatim API (บริการฟรี)
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}&accept-language=th');

      // ส่งคำขอ HTTP GET
      // Nominatim กำหนดให้ต้องใส่ User-Agent ใน header
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'com.example.deliver_tracksure', // ควรเปลี่ยนเป็น package name ของโปรเจกต์คุณ
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(
            response.bodyBytes)); // ถอดรหัสเป็น UTF-8 เพื่อรองรับภาษาไทย
        if (data != null && data['display_name'] != null) {
          _selectedAddress = data['display_name'];
        } else {
          _selectedAddress = 'ไม่พบข้อมูลที่อยู่สำหรับพิกัดนี้';
        }
      } else {
        _selectedAddress = 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์';
      }
    } catch (e) {
      _selectedAddress = 'เกิดข้อผิดพลาดในการค้นหาที่อยู่';
    } finally {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
        });
      }
    }
  }

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
                    initialCenter: _selectedLocation!,
                    // ปรับ zoom เป็น 15.0 เมื่อไม่มี initialLocation เพื่อให้เห็น มมส ชัดเจนขึ้น
                    initialZoom: widget.initialLocation != null ? 16.0 : 15.0, 
                    onTap: (tapPosition, point) {
                      if (!_isPopping) {
                        _getAddressFromLatLng(point);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.deliver_tracksure',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on,
                                size: 45, color: Colors.red),
                          ),
                        ],
                      ),
                  ],
                ),
                // ส่วนแสดงผลลัพธ์และปุ่มยืนยัน
                if (_selectedLocation != null)
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
                              ? const CircularProgressIndicator()
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
                            onPressed: _isPopping || _isGeocoding
                                ? null
                                : () {
                                    setState(() => _isPopping = true);
                                    Navigator.of(context).pop({
                                      'latlng': _selectedLocation,
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
