import 'dart:async'; // <--- 1. Import (สำหรับ StreamSubscription)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/pages/EditPro.dart';
import 'package:ez_deliver_tracksure/pages/all.dart';
import 'package:ez_deliver_tracksure/pages/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // <--- 2. Import FlutterMap
import 'package:latlong2/latlong.dart' as latLng; // <--- 3. Import latlong2
import 'bottom_bar.dart';

class ProductStatus extends StatefulWidget {
  final String orderId;

  const ProductStatus({super.key, required this.orderId});

  @override
  State<ProductStatus> createState() => _ProductStatusState();
}

class _ProductStatusState extends State<ProductStatus> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  String? _errorMessage;
  DocumentSnapshot? _orderData; // ข้อมูลออเดอร์ (จาก Stream)
  DocumentSnapshot? _riderData; // ข้อมูลไรเดอร์ (ชื่อ, ทะเบียน)

  // --- 4. ตัวแปรสำหรับ Map และ Stream ---
  final MapController _mapController = MapController();
  StreamSubscription? _orderSub; // ดักฟังออเดอร์ (เพื่อเอา riderId)
  StreamSubscription? _riderSub; // ดักฟังพิกัดไรเดอร์
  latLng.LatLng? _currentRiderLocation; // พิกัดไรเดอร์ล่าสุด

  static const Color primaryGreen = Color(0xFF00A859);
  static const Color lightTeal = Color(0xFFE0F7F0);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;

  @override
  void initState() {
    super.initState();
    // 5. เปลี่ยนจาก _fetchData() เป็น _listenToOrder()
    _listenToOrder();
  }

  @override
  void dispose() {
    // 6. ยกเลิกการดักฟังทั้งหมดเมื่อออกจากหน้า
    _orderSub?.cancel();
    _riderSub?.cancel();
    super.dispose();
  }

  // 7. (แก้ไข) ฟังก์ชันดึงข้อมูลหลัก (เปลี่ยนเป็น Stream)
  // นี่คือส่วนที่แก้ปัญหา "ดึงข้อมูลไรเดอร์ไม่ได้"
  Future<void> _listenToOrder() async {
    setState(() => _isLoading = true);

    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots() // <--- .snapshots() คือการดักฟังแบบเรียลไทม์
        .listen(
          (orderDoc) async {
            if (!orderDoc.exists) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'ไม่พบข้อมูลออเดอร์';
                });
              }
              return;
            }

            // อัปเดตข้อมูลออเดอร์ใน State
            final orderData = orderDoc.data() as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                _orderData = orderDoc;
                _isLoading = false; // มีข้อมูลแล้ว หยุดโหลด
              });
            }

            final String? riderId = orderData['riderId'] as String?;

            // ตรวจสอบว่ามี riderId และยังไม่ได้ดักฟังไรเดอร์คนนี้
            if (riderId != null &&
                riderId.isNotEmpty &&
                (_riderData?.id != riderId)) {
              // 1. หยุดดักฟังไรเดอร์คนเก่า (ถ้ามี)
              await _riderSub?.cancel();

              // 2. ดึงข้อมูล "นิ่ง" ของไรเดอร์ (ชื่อ, ทะเบียน) มาเก็บไว้
              final riderDoc = await FirebaseFirestore.instance
                  .collection('riders')
                  .doc(riderId)
                  .get();

              if (riderDoc.exists && mounted) {
                setState(() {
                  _riderData = riderDoc;
                });
              }

              // 3. เริ่ม "ดักฟัง" พิกัดเรียลไทม์ของไรเดอร์คนนี้
              _listenToRiderLocation(riderId);
            }
          },
          onError: (e) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
              });
            }
          },
        );
  }

  // 8. (ใหม่) ฟังก์ชันสำหรับดักฟังพิกัดไรเดอร์โดยเฉพาะ
  void _listenToRiderLocation(String riderId) {
    _riderSub = FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .snapshots()
        .listen((riderSnapshot) {
          if (!riderSnapshot.exists) return;
          final data = riderSnapshot.data() as Map<String, dynamic>;

          // (สันนิษฐานว่า field ชื่อ current_latitude และ current_longitude)
          final double? lat = data['current_latitude'];
          final double? lng = data['current_longitude'];

          if (lat != null && lng != null) {
            final newPos = latLng.LatLng(lat, lng);
            if (mounted) {
              setState(() {
                _currentRiderLocation = newPos;
              });
            }

            // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
            //         <--- จุดแก้ไข
            // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼

            // ลบ if (_mapController.ready) ออก
            _mapController.move(newPos, _mapController.camera.zoom);

            // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
          }
        });
  }

  void _onItemTapped(int index) {
    // If the tapped item is the current one, do nothing.
    if (_selectedIndex == index) return;

    // We use Navigator.push so that the back button works as expected.
    // The state of _selectedIndex is only changed for the home button.
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        // Navigate to the Products (History) page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Products()),
        );
        break;
      case 2:
        // Navigate to the EditPro (Others) page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditPro()),
        );
        break;
    }
  }

  // 9. (Helper) ฟังก์ชันแปลง status เป็นข้อความ (เหมือนเดิม)
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'สถานะรอไรเดอร์รับสินค้า';
      case 'accepted':
        return 'ไรเดอร์รับออเดอร์แล้ว';
      case 'en_route':
        return 'ไรเดอร์กำลังไปรับสินค้า';
      case 'picked_up': // <--- ใช้ 'picked_up' ไม่ใช่ 'pickedUp'
        return 'ไรเดอร์กำลังไปส่งสินค้า';
      case 'completed':
        return 'จัดส่งสินค้าสำเร็จ';
      default:
        // แก้บั๊ก "ไม่ทราบสถานะ"
        return 'กำลังดำเนินการ (สถานะ: $status)';
    }
  }

  // 10. (ใหม่) ฟังก์ชันสร้าง Markers สำหรับ OpenStreetMap
  List<Marker> _buildMapMarkers(Map<String, dynamic> order) {
    final List<Marker> markers = [];

    // 1. Marker จุดรับของ (Pickup)
    if (order['pickup_latitude'] != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: latLng.LatLng(
            order['pickup_latitude'],
            order['pickup_longitude'],
          ),
          child: const Icon(Icons.store, color: Colors.green, size: 40),
        ),
      );
    }

    // 2. Marker จุดส่งของ (Destination)
    if (order['destination_latitude'] != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: latLng.LatLng(
            order['destination_latitude'],
            order['destination_longitude'],
          ),
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    // 3. Marker ไรเดอร์ (Real-time)
    if (_currentRiderLocation != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: _currentRiderLocation!,
          child: const Icon(Icons.motorcycle, color: Colors.blue, size: 35),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: primaryGreen),
        body: const Center(child: CircularProgressIndicator()),
       
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('เกิดข้อผิดพลาด')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    final order = _orderData!.data() as Map<String, dynamic>;
    final rider = _riderData?.data() as Map<String, dynamic>?;
    final String status = order['status'] ?? 'pending';

    // 11. (แก้ไข) ตรรกะ Step ต้องตรงกับชื่อ status
    final bool step1Active = status == 'pending';
    final bool step2Active = status == 'accepted';
    // แก้ไข 'pickedUp' (camelCase) เป็น 'picked_up' (snake_case)
    final bool step3Active = status == 'en_route' || status == 'pickedUp';
    final bool step4Active = status == 'completed';

    // 12. พิกัดเริ่มต้นของกล้อง
    final latLng.LatLng initialCameraPos = latLng.LatLng(
      order['pickup_latitude'] ?? 16.25, // พิกัดเริ่มต้น (จุดรับของ)
      order['pickup_longitude'] ?? 103.23,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        // ... (AppBar เหมือนเดิม) ...
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          backgroundColor: primaryGreen,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF75C2A4),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text(
                'สถานะการส่งสินค้า',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 2.0,
                      color: Colors.black26,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Tracking Steps (เหมือนเดิม)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  TrackingStep(
                    icon: Icons.access_time_filled,
                    label: 'รอไรเดอร์รับสินค้า',
                    isActive: step1Active,
                    color: primaryGreen,
                  ),
                  TrackingStep(
                    icon: Icons.description,
                    label: 'ได้รับออเดอร์แล้ว',
                    isActive: step2Active,
                    color: primaryGreen,
                  ),
                  TrackingStep(
                    icon: Icons.motorcycle,
                    label: 'ไรเดอร์กำลังมา',
                    isActive: step3Active,
                    color: primaryGreen,
                  ),
                  TrackingStep(
                    icon: Icons.check_circle,
                    label: 'จัดส่งสินค้าสำเร็จ',
                    isActive: step4Active,
                    color: primaryGreen,
                  ),
                ],
              ),
            ),

            // 13. (แก้ไข) แทนที่ Placeholder ด้วย FlutterMap
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 250, // เพิ่มความสูงให้แผนที่
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCameraPos,
                      initialZoom: 14.0,
                    ),
                    children: [
                      // Layer ของแผนที่ (OpenStreetMap)
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.ez_deliver_tracksure', // <--- ใส่ชื่อ package ของแอปคุณ
                      ),
                      // Layer ของ Marker
                      MarkerLayer(markers: _buildMapMarkers(order)),
                    ],
                  ),
                ),
              ),
            ),

            // Status Text (เหมือนเดิม)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  _getStatusText(status),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),

            // Camera Icon/Prompt (เหมือนเดิม)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 20.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 60,
                  color: primaryGreen,
                ),
              ),
            ),

            // Rider Info Header (เหมือนเดิม)
            const Center(
              child: Text(
                'ข้อมูลไรเดอร์ที่รับงาน',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            // Rider Info Card (เหมือนเดิม)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text('ชื่อ : ', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 4),
                        Text('เบอร์โทร : ', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 4),
                        Text('ทะเบียน : ', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // 14. ตรวจสอบชื่อ field ให้ตรงกับ 'riders' collection
                          Text(
                            rider?['rider_name'] ??
                                (status == 'pending' ? 'กำลังค้นหา...' : 'N/A'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rider?['rider_phone'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rider?['license_plate'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}

// Custom Widget for the Tracking Steps (ไม่ต้องแก้ไข)
class TrackingStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;

  const TrackingStep({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.white,
            border: Border.all(
              color: isActive ? color : Colors.grey.shade400,
              width: 2.0,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey.shade400,
            size: 24.0,
          ),
        ),
        const SizedBox(height: 4.0),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.black : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
