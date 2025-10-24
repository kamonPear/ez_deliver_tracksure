import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
// import 'package:latlong2/latlong.dart'; // import ตัวนี้ซ้ำซ้อน
import 'package:firebase_auth/firebase_auth.dart'; // เพิ่มการ import ที่อาจจำเป็น

// Dependencies ที่ต้อง import เพิ่มเติม (คุณต้องมีไฟล์เหล่านี้ในโปรเจกต์)
import 'bottom_bar.dart'; // ดึง BottomBar ที่คุณต้องการมาใช้
import 'all.dart'; // สำหรับ HomeScreen
import 'EditPro.dart'; // สำหรับ EditPro
// import 'order_list_page.dart'; // ถ้ามี OrderListPage ต้อง un-comment
// -----------------------

// -----------------------------------------------------------------------------
// MARK: - Constants
// -----------------------------------------------------------------------------

// กำหนดสีที่ใช้จากภาพตัวอย่าง
const Color primaryGreen = Color(0xFF00A859);
const Color backgroundColor = Colors.white;
const Color textColor = Colors.black;

// -----------------------------------------------------------------------------
// MARK: - Screen: ProductStatus
// -----------------------------------------------------------------------------

class ProductStatus extends StatefulWidget {
  final String orderId;

  const ProductStatus({super.key, required this.orderId});

  @override
  State<ProductStatus> createState() => _ProductStatusState();
}

class _ProductStatusState extends State<ProductStatus> {
  // ตั้งค่าให้เป็น Index 1 เพื่อให้รายการพัสดุเป็นสีเขียวใน BottomBar
  final int _selectedIndex = 1; 
  bool _isLoading = true;
  String? _errorMessage;
  DocumentSnapshot? _orderData;
  DocumentSnapshot? _riderData;

  final MapController _mapController = MapController();
  StreamSubscription? _orderSub;
  StreamSubscription? _riderSub;
  latLng.LatLng? _currentRiderLocation;

  String? _pickupImageUrl; 

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

  // ----------------------------------------------------------
  // MARK: - Data Streaming Logic
  // ----------------------------------------------------------

  Future<void> _listenToOrder() async {
    if (!mounted) return;
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

      // ดึง URL รูปภาพ
      // Note: ในโค้ดตัวอย่างก่อนหน้านี้ ใช้ 'productImageUrl' แต่ในโค้ด ProductStatus ใช้ 'pickupImageUrl'
      // ผมจะใช้ 'pickupImageUrl' ตามโค้ด ProductStatus นี้
      final String? fetchedPickupImageUrl = orderData['productImageUrl'] as String? 
          ?? orderData['pickupImageUrl'] as String?;


      if (mounted) {
        setState(() {
          _orderData = orderDoc;
          _isLoading = false; 

          // อัปเดต URL รูปภาพใน State
          if (fetchedPickupImageUrl != null && fetchedPickupImageUrl.isNotEmpty) {
            _pickupImageUrl = fetchedPickupImageUrl;
          } else {
            _pickupImageUrl = null; // ถ้าไม่มี ให้เป็น null
          }
        });
       }

      final String? riderId = orderData['riderId'] as String?;

      // ถ้ามี riderId และยังไม่เคยโหลดข้อมูลไรเดอร์ หรือ riderId เปลี่ยนไป
      if (riderId != null && riderId.isNotEmpty && (_riderData?.id != riderId)) {
        await _riderSub?.cancel();
        final riderDoc = await FirebaseFirestore.instance.collection('riders').doc(riderId).get();
        if (riderDoc.exists && mounted) setState(() { _riderData = riderDoc; });
        _listenToRiderLocation(riderId);
      } else if (riderId == null || riderId.isEmpty) {
        // ถ้าไม่มี Rider ให้ยกเลิกการติดตามตำแหน่ง
        await _riderSub?.cancel();
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

      final double? lat = (data['current_latitude'] as num?)?.toDouble();
      final double? lng = (data['current_longitude'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        final newPos = latLng.LatLng(lat, lng);
        if (mounted) setState(() { _currentRiderLocation = newPos; });
        try {
          // ซูมไปยังตำแหน่งไรเดอร์ใหม่
          _mapController.move(newPos, _mapController.camera.zoom);
        } catch (e) {
          debugPrint("MapController not ready or error moving map: $e");
        }
      }
    });
  }

  // ----------------------------------------------------------
  // MARK: - UI Logic / Status / Navigation
  // ----------------------------------------------------------

  // Logic การนำทาง (เหมือนเดิม)
  void _onItemTapped(int index) {
    if (index != _selectedIndex) { 
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EditPro()),
          );
          break;
      }
    } else {
      // เมื่อกดซ้ำที่พัสดุ (Index 1) ให้กลับไปหน้าก่อนหน้า
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Fallback: หากมาจาก Notification หรือ Deep Link
        // อาจจะต้องนำทางไปยัง OrderListPage หรือ HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }


  // ปรับ _getStatusText ให้สอดคล้องกับ 4 ขั้นตอน
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'สถานะ: รอไรเดอร์รับสินค้า';
      case 'accepted':
      case 'en_route': // ไรเดอร์กำลังไปรับสินค้า
        return 'สถานะ: ไรเดอร์รับออเดอร์แล้ว (กำลังเดินทางไปรับ)';
      case 'picked_up': // ไรเดอร์รับสินค้าแล้ว (กำลังไปส่ง)
      case 'intransit':
        return 'สถานะ: ไรเดอร์กำลังไปส่งของ'; 
      case 'completed':
      case 'delivered':
        return 'สถานะ: จัดส่งสินค้าสำเร็จ';
      default:
        return 'สถานะ: กำลังดำเนินการ ($status)';
    }
  }

  List<Marker> _buildMapMarkers(Map<String, dynamic> order) {
    final List<Marker> markers = [];
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

  // ----------------------------------------------------------
  // MARK: - Build Method
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(backgroundColor: primaryGreen, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
          body: const Center(child: CircularProgressIndicator()),
          bottomNavigationBar: BottomBar( currentIndex: _selectedIndex, onItemSelected: _onItemTapped, ),
        );
    }

    if (_errorMessage != null || _orderData == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('เกิดข้อผิดพลาด'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
          body: Center(child: Text(_errorMessage ?? 'ไม่พบข้อมูลออเดอร์')),
          bottomNavigationBar: BottomBar( currentIndex: _selectedIndex, onItemSelected: _onItemTapped, ),
        );
    }

    final order = _orderData!.data() as Map<String, dynamic>;
    final rider = _riderData?.data() as Map<String, dynamic>?;
    final String status = (order['status'] as String?)?.toLowerCase() ?? 'pending';

    // Logic สถานะ 4 ขั้นตอน
    final bool step1Active = status == 'pending'; // รอไรเดอร์รับสินค้า (Pending)
    final bool step2Active = status == 'accepted' || status == 'en_route' || status == 'picked_up' || status == 'intransit' || status == 'completed' || status == 'delivered'; // ไรเดอร์รับออเดอร์แล้ว (Accepted, En_route, และสถานะถัดไป)
    final bool step3Active = status == 'picked_up' || status == 'intransit' || status == 'completed' || status == 'delivered'; // ไรเดอร์กำลังไปส่งของ (Picked_up, InTransit, และสถานะถัดไป)
    final bool step4Active = status == 'completed' || status == 'delivered'; // จัดส่งสินค้าสำเร็จ (Completed, Delivered)

    // กำหนดตำแหน่งเริ่มต้นแผนที่
    double initialLat = 16.25; 
    double initialLng = 103.23;
    final pLat = (order['pickup_latitude'] as num?)?.toDouble();
    final pLng = (order['pickup_longitude'] as num?)?.toDouble();
    if (pLat != null && pLng != null) {
      initialLat = pLat;
      initialLng = pLng;
    } else {
      final dLat = (order['destination_latitude'] as num?)?.toDouble();
      final dLng = (order['destination_longitude'] as num?)?.toDouble();
      if(dLat != null && dLng != null) {
        initialLat = dLat;
        initialLng = dLng;
      }
    }
    final latLng.LatLng initialCameraPos = latLng.LatLng(initialLat, initialLng);

    // Widget แสดงรูปภาพ/ไอคอนกล้อง (ปรับปรุงให้ใช้ Image.network พร้อม Error Handling)
    Widget imageOrIconWidget;
    // รูปภาพจะแสดงเมื่อพัสดุถูกรับแล้ว (สถานะ picked_up หรือสูงกว่า)
    final bool showPickupImage = _pickupImageUrl != null && (step3Active || step4Active);

    if (showPickupImage) {
      imageOrIconWidget = ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Image.network(
          _pickupImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Error loading pickup image: $error. URL: $_pickupImageUrl");
            return const Center(child: Icon(Icons.broken_image, color: Colors.red, size: 50));
          },
        ),
      );
    } else {
      imageOrIconWidget = Icon(
        Icons.camera_alt,
        size: 60,
        color: (step1Active || step2Active)
            ? Colors.grey.shade400 // สีเทาอ่อนถ้ารอรับสินค้า
            : primaryGreen, // สีเขียวถ้าสถานะถัดไป
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
            backgroundColor: primaryGreen,
            elevation: 0,
            automaticallyImplyLeading: false, 
            leading: IconButton( 
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: Container(
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
                     TrackingStep(icon: Icons.motorcycle, label: 'กำลังไปส่งของ', isActive: step3Active, color: primaryGreen),
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
                      TileLayer( urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.ez_deliver_tracksure', ),
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

            // --- Camera Icon or Pickup Image ---
            Center(
              child: Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.symmetric(vertical: 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
                  border: Border.all(color: Colors.grey.shade200, width: 1.0)
                ),
                child: imageOrIconWidget,
              ),
            ),
            
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

// -----------------------------------------------------------------------------
// MARK: - Widget: TrackingStep
// -----------------------------------------------------------------------------

/// Widget สำหรับแสดงสถานะขั้นตอนการส่ง
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