// lib/pages/delivery_status_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ez_deliver_tracksure/api/api_service_image.dart';
import 'rider_bottom_bar.dart';
import 'rider_home.dart';
import 'package:ez_deliver_tracksure/pages/login.dart';

class RiderImageCache {
  static File? deliveryImage; // รูปรับของ
  static File? successImage;  // รูปส่งสำเร็จ
  static void clearCache() { deliveryImage = null; successImage = null; }
}

class Order {
  final String orderId;
  final DateTime? createdDate;
  final String customerName;
  final String destination;
  final String pickupLocation;
  final String productDescription;
  final String receiverName;
  final String receiverPhone;
  final String? productImageUrl;
  final String? pickupImageUrl;
  final String? deliveryImageUrl;
  final String status;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? pickupLatitude;
  final double? pickupLongitude;

  Order({
    required this.orderId,
    this.createdDate,
    required this.customerName,
    required this.destination,
    required this.pickupLocation,
    required this.productDescription,
    required this.receiverName,
    required this.receiverPhone,
    this.productImageUrl,
    this.pickupImageUrl,
    this.deliveryImageUrl,
    this.status = 'accepted',
    this.destinationLatitude,
    this.destinationLongitude,
    this.pickupLatitude,
    this.pickupLongitude,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
    return Order(
      orderId: doc.id,
      createdDate: createdAtTimestamp?.toDate(),
      customerName: data['customerName'] ?? 'ไม่ระบุลูกค้า',
      destination: data['destination'] ?? 'ไม่ระบุปลายทาง',
      pickupLocation: data['pickupLocation'] ?? 'ไม่ระบุต้นทาง',
      productDescription: data['productDescription'] ?? 'ไม่ระบุสินค้า',
      receiverName: data['receiverName'] ?? 'ไม่ระบุผู้รับ',
      receiverPhone: data['receiverPhone'] ?? 'ไม่ระบุเบอร์โทร',
      productImageUrl: data['productImageUrl'],
      pickupImageUrl: data['pickupImageUrl'],
      deliveryImageUrl: data['deliveryImageUrl'],
      status: (data['status'] ?? 'accepted').toString(),
      destinationLatitude: (data['destination_latitude'] as num?)?.toDouble(),
      destinationLongitude: (data['destination_longitude'] as num?)?.toDouble(),
      pickupLatitude: (data['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickup_longitude'] as num?)?.toDouble(),
    );
  }
}

class DeliveryStatusScreen extends StatefulWidget {
  final Order? acceptedOrder;
  const DeliveryStatusScreen({super.key, this.acceptedOrder});

  static const Color primaryColor = Color(0xFF00BFA5);
  static const Color secondaryColor = Color(0xFF004D40);

  @override
  State<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> {
  Order? _currentOrderFromStream;
  LatLng? _currentRiderLocation;
  bool _isUploadingPhoto = false;

  final ImageUploadService _imageUploadService = ImageUploadService();

  StreamSubscription<Position>? _positionStreamSubscription;
  final String? _riderId = FirebaseAuth.instance.currentUser?.uid;

  // >>> เพิ่มตัวแปร throttle track
  DateTime? _lastTrackWriteAt;
  LatLng? _lastTrackPoint;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStartLocationUpdates();
    _fetchInitialRiderLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialRiderLocation() async {
    if (_riderId == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('riders').doc(_riderId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = (data['current_latitude'] as num?)?.toDouble();
        final lng = (data['current_longitude'] as num?)?.toDouble();
        if (lat != null && lng != null && mounted) {
          setState(() { _currentRiderLocation = LatLng(lat, lng); });
        }
      }
    } catch (e) {
      debugPrint("Error fetching initial rider location: $e");
    }
  }

  Future<void> _checkPermissionAndStartLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('กรุณาเปิด GPS เพื่อให้สามารถติดตามตำแหน่งได้', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('การอนุญาตตำแหน่งถูกปฏิเสธ', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('กรุณาไปตั้งค่าเพื่ออนุญาตการเข้าถึงตำแหน่งแบบถาวร', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    if (_riderId == null) return;

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // อัปเดตเมื่อเคลื่อนที่เกิน 10 ม.
    );

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position position) {
        _updateRiderLocation(position);
        if (mounted) {
          setState(() {
            _currentRiderLocation = LatLng(position.latitude, position.longitude);
          });
        }
      },
      onError: (e) => debugPrint("Error getting location updates: $e"),
    );
  }

  // >>> ฟังก์ชันสำคัญ: อัปเดต riders + มิเรอร์ไป orders + เก็บ tracks
  Future<void> _updateRiderLocation(Position position) async {
    if (_riderId == null) return;

    // 1) โปรไฟล์ไรเดอร์ (riders/{uid})
    await FirebaseFirestore.instance.collection('riders').doc(_riderId).set({
      'current_latitude': position.latitude,
      'current_longitude': position.longitude,
      'last_updated': FieldValue.serverTimestamp(),
      'is_online': true,
    }, SetOptions(merge: true));

    // 2) มิเรอร์ไปที่ออเดอร์ (orders/{orderId}) – เพื่อให้ผู้ส่ง/ผู้รับ subscribe ง่าย
    final Order? o = _currentOrderFromStream;
    if (o != null) {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(o.orderId);
      await orderRef.set({
        'rider_last_location': GeoPoint(position.latitude, position.longitude),
        'rider_last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3) เก็บประวัติเส้นทางแบบ throttle
      final now = DateTime.now();
      final current = LatLng(position.latitude, position.longitude);
      final movedFar = _lastTrackPoint == null
          ? true
          : const Distance().as(LengthUnit.Meter, _lastTrackPoint!, current) >= 30.0;
      final longEnough = _lastTrackWriteAt == null
          ? true
          : now.difference(_lastTrackWriteAt!).inSeconds >= 15;

      if (movedFar || longEnough) {
        await orderRef.collection('tracks').add({
          'pos': GeoPoint(position.latitude, position.longitude),
          'ts': FieldValue.serverTimestamp(),
        });
        _lastTrackWriteAt = now;
        _lastTrackPoint = current;
      }
    }
  }

  Stream<Order?> _fetchOngoingOrderStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('orders')
        .where('riderId', isEqualTo: user.uid)
        .where('status', whereIn: ['accepted', 'pickedUp', 'inTransit', 'delivered'])
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? Order.fromFirestore(snap.docs.first) : null);
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ: $newStatus'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadImageAndUpdateFirestore(
      File imageFile, String orderId, String imageFieldName, String? newStatus) async {
    try {
      final String? downloadUrl = await _imageUploadService.uploadImageToCloudinary(imageFile);
      if (downloadUrl == null) { throw Exception("Cloudinary upload failed"); }

      final Map<String, dynamic> updateData = { imageFieldName: downloadUrl };
      if (newStatus != null) updateData['status'] = newStatus;

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพล้มเหลว: $e')));
      rethrow;
    }
  }

  Future<void> _pickImage(ImageSource source, int photoIndex) async {
    if (_isUploadingPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังอัปโหลดรูปภาพก่อนหน้า...')));
      return;
    }
    if (mounted) setState(() => _isUploadingPhoto = true);

    final Order? currentOrder = _currentOrderFromStream;
    if (currentOrder == null) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบงานที่กำลังจัดส่ง')));
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) { if (mounted) setState(() => _isUploadingPhoto = false); return; }

    final newImage = File(pickedFile.path);
    setState(() {
      if (photoIndex == 0) RiderImageCache.deliveryImage = newImage;
      if (photoIndex == 1) RiderImageCache.successImage = newImage;
    });

    try {
      if (photoIndex == 0) {
        await _uploadImageAndUpdateFirestore(newImage, currentOrder.orderId, 'pickupImageUrl', null);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('อัปโหลดรูปรับสินค้าสำเร็จ! สถานะ "กำลังไปส่งของ" จะอัปเดตใน 30 วินาที'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 4),
        ));

        Future.delayed(const Duration(seconds: 30), () async {
          try {
            if (_currentOrderFromStream?.orderId == currentOrder.orderId &&
                _currentOrderFromStream?.status != 'delivered' &&
                _currentOrderFromStream?.status != 'completed') {
              await _updateOrderStatus(currentOrder.orderId, 'inTransit');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('สถานะงานเปลี่ยนเป็น "กำลังไปส่งของ" แล้ว'),
                  backgroundColor: DeliveryStatusScreen.primaryColor,
                ));
              }
            }
          } catch (e) { debugPrint("Error in delayed status update: $e"); }
        });
      } else {
        await _uploadImageAndUpdateFirestore(newImage, currentOrder.orderId, 'deliveryImageUrl', null);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (photoIndex == 0) RiderImageCache.deliveryImage = null;
        if (photoIndex == 1) RiderImageCache.successImage = null;
      });
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _confirmDelivery(Order order) async {
    if (_isUploadingPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณารอการอัปโหลดรูปภาพให้เสร็จ')));
      return;
    }

    final hasAllPhotos = RiderImageCache.deliveryImage != null && RiderImageCache.successImage != null;
    final isReadyToComplete = hasAllPhotos && order.status == 'delivered';

    if (hasAllPhotos && order.status != 'delivered') {
      await _updateOrderStatus(order.orderId, 'delivered');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('รูปภาพครบ! กด "สิ้นสุดงานจัดส่ง" อีกครั้งเพื่อจบงาน'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    if (isReadyToComplete) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(order.orderId).update({'status': 'completed'});
        RiderImageCache.clearCache();
        _positionStreamSubscription?.cancel();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('สิ้นสุดงานจัดส่งสำเร็จ! ✅ ID: ${order.orderId}'),
          backgroundColor: const Color(0xFF4CAF50),
        ));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DeliveryHomePage()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสิ้นสุดการจัดส่ง'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณาอัปโหลดรูปภาพให้ครบก่อนยืนยัน'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showImageSourceActionSheet(BuildContext context, int photoIndex) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('ถ่ายรูปด้วยกล้อง'), onTap: () {
              Navigator.pop(context); _pickImage(ImageSource.camera, photoIndex);
            }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('เลือกจากแกลเลอรี่'), onTap: () {
              Navigator.pop(context); _pickImage(ImageSource.gallery, photoIndex);
            }),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Order? order) {
    if (order == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('รายละเอียดสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ListBody(children: [
            Text('คำอธิบาย: ${order.productDescription}'),
            const SizedBox(height: 10),
            if (order.productImageUrl != null && order.productImageUrl!.isNotEmpty)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('รูปภาพสินค้า (จากผู้ส่ง):'), const SizedBox(height: 5),
                Image.network(order.productImageUrl!, width: 150, height: 150, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('ไม่สามารถโหลดรูปภาพได้'),
                ),
              ])
            else const Text('ไม่มีรูปภาพสินค้าแนบมา'),
            const Divider(height: 20),
            if (order.pickupImageUrl != null && order.pickupImageUrl!.isNotEmpty)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('รูปภาพตอนรับสินค้า (ไรเดอร์):'), const SizedBox(height: 5),
                Image.network(order.pickupImageUrl!, width: 150, height: 150, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('ไม่สามารถโหลดรูปภาพได้'),
                ),
              ]),
            if (order.deliveryImageUrl != null && order.deliveryImageUrl!.isNotEmpty)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('รูปภาพตอนส่งสินค้า (ไรเดอร์):'), const SizedBox(height: 5),
                Image.network(order.deliveryImageUrl!, width: 150, height: 150, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('ไม่สามารถโหลดรูปภาพได้'),
                ),
              ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด', style: TextStyle(color: DeliveryStatusScreen.primaryColor))),
        ],
      ),
    );
  }

  Widget _buildTopGradientAndBanner(BuildContext context, Order? currentOrder) {
    const Color secondaryColor = Color(0xFF004D40);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [secondaryColor, Color(0xFF00897B)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: const Text('สถานะการจัดส่งสินค้า', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        _buildStepIndicators(currentOrder),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildStepIndicators(Order? currentOrder) {
    final String status = currentOrder?.status ?? 'pending';
    final isStep1Active = status != 'pending';
    final isStep2Active = ['pickedUp', 'inTransit', 'delivered', 'completed'].contains(status);
    final isStep3Active = ['delivered', 'completed'].contains(status);

    Widget dot(IconData icon, String label, bool active) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: active ? Colors.white : Colors.white.withOpacity(0.8), shape: BoxShape.circle),
          child: Icon(icon, color: active ? const Color(0xFF00BFA5) : Colors.grey, size: 24),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      ]);
    }

    Widget line(bool active) => Expanded(
      child: Padding(padding: const EdgeInsets.only(top: 15), child: Container(height: 3, color: active ? Colors.white : Colors.white.withOpacity(0.4))),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
        dot(Icons.description, 'ได้รับออเดอร์แล้ว', isStep1Active),
        line(isStep2Active || isStep3Active),
        dot(Icons.motorcycle, 'กำลังไปส่งของ', isStep2Active),
        line(isStep3Active),
        dot(Icons.check_circle, 'จัดส่งสำเร็จ', isStep3Active),
      ]),
    );
  }

  Widget _buildMapSection(Order order) {
    final LatLng dest = (order.destinationLatitude != null && order.destinationLongitude != null)
        ? LatLng(order.destinationLatitude!, order.destinationLongitude!)
        : const LatLng(16.2082, 103.2798);

    final LatLng pickup = (order.pickupLatitude != null && order.pickupLongitude != null)
        ? LatLng(order.pickupLatitude!, order.pickupLongitude!)
        : dest;

    final List<LatLng> focus = [dest, pickup];
    if (_currentRiderLocation != null) focus.add(_currentRiderLocation!);
    final bounds = LatLngBounds.fromPoints(focus);

    final markers = <Marker>[
      Marker(point: pickup, width: 80, height: 80, child: const Icon(Icons.location_on, color: Colors.green, size: 40)),
      Marker(point: dest, width: 80, height: 80, child: const Icon(Icons.location_pin, color: Colors.red, size: 40)),
    ];
    if (_currentRiderLocation != null) {
      markers.add(Marker(point: _currentRiderLocation!, width: 80, height: 80, child: const Icon(Icons.motorcycle, color: Colors.blue, size: 40)));
    }

    // เส้นตรง Rider -> เป้าหมาย
    LatLng? target;
    final status = order.status;
    if (['picked_up', 'intransit', 'inTransit', 'pickedUp'].contains(status)) {
      target = dest;
    } else {
      target = pickup;
    }

    final lines = <Polyline>[];
    double? distanceToTarget;
    if (_currentRiderLocation != null && target != null) {
      distanceToTarget = const Distance().as(LengthUnit.Meter, _currentRiderLocation!, target);
      lines.add(Polyline(points: [_currentRiderLocation!, target], strokeWidth: 4, color: Colors.blue));
    }

    String _humanizeDistance(double meters) => meters < 950
        ? '${meters.toStringAsFixed(0)} เมตร'
        : '${(meters / 1000).toStringAsFixed(1)} กม.';
    String _etaText(double meters, {double kmh = 30}) {
      final mins = (((meters / 1000) / kmh) * 60).round();
      return mins <= 1 ? '≈ 1 นาที' : '≈ $mins นาที';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.ez_deliver_tracksure'),
                  PolylineLayer(polylines: lines),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ),
        if (distanceToTarget != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'ระยะทางที่เหลือ: ${_humanizeDistance(distanceToTarget)} • ${_etaText(distanceToTarget)}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
      ]),
    );
  }

  Widget _buildPhotoSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildPhotoCard(label: 'ฉันรับสินค้าแล้ว', photoIndex: 0),
        _buildPhotoCard(label: 'ยืนยันการจัดส่งสินค้า', photoIndex: 1),
      ]),
    );
  }

  Widget _buildPhotoCard({required String label, required int photoIndex}) {
    final File? imageFile = photoIndex == 0 ? RiderImageCache.deliveryImage : RiderImageCache.successImage;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(children: [
          GestureDetector(
            onTap: () => _showImageSourceActionSheet(context, photoIndex),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                image: imageFile != null ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover) : null,
              ),
              child: imageFile == null
                  ? Center(
                      child: _isUploadingPhoto
                          ? const CircularProgressIndicator(color: DeliveryStatusScreen.primaryColor)
                          : Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                              child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF4CAF50)),
                            ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ]),
      ),
    );
  }

  Widget _buildConfirmationButton(Order order) {
    final isReadyToComplete = order.status == 'delivered' && RiderImageCache.deliveryImage != null && RiderImageCache.successImage != null;
    final String buttonText = isReadyToComplete ? 'สิ้นสุดงานจัดส่ง' : 'ยืนยันการจัดส่งสินค้า';
    final Color buttonColor = isReadyToComplete ? DeliveryStatusScreen.primaryColor : const Color(0xFF66BB6A);
    return ElevatedButton(
      onPressed: () => _confirmDelivery(order),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildProductInfoButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF00838F)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 3))],
        ),
        child: TextButton(
          onPressed: () => _showProductDetails(context, _currentOrderFromStream),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          child: const Text('ข้อมูลสินค้า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = DeliveryStatusScreen.primaryColor;
    const Color secondaryColor = DeliveryStatusScreen.secondaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [secondaryColor, primaryColor], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: StreamBuilder<Order?>(
        stream: _fetchOngoingOrderStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text("ข้อผิดพลาดในการโหลดงาน: ${snapshot.error}"));
          }

          final Order? currentOrder = snapshot.data ?? widget.acceptedOrder;
          _currentOrderFromStream = currentOrder;

          if (currentOrder == null) {
            if (RiderImageCache.deliveryImage != null || RiderImageCache.successImage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() { RiderImageCache.clearCache(); }); });
            }
            return const Center(
              child: Padding(padding: EdgeInsets.all(30), child: Text("ไม่พบงานที่กำลังจัดส่ง กรุณากลับไปหน้าหลักเพื่อรับงาน",
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey))),
            );
          }

          return SingleChildScrollView(
            child: Column(children: [
              _buildTopGradientAndBanner(context, currentOrder),
              _buildMapSection(currentOrder),
              _buildPhotoSections(),
              const SizedBox(height: 15),
              _buildConfirmationButton(currentOrder),
              const SizedBox(height: 20),
              _buildProductInfoButton(),
              const SizedBox(height: 40),
            ]),
          );
        },
      ),
      bottomNavigationBar: StatusBottomBar(
        currentIndex: 1,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DeliveryHomePage()), (route) => false);
          } else if (index == 2) {
            FirebaseAuth.instance.signOut();
            RiderImageCache.clearCache();
            _positionStreamSubscription?.cancel();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
          }
        },
      ),
    );
  }
}
