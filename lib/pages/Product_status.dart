import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;

// --- Import หน้าอื่นๆ ---
import 'package:ez_deliver_tracksure/pages/all.dart'; // HomeScreen
import 'package:ez_deliver_tracksure/pages/EditPro.dart'; // EditPro
import 'package:ez_deliver_tracksure/pages/order_list_page.dart'; // OrderListPage
// -----------------------

import 'package:ez_deliver_tracksure/pages/bottom_bar.dart'; // BottomBar

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

  String? _pickupImageUrl;
  String? _deliveryImageUrl;

  static const Color primaryGreen = Color(0xFF00A859);
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
        .listen(
          (orderDoc) async {
            if (!orderDoc.exists) {
              if (mounted)
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'ไม่พบข้อมูลออเดอร์';
                });
              return;
            }

            final orderData = orderDoc.data() as Map<String, dynamic>;

            final String? fetchedPickupImageUrl =
                orderData['pickupImageUrl'] as String?;
            final String? fetchedDeliveryImageUrl =
                orderData['deliveryImageUrl'] as String?;

            if (mounted) {
              setState(() {
                _orderData = orderDoc;
                _isLoading = false;

                _pickupImageUrl =
                    (fetchedPickupImageUrl != null &&
                        fetchedPickupImageUrl.isNotEmpty)
                    ? fetchedPickupImageUrl
                    : null;
                _deliveryImageUrl =
                    (fetchedDeliveryImageUrl != null &&
                        fetchedDeliveryImageUrl.isNotEmpty)
                    ? fetchedDeliveryImageUrl
                    : null;
              });
            }

            final String? riderId = orderData['riderId'] as String?;

            if (riderId != null &&
                riderId.isNotEmpty &&
                (_riderData?.id != riderId)) {
              await _riderSub?.cancel();
              final riderDoc = await FirebaseFirestore.instance
                  .collection('riders')
                  .doc(riderId)
                  .get();
              if (riderDoc.exists && mounted)
                setState(() {
                  _riderData = riderDoc;
                });
              _listenToRiderLocation(riderId);
            }
          },
          onError: (e) {
            if (mounted)
              setState(() {
                _isLoading = false;
                _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
              });
          },
        );
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
            if (mounted)
              setState(() {
                _currentRiderLocation = newPos;
              });
            try {
              _mapController.move(newPos, _mapController.camera.zoom);
            } catch (e) {
              print("MapController not ready or error moving map: $e");
            }
          }
        });
  }

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
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderListPage()),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'สถานะรอไรเดอร์รับสินค้า';
      case 'accepted':
      case 'en_route':
        return 'ไรเดอร์รับออเดอร์แล้ว (กำลังเดินทางไปรับ)';
      case 'picked_up':
      case 'intransit':
        return 'ไรเดอร์กำลังไปส่งของ';
      case 'completed':
      case 'delivered':
        return 'จัดส่งสินค้าสำเร็จ';
      default:
        return 'กำลังดำเนินการ (สถานะ: $status)';
    }
  }

  List<Marker> _buildMapMarkers(Map<String, dynamic> order) {
    final List<Marker> markers = [];
    final pickLat = (order['pickup_latitude'] as num?)?.toDouble();
    final pickLng = (order['pickup_longitude'] as num?)?.toDouble();
    if (pickLat != null && pickLng != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: latLng.LatLng(pickLat, pickLng),
          child: const Icon(Icons.store, color: Colors.green, size: 40),
        ),
      );
    }

    final destLat = (order['destination_latitude'] as num?)?.toDouble();
    final destLng = (order['destination_longitude'] as num?)?.toDouble();
    if (destLat != null && destLng != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: latLng.LatLng(destLat, destLng),
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

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
        appBar: AppBar(
          backgroundColor: primaryGreen,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomBar(
          currentIndex: _selectedIndex,
          onItemSelected: (_) {},
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('เกิดข้อผิดพลาด'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(child: Text(_errorMessage!)),
        bottomNavigationBar: BottomBar(
          currentIndex: _selectedIndex,
          onItemSelected: (_) {},
        ),
      );
    }

    final order = _orderData!.data() as Map<String, dynamic>;
    final rider = _riderData?.data() as Map<String, dynamic>?;
    final String status =
        (order['status'] as String?)?.toLowerCase() ?? 'pending';

    final bool isCompleted = status == 'completed' || status == 'delivered';
    final bool isPickedUpOrLater =
        isCompleted || status == 'picked_up' || status == 'intransit';
    final bool isAcceptedOrLater =
        isPickedUpOrLater || status == 'accepted' || status == 'en_route';
    final bool isPendingOrLater = isAcceptedOrLater || status == 'pending';

    final bool step1Active = isPendingOrLater;
    final bool step2Active = isAcceptedOrLater;
    final bool step3Active = isPickedUpOrLater;
    final bool step4Active = isCompleted;

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
      if (dLat != null && dLng != null) {
        initialLat = dLat;
        initialLng = dLng;
      }
    }
    final latLng.LatLng initialCameraPos = latLng.LatLng(
      initialLat,
      initialLng,
    );

    // 🚀 [ โค้ดที่แก้ไข: สร้าง Widget สำหรับแสดงรูปภาพทั้งสอง โดยใช้ Row ] 🚀
    List<Widget> imageItems = [];

    // รูปภาพตอนรับสินค้า (Pickup Image)
    if (_pickupImageUrl != null) {
      imageItems.add(
        _buildImageCard(
          imageUrl: _pickupImageUrl!,
          title: 'รูปตอนรับสินค้า', // ปรับข้อความให้สั้นลง
          isActive: isPickedUpOrLater,
          color: primaryGreen,
        ),
      );
    } else if (isPickedUpOrLater) {
      // แสดง placeholder เมื่อถึงเวลาควรมีรูป แต่ยังไม่มี
      imageItems.add(
        _buildImageCard(
          icon: Icons.camera_alt,
          title: 'ยังไม่มีรูปตอนรับสินค้า',
          isActive: true,
          color: primaryGreen,
        ),
      );
    }

    // รูปภาพตอนจัดส่งสำเร็จ (Delivery Image)
    if (_deliveryImageUrl != null) {
      // ไม่ต้องเพิ่ม SizedBox(height) เพราะจะอยู่ข้างกัน
      imageItems.add(
        _buildImageCard(
          imageUrl: _deliveryImageUrl!,
          title: 'รูปส่งสำเร็จ', // ปรับข้อความให้สั้นลง
          isActive: isCompleted,
          color: primaryGreen,
        ),
      );
    } else if (isCompleted) {
      imageItems.add(
        _buildImageCard(
          icon: Icons.camera_alt,
          title: 'ยังไม่มีรูปส่งสำเร็จ',
          isActive: true,
          color: primaryGreen,
        ),
      );
    }

    // กำหนด Widget ที่จะแสดงรูปภาพ (หรือ placeholder)
    Widget imageSection;
    if (imageItems.isNotEmpty) {
      imageSection = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceEvenly, // จัดให้อยู่ตรงกลางและมีช่องไฟเท่ากัน
          crossAxisAlignment: CrossAxisAlignment.start,
          children: imageItems,
        ),
      );
    } else {
      // กรณีที่ยังไม่มีรูปภาพใดๆ เลย และสถานะยังไม่ถึงจุดที่ต้องแสดงรูป
      imageSection = Center(
        child: Container(
          width: 150,
          height: 150,
          margin: const EdgeInsets.symmetric(vertical: 20.0),
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
            border: Border.all(color: Colors.grey.shade200, width: 1.0),
          ),
          child: Icon(Icons.camera_alt, size: 60, color: Colors.grey.shade400),
        ),
      );
    }
    // -------------------------------------------------------------

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
            // --- Tracking Steps ---
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  TrackingStepWithLine(
                    icon: Icons.access_time_filled,
                    label: 'รอไรเดอร์รับสินค้า',
                    isActive: step1Active,
                    color: primaryGreen,
                    hasLine: true,
                    lineCompleted: step2Active,
                  ),

                  TrackingStepWithLine(
                    icon: Icons.description,
                    label: 'ได้รับออเดอร์แล้ว',
                    isActive: step2Active,
                    color: primaryGreen,
                    hasLine: true,
                    lineCompleted: step3Active,
                  ),

                  TrackingStepWithLine(
                    icon: Icons.motorcycle,
                    label: 'กำลังไปส่งของ',
                    isActive: step3Active,
                    color: primaryGreen,
                    hasLine: true,
                    lineCompleted: step4Active,
                  ),

                  // ไอคอนสุดท้าย ไม่ต้องมีเส้นต่อไป
                  TrackingStep(
                    icon: Icons.check_circle,
                    label: 'จัดส่งสินค้าสำเร็จ',
                    isActive: step4Active,
                    color: primaryGreen,
                  ),
                ],
              ),
            ),

            // --- FlutterMap ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 250,
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
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.ez_deliver_tracksure',
                      ),
                      MarkerLayer(markers: _buildMapMarkers(order)),
                    ],
                  ),
                ),
              ),
            ),

            // --- Status Text ---
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

            // 🚀 [ โค้ดที่แก้ไข: แสดงรูปภาพทั้งสอง ] 🚀
            imageSection, // ใช้ Widget ที่สร้างไว้ด้านบน
            // -----------------------------------------------------------------

            // --- Rider Info Header ---
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

            // --- Rider Info Card ---
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

  // 🚀 [ โค้ดที่แก้ไข: Widget Helper สำหรับสร้าง Image Card (ปรับขนาด) ] 🚀
  Widget _buildImageCard({
    String? imageUrl,
    IconData? icon,
    required String title,
    required bool isActive,
    required Color color,
  }) {
    return Expanded(
      // ใช้ Expanded เพื่อให้แต่ละรูปภาพขยายเท่ากัน
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14, // ปรับขนาดฟอนต์ให้เล็กลง
              fontWeight: FontWeight.bold,
              color: isActive ? textColor : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            width: 120, // ปรับขนาดความกว้าง
            height: 120, // ปรับขนาดความสูง
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
              border: Border.all(
                color: isActive ? color : Colors.grey.shade200,
                width: 1.0,
              ),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading image: $error");
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.red,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Icon(
                      icon ?? Icons.camera_alt,
                      size: 50, // ปรับขนาดไอคอน
                      color: isActive ? color : Colors.grey.shade400,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
}

// --- TrackingStep Widget (ส่วนเดิม) ---
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

// 🚀 [ TrackingStepWithLine Widget ] 🚀
class TrackingStepWithLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final bool hasLine;
  final bool lineCompleted;

  const TrackingStepWithLine({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    this.hasLine = false,
    this.lineCompleted = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. ตัว Icon สถานะ
          TrackingStep(
            icon: icon,
            label: label,
            isActive: isActive,
            color: color,
          ),
          // 2. เส้นเชื่อมต่อ (ถ้ามี)
          if (hasLine)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Divider(
                  color: lineCompleted ? color : Colors.grey.shade400,
                  thickness: 3.0,
                  height: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
