import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;

// --- Import หน้าอื่นๆ ---
import 'package:ez_deliver_tracksure/pages/all.dart'; // HomeScreen
import 'package:ez_deliver_tracksure/pages/EditPro.dart'; // EditPro
import 'order_list_page.dart'; // OrderListPage
// -----------------------

import 'bottom_bar.dart'; // BottomBar

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
  DocumentSnapshot? _orderData;
  DocumentSnapshot? _riderData;

  final MapController _mapController = MapController();
  StreamSubscription? _orderSub;
  StreamSubscription? _riderSub;
  latLng.LatLng? _currentRiderLocation;

  // ▼▼▼▼▼▼ [ CODE ที่เพิ่ม ] ▼▼▼▼▼▼
  String? _pickupImageUrl; // ตัวแปรเก็บ URL รูปตอนรับของ
  // ▲▲▲▲▲▲ [ CODE ที่เพิ่ม ] ▲▲▲▲▲▲

  static const Color primaryGreen = Color(0xFF00A859);
  // static const Color lightTeal = Color(0xFFE0F7F0); // ไม่ได้ใช้ ลบออกได้
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _listenToOrder();
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _riderSub?.cancel();
    super.dispose();
  }

  Future<void> _listenToOrder() async {
    setState(() => _isLoading = true);

    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((orderDoc) async {
      if (!orderDoc.exists) {
        if (mounted) setState(() { _isLoading = false; _errorMessage = 'ไม่พบข้อมูลออเดอร์'; });
        return;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;

      // ▼▼▼▼▼▼ [ CODE ที่เพิ่ม ] ▼▼▼▼▼▼
      // ดึง URL รูปภาพ ถ้ามี
      final String? fetchedPickupImageUrl = orderData['pickupImageUrl'] as String?;
      // ▲▲▲▲▲▲ [ CODE ที่เพิ่ม ] ▲▲▲▲▲▲


      if (mounted) {
        setState(() {
          _orderData = orderDoc;
          _isLoading = false; // มีข้อมูลแล้ว หยุดโหลด

          // ▼▼▼▼▼▼ [ CODE ที่เพิ่ม ] ▼▼▼▼▼▼
          // อัปเดต URL รูปภาพใน State
          if (fetchedPickupImageUrl != null && fetchedPickupImageUrl.isNotEmpty) {
            _pickupImageUrl = fetchedPickupImageUrl;
          } else {
             _pickupImageUrl = null; // ถ้าไม่มี ให้เป็น null
          }
          // ▲▲▲▲▲▲ [ CODE ที่เพิ่ม ] ▲▲▲▲▲▲

        });
       }


      final String? riderId = orderData['riderId'] as String?;

      if (riderId != null && riderId.isNotEmpty && (_riderData?.id != riderId)) {
        await _riderSub?.cancel();
        final riderDoc = await FirebaseFirestore.instance.collection('riders').doc(riderId).get();
        if (riderDoc.exists && mounted) setState(() { _riderData = riderDoc; });
        _listenToRiderLocation(riderId);
      }
    }, onError: (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}'; });
    });
  }

  void _listenToRiderLocation(String riderId) {
    _riderSub = FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .snapshots()
        .listen((riderSnapshot) {
      if (!riderSnapshot.exists) return;
      final data = riderSnapshot.data() as Map<String, dynamic>;

      // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
      // เปลี่ยนไปใช้ (as num?)?.toDouble() เพื่อความปลอดภัย
      final double? lat = (data['current_latitude'] as num?)?.toDouble();
      final double? lng = (data['current_longitude'] as num?)?.toDouble();
      // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

      if (lat != null && lng != null) {
        final newPos = latLng.LatLng(lat, lng);
        if (mounted) setState(() { _currentRiderLocation = newPos; });
        // ทำให้แผนที่เคลื่อนที่ตาม (ถ้า MapController พร้อมใช้งาน)
        try {
          // ใช้ try-catch เผื่อกรณี controller ยังไม่พร้อมจริงๆ
           _mapController.move(newPos, _mapController.camera.zoom);
        } catch (e) {
          print("MapController not ready or error moving map: $e");
        }
      }
    });
  }

  void _onItemTapped(int index) {
     // ... (โค้ดส่วนนี้เหมือนเดิม) ...
      setState(() { _selectedIndex = index; });
      switch (index) {
        case 0: Navigator.of(context).popUntil((route) => route.isFirst); break;
        case 1:
          if (Navigator.canPop(context)) { Navigator.pop(context); }
          else { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OrderListPage())); }
          break;
        case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EditPro())); break;
      }
  }

  String _getStatusText(String status) {
     switch (status.toLowerCase()) { // <-- เปลี่ยนเป็น lowerCase เพื่อรองรับหลายแบบ
       case 'pending': return 'สถานะรอไรเดอร์รับสินค้า';
       case 'accepted': return 'ไรเดอร์รับออเดอร์แล้ว';
       case 'en_route': return 'ไรเดอร์กำลังไปรับสินค้า';
       case 'picked_up': return 'ไรเดอร์รับสินค้าแล้ว (กำลังไปส่ง)'; // <-- ปรับข้อความเล็กน้อย
       case 'completed': return 'จัดส่งสินค้าสำเร็จ';
       case 'delivered': return 'จัดส่งสินค้าสำเร็จ'; // <-- เพิ่ม delivered
       default: return 'กำลังดำเนินการ (สถานะ: $status)';
     }
  }

 List<Marker> _buildMapMarkers(Map<String, dynamic> order) {
   final List<Marker> markers = [];
   // ใช้ (as num?)?.toDouble() เพื่อความปลอดภัย
   final pickLat = (order['pickup_latitude'] as num?)?.toDouble();
   final pickLng = (order['pickup_longitude'] as num?)?.toDouble();
   if (pickLat != null && pickLng != null) {
     markers.add(Marker(
       width: 80.0, height: 80.0,
       point: latLng.LatLng(pickLat, pickLng),
       child: const Icon(Icons.store, color: Colors.green, size: 40),
     ));
   }

   final destLat = (order['destination_latitude'] as num?)?.toDouble();
   final destLng = (order['destination_longitude'] as num?)?.toDouble();
   if (destLat != null && destLng != null) {
     markers.add(Marker(
       width: 80.0, height: 80.0,
       point: latLng.LatLng(destLat, destLng),
       child: const Icon(Icons.location_on, color: Colors.red, size: 40),
     ));
   }

   if (_currentRiderLocation != null) {
     markers.add(Marker(
       width: 80.0, height: 80.0,
       point: _currentRiderLocation!,
       child: const Icon(Icons.motorcycle, color: Colors.blue, size: 35),
     ));
   }
   return markers;
 }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // ... (Loading Scaffold เหมือนเดิม) ...
        return Scaffold(
         appBar: AppBar(backgroundColor: primaryGreen, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.of(context).pop())), // เพิ่มปุ่ม Back
         body: const Center(child: CircularProgressIndicator()),
         bottomNavigationBar: BottomBar( currentIndex: _selectedIndex, onItemSelected: (_) {}, ),
       );
    }

    if (_errorMessage != null) {
      // ... (Error Scaffold เหมือนเดิม) ...
        return Scaffold(
         appBar: AppBar(title: const Text('เกิดข้อผิดพลาด'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.of(context).pop())), // เพิ่มปุ่ม Back
         body: Center(child: Text(_errorMessage!)),
         bottomNavigationBar: BottomBar( currentIndex: _selectedIndex, onItemSelected: (_) {}, ),
       );
    }

    final order = _orderData!.data() as Map<String, dynamic>;
    final rider = _riderData?.data() as Map<String, dynamic>?;
    final String status = (order['status'] as String?)?.toLowerCase() ?? 'pending'; // <-- ใช้ lowerCase

    final bool step1Active = status == 'pending';
    final bool step2Active = status == 'accepted';
    final bool step3Active = status == 'en_route' || status == 'picked_up';
    final bool step4Active = status == 'completed' || status == 'delivered'; // <-- เพิ่ม delivered

    // ใช้ (as num?)?.toDouble() เพื่อความปลอดภัย
    double initialLat = 16.25; // Default fallback
    double initialLng = 103.23; // Default fallback
    final pLat = (order['pickup_latitude'] as num?)?.toDouble();
    final pLng = (order['pickup_longitude'] as num?)?.toDouble();
    if (pLat != null && pLng != null) {
        initialLat = pLat;
        initialLng = pLng;
    } else {
       // ถ้าจุดรับไม่มี ลองใช้จุดส่งแทน (เผื่อกรณีข้อมูลไม่ครบ)
       final dLat = (order['destination_latitude'] as num?)?.toDouble();
       final dLng = (order['destination_longitude'] as num?)?.toDouble();
       if(dLat != null && dLng != null) {
         initialLat = dLat;
         initialLng = dLng;
       }
    }
    final latLng.LatLng initialCameraPos = latLng.LatLng(initialLat, initialLng);

    // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
    // --- สร้าง Widget สำหรับแสดงรูปภาพหรือไอคอนกล้อง ---
    Widget imageOrIconWidget;

    // ตรวจสอบว่ามี URL รูปภาพ และสถานะเป็น picked_up หรือ completed/delivered หรือไม่
    if (_pickupImageUrl != null && (status == 'picked_up' || status == 'completed' || status == 'delivered')) {
       // ถ้ามี ให้แสดงรูปภาพจาก Network
       imageOrIconWidget = ClipRRect( // ใช้ ClipRRect เพื่อให้มุมโค้ง
          borderRadius: BorderRadius.circular(15.0),
          child: Image.network(
            _pickupImageUrl!,
            fit: BoxFit.cover, // ทำให้รูปเต็ม Container
            width: double.infinity, // ทำให้รูปเต็มความกว้าง Container
            height: double.infinity, // ทำให้รูปเต็มความสูง Container
            // เพิ่ม loadingBuilder เพื่อแสดงสถานะตอนโหลดรูป
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child; // โหลดเสร็จแล้ว แสดงรูป
              return Center(
                 child: CircularProgressIndicator(
                   value: loadingProgress.expectedTotalBytes != null
                       ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                       : null, // แสดง % การโหลด
                 ),
              );
            },
            // เพิ่ม errorBuilder เพื่อแสดง Icon กรณีโหลดรูปไม่ได้
            errorBuilder: (context, error, stackTrace) {
              print("Error loading pickup image: $error"); // แสดง error ใน console
              return const Center(child: Icon(Icons.broken_image, color: Colors.red, size: 50));
            },
          ),
       );
    } else {
       // ถ้าไม่มี URL หรือสถานะยังไม่ถึง ให้แสดงไอคอนกล้อง
       imageOrIconWidget = Icon(
          Icons.camera_alt,
          size: 60,
          // ทำให้เป็นสีเทาถ้ายังไม่ถึงสถานะ picked_up
          color: (status == 'pending' || status == 'accepted' || status == 'en_route')
                 ? Colors.grey.shade400
                 : primaryGreen,
       );
    }
    // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
            backgroundColor: primaryGreen,
            elevation: 0,
            // --- (แก้ไข) ทำให้ปุ่ม back กดได้ ---
            automaticallyImplyLeading: false, // ปิดปุ่ม back อัตโนมัติ
            leading: IconButton( // เพิ่มปุ่ม back เอง
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(), // สั่งให้ pop กลับไปหน้าก่อนหน้า
            ),
            // ----------------------------------
            flexibleSpace: Container( /* ... AppBar Content เหมือนเดิม ... */
               alignment: Alignment.bottomCenter,
               padding: const EdgeInsets.only(bottom: 12.0),
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                 decoration: BoxDecoration( color: const Color(0xFF75C2A4), borderRadius: BorderRadius.circular(8.0), ),
                 child: const Text('สถานะการส่งสินค้า', style: TextStyle( color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2.0, color: Colors.black26, offset: Offset(1.0, 1.0))],),),
               ),
            ),
         ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Tracking Steps ---
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: <Widget>[
                   TrackingStep(icon: Icons.access_time_filled, label: 'รอไรเดอร์รับสินค้า', isActive: step1Active, color: primaryGreen),
                   TrackingStep(icon: Icons.description, label: 'ได้รับออเดอร์แล้ว', isActive: step2Active, color: primaryGreen),
                   TrackingStep(icon: Icons.motorcycle, label: 'ไรเดอร์กำลังมา', isActive: step3Active, color: primaryGreen),
                   TrackingStep(icon: Icons.check_circle, label: 'จัดส่งสินค้าสำเร็จ', isActive: step4Active, color: primaryGreen),
                 ],
               ),
             ),

            // --- FlutterMap ---
            Padding(
               padding: const EdgeInsets.all(16.0),
               child: Container(
                 height: 250,
                 decoration: BoxDecoration( border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0), ),
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(8.0),
                   child: FlutterMap(
                     mapController: _mapController,
                     options: MapOptions( initialCenter: initialCameraPos, initialZoom: 14.0, ),
                     children: [
                       TileLayer( urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.ez_deliver_tracksure', ), // <-- ตรวจสอบชื่อ package อีกครั้ง
                       MarkerLayer(markers: _buildMapMarkers(order)),
                     ],
                   ),
                 ),
               ),
             ),

            // --- Status Text ---
            Padding(
               padding: const EdgeInsets.symmetric(vertical: 8.0),
               child: Center(child: Text(_getStatusText(status), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
             ),

            // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
            // --- Camera Icon or Pickup Image ---
            Center(
              child: Container(
                // เพิ่ม width/height ให้เหมาะกับการแสดงรูป
                width: 150,
                height: 150,
                margin: const EdgeInsets.symmetric(vertical: 20.0),
                // padding: const EdgeInsets.all(20.0), // เอา padding ออกเพื่อให้รูปเต็มกรอบ
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
                  // เพิ่ม border สีเทาอ่อนๆ รอบรูป/ไอคอน (optional)
                  border: Border.all(color: Colors.grey.shade200, width: 1.0)
                ),
                // ใช้ Widget ที่สร้างไว้ด้านบน (imageOrIconWidget)
                child: imageOrIconWidget,
              ),
            ),
            // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

            // --- Rider Info Header ---
            const Center(child: Text('ข้อมูลไรเดอร์ที่รับงาน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor))),

            // --- Rider Info Card ---
            Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Container(
                   padding: const EdgeInsets.all(16.0),
                   decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(10.0), border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))], ),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: <Widget>[
                       Column( crossAxisAlignment: CrossAxisAlignment.start, children: const <Widget>[ Text('ชื่อ : ', style: TextStyle(fontSize: 16)), SizedBox(height: 4), Text('เบอร์โทร : ', style: TextStyle(fontSize: 16)), SizedBox(height: 4), Text('ทะเบียน : ', style: TextStyle(fontSize: 16)), ],),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: <Widget>[
                             // ตรวจสอบชื่อ Field 'rider_name', 'rider_phone', 'license_plate' ใน collection 'riders' ด้วยนะครับ
                             Text(rider?['rider_name'] ?? (status == 'pending' ? 'กำลังค้นหา...' : 'N/A'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
                             Text(rider?['rider_phone'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
                             Text(rider?['license_plate'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

// --- TrackingStep Widget (เหมือนเดิม) ---
class TrackingStep extends StatelessWidget {
   final IconData icon;
   final String label;
   final bool isActive;
   final Color color;

   const TrackingStep({ required this.icon, required this.label, required this.isActive, required this.color, super.key, });

   @override
   Widget build(BuildContext context) {
     return Column(
       children: <Widget>[
         Container(
           padding: const EdgeInsets.all(8.0),
           decoration: BoxDecoration( shape: BoxShape.circle, color: isActive ? color : Colors.white, border: Border.all( color: isActive ? color : Colors.grey.shade400, width: 2.0, ), ),
           child: Icon( icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 24.0, ),
         ),
         const SizedBox(height: 4.0),
         SizedBox( width: 60, child: Text( label, textAlign: TextAlign.center, style: TextStyle( fontSize: 10, color: isActive ? Colors.black : Colors.grey.shade600, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, ), ), ),
       ],
     );
   }
}