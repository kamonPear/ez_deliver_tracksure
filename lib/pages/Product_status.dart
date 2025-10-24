// lib/pages/product_status.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;

import 'package:ez_deliver_tracksure/pages/all.dart';      // HomeScreen
import 'package:ez_deliver_tracksure/pages/EditPro.dart';   // EditPro
import 'package:ez_deliver_tracksure/pages/order_list_page.dart'; // OrderListPage
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

  static const Color primaryGreen = Color(0xFF00A859);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;

  bool _didAutoCenterOnce = false;

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

  void _maybeCenterOn(latLng.LatLng pos) {
    if (!_didAutoCenterOnce) {
      _mapController.move(pos, 15);
      _didAutoCenterOnce = true;
      return;
    }
    final b = _mapController.camera.visibleBounds;
    if (!b.contains(pos)) {
      _mapController.move(pos, _mapController.camera.zoom);
    }
  }

  void _listenToOrder() {
  _orderSub = FirebaseFirestore.instance
      .collection('orders')
      .doc(widget.orderId)
      .snapshots()
      .listen((orderDoc) async {
    if (!orderDoc.exists) {
      setState(() { _isLoading = false; _errorMessage = 'ไม่พบข้อมูลออเดอร์'; });
      return;
    }

    final orderData = orderDoc.data() as Map<String, dynamic>;
    setState(() { _orderData = orderDoc; _isLoading = false; });

    // 1) ลองอ่านพิกัดจาก order เองก่อน
    final riderGeo = orderData['rider_last_location'];
    if (riderGeo is GeoPoint) {
      final pos = latLng.LatLng(riderGeo.latitude, riderGeo.longitude);
      setState(() => _currentRiderLocation = pos);
      _safeMove(pos);
    }

    // 2) subscribe ที่ riders/{riderId} เป็น fallback/real-time ยาว ๆ
    final String? riderId = orderData['riderId'] as String?;
    if (riderId != null && riderId.isNotEmpty) {
      await _riderSub?.cancel();
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
          final p = latLng.LatLng(lat, lng);
          setState(() => _currentRiderLocation = p);
          _safeMove(p);
        }
      });
    }
  }, onError: (e) {
    setState(() { _isLoading = false; _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}'; });
  });
}

void _safeMove(latLng.LatLng pos) {
  try { _mapController.move(pos, _mapController.camera.zoom); } catch (_) {}
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
        _maybeCenterOn(newPos);
      }
    });
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          break;
        case 2:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EditPro()));
          break;
      }
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderListPage()));
      }
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'สถานะรอไรเดอร์รับสินค้า';
      case 'accepted':
      case 'en_route': return 'ไรเดอร์รับออเดอร์แล้ว (กำลังเดินทางไปรับ)';
      case 'picked_up':
      case 'intransit':
      case 'intransit ': // กันเคสมี space
      case 'intransit\n':
      case 'intransit\r':
      case 'intransit\t':
      case 'intransit  ':
      case 'intransit  \n': return 'ไรเดอร์กำลังไปส่งของ';
      case 'completed':
      case 'delivered': return 'จัดส่งสินค้าสำเร็จ';
      default: return 'กำลังดำเนินการ (สถานะ: $status)';
    }
  }

  List<Marker> _buildMapMarkers(Map<String, dynamic> order, latLng.LatLng? rider) {
    final List<Marker> markers = [];
    final pickLat = (order['pickup_latitude'] as num?)?.toDouble();
    final pickLng = (order['pickup_longitude'] as num?)?.toDouble();
    if (pickLat != null && pickLng != null) {
      markers.add(Marker(
        width: 80, height: 80,
        point: latLng.LatLng(pickLat, pickLng),
        child: const Icon(Icons.store, color: Colors.green, size: 40),
      ));
    }

    final destLat = (order['destination_latitude'] as num?)?.toDouble();
    final destLng = (order['destination_longitude'] as num?)?.toDouble();
    if (destLat != null && destLng != null) {
      markers.add(Marker(
        width: 80, height: 80,
        point: latLng.LatLng(destLat, destLng),
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }

    if (rider != null) {
      markers.add(Marker(
        width: 80, height: 80,
        point: rider,
        child: const Icon(Icons.motorcycle, color: Colors.blue, size: 35),
      ));
    }
    return markers;
  }

  // helper: ระยะทาง/ETA
  double _distanceMeters(latLng.LatLng a, latLng.LatLng b) {
    final d = const latLng.Distance();
    return d.as(latLng.LengthUnit.Meter, a, b);
  }
  String _humanizeDistance(double meters) => meters < 950
      ? '${meters.toStringAsFixed(0)} เมตร'
      : '${(meters / 1000).toStringAsFixed(1)} กม.';
  String _etaText({required double meters, double kmh = 30}) {
    final mins = (((meters / 1000) / kmh) * 60).round();
    return mins <= 1 ? '≈ 1 นาที' : '≈ $mins นาที';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: primaryGreen, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomBar(currentIndex: _selectedIndex, onItemSelected: (_) {}),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('เกิดข้อผิดพลาด'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
        body: Center(child: Text(_errorMessage!)),
        bottomNavigationBar: BottomBar(currentIndex: _selectedIndex, onItemSelected: (_) {}),
      );
    }

    final order = _orderData!.data() as Map<String, dynamic>;
    final rider = _riderData?.data() as Map<String, dynamic>?;
    final String status = (order['status'] as String?)?.toLowerCase() ?? 'pending';

    final bool step1Active = status == 'pending';
    final bool step2Active = status == 'accepted' || status == 'en_route';
    final bool step3Active = status == 'picked_up' || status == 'intransit';
    final bool step4Active = status == 'completed' || status == 'delivered';

    double initialLat = 16.25;
    double initialLng = 103.23;
    final pLat = (order['pickup_latitude'] as num?)?.toDouble();
    final pLng = (order['pickup_longitude'] as num?)?.toDouble();
    if (pLat != null && pLng != null) {
      initialLat = pLat; initialLng = pLng;
    } else {
      final dLat = (order['destination_latitude'] as num?)?.toDouble();
      final dLng = (order['destination_longitude'] as num?)?.toDouble();
      if (dLat != null && dLng != null) { initialLat = dLat; initialLng = dLng; }
    }
    final latLng.LatLng initialCameraPos = latLng.LatLng(initialLat, initialLng);

    // กลุ่มแผนที่: เตรียมเส้นตรง rider -> target
    latLng.LatLng? target;
    if (status == 'picked_up' || status == 'intransit') {
      final destLat = (order['destination_latitude'] as num?)?.toDouble();
      final destLng = (order['destination_longitude'] as num?)?.toDouble();
      if (destLat != null && destLng != null) target = latLng.LatLng(destLat, destLng);
    } else {
      if (pLat != null && pLng != null) target = latLng.LatLng(pLat, pLng);
    }

    final riderPos = _currentRiderLocation;
    final List<Polyline> lines = [];
    double? distanceToTarget;
    if (riderPos != null && target != null) {
      distanceToTarget = _distanceMeters(riderPos, target);
      lines.add(Polyline(points: [riderPos, target], strokeWidth: 4, color: Colors.blue));
    }

    // รูป/ไอคอน
    Widget imageOrIconWidget;
    if (_pickupImageUrl != null && (status == 'picked_up' || status == 'completed' || status == 'delivered' || status == 'intransit')) {
      imageOrIconWidget = ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(_pickupImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
          loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.red, size: 50)),
        ),
      );
    } else {
      imageOrIconWidget = Icon(
        Icons.camera_alt, size: 60,
        color: (status == 'pending' || status == 'accepted' || status == 'en_route') ? Colors.grey.shade400 : primaryGreen,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: primaryGreen, elevation: 0, automaticallyImplyLeading: false,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
          flexibleSpace: Container(
            alignment: Alignment.bottomCenter, padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF75C2A4), borderRadius: BorderRadius.circular(8)),
              child: const Text('สถานะการส่งสินค้า', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1,1))])),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              TrackingStep(icon: Icons.access_time_filled, label: 'รอไรเดอร์รับสินค้า', isActive: step1Active, color: primaryGreen),
              TrackingStep(icon: Icons.description, label: 'ได้รับออเดอร์แล้ว', isActive: step2Active, color: primaryGreen),
              TrackingStep(icon: Icons.motorcycle, label: 'กำลังไปส่งของ', isActive: step3Active, color: primaryGreen),
              TrackingStep(icon: Icons.check_circle, label: 'จัดส่งสินค้าสำเร็จ', isActive: step4Active, color: primaryGreen),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: initialCameraPos, initialZoom: 14),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.ez_deliver_tracksure'),
                    PolylineLayer(polylines: lines),
                    MarkerLayer(markers: _buildMapMarkers(order, riderPos)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text(_getStatusText(status), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
          ),
          Center(
            child: Container(
              width: 150, height: 150, margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: imageOrIconWidget,
            ),
          ),
          if (distanceToTarget != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'ระยะทางที่เหลือ: ${_humanizeDistance(distanceToTarget)} • ${_etaText(meters: distanceToTarget)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ),
          const Center(child: Text('ข้อมูลไรเดอร์ที่รับงาน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('ชื่อ : ', style: TextStyle(fontSize: 16)), SizedBox(height: 4),
                  Text('เบอร์โทร : ', style: TextStyle(fontSize: 16)), SizedBox(height: 4),
                  Text('ทะเบียน : ', style: TextStyle(fontSize: 16)),
                ]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rider?['rider_name'] ?? (status == 'pending' ? 'กำลังค้นหา...' : 'N/A'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(rider?['rider_phone'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(rider?['license_plate'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      bottomNavigationBar: BottomBar(currentIndex: _selectedIndex, onItemSelected: _onItemTapped),
    );
  }
}

class TrackingStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  const TrackingStep({ required this.icon, required this.label, required this.isActive, required this.color, super.key });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? color : Colors.white, border: Border.all(color: isActive ? color : Colors.grey.shade400, width: 2)),
        child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 24),
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: 60,
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: isActive ? Colors.black : Colors.grey.shade600, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    ]);
  }
}
