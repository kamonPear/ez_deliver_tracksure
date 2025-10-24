import 'dart:io';
// [NEW] Import สำหรับ Timer และ StreamSubscription
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// [NEW] Import สำหรับ Flutter Map และพิกัด
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// [NEW] Import สำหรับการติดตามตำแหน่ง
import 'package:geolocator/geolocator.dart';

// [NEW] เพิ่ม Firebase Imports ที่จำเป็น
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// [NEW] 1. Import Service สำหรับอัปโหลดรูปภาพ
// (สมมติว่า Path นี้ถูกต้องตามที่คุณระบุ)
import '../api/api_service_image.dart';

// Local Imports
import 'rider_bottom_bar.dart';
import 'rider_home.dart';
import 'package:ez_deliver_tracksure/pages/login.dart';

// **********************************************
// 1. CLASS สำหรับเก็บสถานะรูปภาพชั่วคราว (Cache)
// **********************************************
class RiderImageCache {
  // ทำให้เป็น static เพื่อให้เข้าถึงได้จากทุกที่และไม่ถูกทำลายเมื่อ Widget Rebuild
  static File? deliveryImage;
  static File? successImage;

  // ฟังก์ชันสำหรับล้างค่าเมื่อจัดส่งสำเร็จ
  static void clearCache() {
    deliveryImage = null;
    successImage = null;
  }
}

// ----------------------
// Order Model (แก้ไข)
// ----------------------
class Order {
  final String orderId;
  final DateTime? createdDate;
  final String customerName;
  final String destination;
  final String pickupLocation;
  final String productDescription;
  final String receiverName;
  final String receiverPhone;
  final String? productImageUrl; // รูปสินค้า (จาก Admin)
  final String status;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? riderLatitude;
  final double? riderLongitude;

  // [NEW] เพิ่ม Field สำหรับเก็บ URL รูปที่ไรเดอร์อัปโหลด
  final String? pickupImageUrl; // รูปตอนรับสินค้า
  final String? deliveryImageUrl; // รูปตอนส่งสำเร็จ

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
    this.status = 'accepted',
    this.destinationLatitude,
    this.destinationLongitude,
    this.pickupLatitude,
    this.pickupLongitude,
    this.riderLatitude,
    this.riderLongitude,
    // [NEW] เพิ่มใน Constructor
    this.pickupImageUrl,
    this.deliveryImageUrl,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Order data is null for document ${doc.id}");
    }

    final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;

    // [FIXED] 1. แก้ไขการดึงรูปภาพสินค้า (เหมือนไฟล์ rider_home.dart)
    final List<dynamic>? imageUrls =
        data['productImagesUrlList'] as List<dynamic>?;

    return Order(
      orderId: doc.id,
      createdDate: createdAtTimestamp?.toDate(),
      customerName: data['customerName'] ?? 'ไม่ระบุลูกค้า',
      destination: data['destination'] ?? 'ไม่ระบุปลายทาง',
      pickupLocation: data['pickupLocation'] ?? 'ไม่ระบุต้นทาง',
      productDescription: data['productDescription'] ?? 'ไม่ระบุสินค้า',
      receiverName: data['receiverName'] ?? 'ไม่ระบุผู้รับ',
      receiverPhone: data['receiverPhone'] ?? 'ไม่ระบุเบอร์โทร',

      // [FIXED] 2. ดึง URL รูปแรกจาก List
      productImageUrl: (imageUrls != null && imageUrls.isNotEmpty)
          ? imageUrls[0] as String?
          : null,

      status: data['status'] ?? 'accepted',
      destinationLatitude: (data['destination_latitude'] as num?)?.toDouble(),
      destinationLongitude: (data['destination_longitude'] as num?)?.toDouble(),
      pickupLatitude: (data['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickup_longitude'] as num?)?.toDouble(),
      riderLatitude: (data['rider_lat'] as num?)?.toDouble(),
      riderLongitude: (data['rider_long'] as num?)?.toDouble(),

      // [NEW] 3. ดึง URL รูปที่ไรเดอร์อัปโหลด (ถ้ามี)
      pickupImageUrl: data['pickupImageUrl'] as String?,
      deliveryImageUrl: data['deliveryImageUrl'] as String?,
    );
  }
}

// ----------------------
// 2. DeliveryStatusScreen
// ----------------------
class DeliveryStatusScreen extends StatefulWidget {
  final Order? acceptedOrder; // ทำให้เป็น optional

  const DeliveryStatusScreen({super.key, this.acceptedOrder});

  static const Color primaryColor = Color(0xFF00BFA5);
  static const Color secondaryColor = Color(0xFF004D40);

  @override
  State<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> {
  Order? _currentOrderFromStream;
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentRiderLocation;
  Timer? _firestoreUpdateTimer;
  bool _isLocationServiceEnabled = false;

  final MapController _mapController = MapController();
  bool _mapInitialized = false;

  // [NEW] 2. สร้าง Instance ของ Service และ State การอัปโหลด
  final ImageUploadService _imageUploadService = ImageUploadService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // [FIXED] เคลียร์ Cache รูปภาพเก่าทันทีที่หน้านี้ถูกโหลด
    RiderImageCache.clearCache();
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _mapController.dispose();
    super.dispose();
  }

  // [NEW] หยุดการติดตามตำแหน่งและ Timer
  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _firestoreUpdateTimer?.cancel();
    _positionStreamSubscription = null;
    _firestoreUpdateTimer = null;
    _isLocationServiceEnabled = false; // รีเซ็ตสถานะ
    if (mounted) {
      setState(() {
        _currentRiderLocation = null;
      });
    }
  }

  // [NEW] ฟังก์ชันเริ่มต้นกระบวนการติดตามตำแหน่ง
  Future<void> _initializeLocationTracking() async {
    // ป้องกันการรันซ้ำ
    if (_isLocationServiceEnabled) return;

    // 1. ตรวจสอบสิทธิ์และบริการ
    bool hasPermission = await _checkAndRequestLocationPermissions();
    if (!hasPermission) {
      print("Location permission denied.");
      // อาจแสดง Dialog แจ้งผู้ใช้
      return; // หยุดทำงานถ้าไม่ได้รับสิทธิ์
    }

    if (mounted) {
      setState(() {
        _isLocationServiceEnabled = true;
      });
    }

    // 2. เริ่มรับตำแหน่งแบบ Real-time
    _startLocationStream();

    // 3. เริ่ม Timer อัปเดต Firestore (10 วินาที)
    _startFirestoreUpdateTimer();
  }

  // [NEW] ฟังก์ชันตรวจสอบและขอสิทธิ์การเข้าถึงตำแหน่ง
  Future<bool> _checkAndRequestLocationPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่า Location Service เปิดอยู่หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      // TODO: อาจจะแสดง dialog แจ้งเตือนผู้ใช้ให้เปิด GPS
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      // TODO: แสดง dialog ให้ผู้ใช้ไปเปิดใน Settings
      return false;
    }

    // ถ้าผ่านหมด แสดงว่าได้รับสิทธิ์
    return true;
  }

  // [NEW] ฟังก์ชันเริ่มรับตำแหน่งจาก Geolocator
  void _startLocationStream() {
    if (!_isLocationServiceEnabled) return;

    // ตั้งค่าความแม่นยำ
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // อัปเดตทุก 10 เมตร
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (mounted) {
          // อัปเดต State เพื่อให้ Map แสดง Marker ใหม่
          setState(() {
            _currentRiderLocation = LatLng(
              position.latitude,
              position.longitude,
            );
          });
        }
      },
      onError: (e) {
        print("Error getting location stream: $e");
      },
    );
  }

  // [NEW] ฟังก์ชันเริ่ม Timer สำหรับอัปเดต Firestore (ทุก 10 วินาที)
  void _startFirestoreUpdateTimer() {
    // ยกเลิก Timer เก่า (ถ้ามี)
    _firestoreUpdateTimer?.cancel();

    _firestoreUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) {
      // ตรวจสอบว่ามี Order และมีตำแหน่งปัจจุบันหรือไม่
      if (_currentOrderFromStream != null && _currentRiderLocation != null) {
        _updateRiderLocationInFirestore(
          _currentOrderFromStream!.orderId,
          _currentRiderLocation!,
        );
      }
    });
  }

  // [NEW] ฟังก์ชันอัปเดตพิกัดไรเดอร์ลง Firestore
  Future<void> _updateRiderLocationInFirestore(
    String orderId,
    LatLng location,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {
          'rider_lat': location.latitude,
          'rider_long': location.longitude,
          'rider_last_seen': FieldValue.serverTimestamp(), // (Optional)
        },
      );
      print("Rider location updated for $orderId");
    } catch (e) {
      print("Error updating rider location: $e");
      // ไม่แสดง SnackBar เพราะจะรบกวนผู้ใช้ทุก 10 วินาที
    }
  }

  // [NEW] Stream สำหรับดึงงานที่ไรเดอร์ปัจจุบันรับอยู่
  Stream<Order?> _fetchOngoingOrderStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('riderId', isEqualTo: user.uid)
        // [MODIFIED] กรองสถานะ 'delivered' ออกจากรายการที่ต้องแสดงในหน้าสถานะ
        .where('status', whereIn: ['accepted', 'pickedUp', 'inTransit'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Order.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // [NEW FUNCTION] อัปเดตสถานะของงานใน Firestore
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': newStatus},
      );

      print("Order $orderId status updated to: $newStatus");
    } catch (e) {
      print("Error updating order status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ: $newStatus'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // [NEW] 3. ฟังก์ชันสำหรับอัปโหลดรูปภาพและอัปเดต Firestore (แยกออกมา)
  Future<void> _uploadImageAndUpdateFirestore(
    File imageFile,
    int photoIndex,
    String orderId,
  ) async {
    // 1. แสดงสถานะกำลังอัปโหลด
    if (mounted) {
      setState(() => _isUploading = true);
    }

    try {
      // 2. อัปโหลดรูปภาพไปยัง Cloudinary
      // (ใช้ imageFile.path หรือ imageFile ก็ได้ ขึ้นอยู่กับ Service ของคุณ)
      final String? imageUrl =
          await _imageUploadService.uploadImageToCloudinary(imageFile);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // 3. กำหนดชื่อ Field ที่จะอัปเดตใน Firestore
        // (คุณสามารถเปลี่ยนชื่อ Field ได้ตามต้องการ)
        final String fieldName = (photoIndex == 0)
            ? 'pickupImageUrl' // รูปตอนรับสินค้า
            : 'deliveryImageUrl'; // รูปตอนส่งสำเร็จ

        // 4. เตรียมข้อมูลที่จะอัปเดต
        Map<String, dynamic> updateData = {fieldName: imageUrl};

        // 5. [สำคัญ] ย้ายตรรกะการเปลี่ยนสถานะมาไว้ที่นี่
        // (จะอัปเดตสถานะเป็น 'inTransit' *หลังจาก* อัปโหลดรูปสำเร็จแล้ว)
        if (photoIndex == 0) {
          final currentStatus = _currentOrderFromStream?.status;
          if (currentStatus == 'accepted' || currentStatus == 'pickedUp') {
            updateData['status'] = 'inTransit';
          }
        }

        // 6. อัปเดต Firestore (ทั้ง URL และ Status ในครั้งเดียว)
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update(updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'อัปโหลดรูป${photoIndex == 0 ? "รับ" : "ส่ง"}สำเร็จ!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // กรณี Cloudinary คืนค่า null หรือว่างเปล่า
        throw Exception('Image URL is null or empty');
      }
    } catch (e) {
      print("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูป: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 7. ซ่อนสถานะกำลังอัปโหลด
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // [MODIFIED] 4. แก้ไขฟังก์ชัน _pickImage
  Future<void> _pickImage(ImageSource source, int photoIndex) async {
    final Order? currentOrder = _currentOrderFromStream;

    if (currentOrder == null) {
      // (Handle no order... เหมือนเดิม)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ไม่พบงานที่กำลังจัดส่ง')));
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      final newImage = File(pickedFile.path);

      // 1. อัปเดต Cache ทันทีเพื่อให้ UI แสดงรูปที่เลือก
      setState(() {
        if (photoIndex == 0) {
          RiderImageCache.deliveryImage = newImage;
        } else if (photoIndex == 1) {
          RiderImageCache.successImage = newImage;
        }
      });

      // 2. เรียกฟังก์ชันอัปโหลด (ทำงานเบื้องหลัง)
      // (เราไม่ await ที่นี่ เพื่อให้ UI ตอบสนองทันที)
      _uploadImageAndUpdateFirestore(
        newImage,
        photoIndex,
        currentOrder.orderId,
      );
    }
  }

  // 5. ฟังก์ชันสำหรับแสดง Bottom Sheet เพื่อเลือกแหล่งที่มาของรูปภาพ
  void _showImageSourceActionSheet(BuildContext context, int photoIndex) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, photoIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากแกลเลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, photoIndex);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // [MODIFIED] 5. แก้ไขฟังก์ชัน _confirmDelivery
  // (ปรับปรุงเล็กน้อย: ตรวจสอบรูปภาพจาก Firebase แทน Cache)
  // (ตรรกะส่วนใหญ่เหมือนเดิมตามที่คุณแก้ไขครั้งล่าสุด)
  Future<void> _confirmDelivery(Order order) async {
    // [REVISED] ตรวจสอบว่า URL รูปภาพถูกอัปโหลดขึ้น Firebase ครบหรือยัง
    final bool hasAllPhotosUploaded =
        order.pickupImageUrl != null && order.deliveryImageUrl != null;

    // ตรวจสอบสถานะ (ป้องกันการกดซ้ำ) - (ส่วนนี้ถูกต้องแล้ว)
    if (order.status == 'delivered') {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DeliveryHomePage()),
          (route) => false,
        );
      }
      return;
    }

    // (กรณีรูปไม่ครบ) - (ส่วนนี้ถูกต้องแล้ว)
    if (!hasAllPhotosUploaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'กรุณารอรูปภาพอัปโหลดให้ครบ (หรือถ่ายรูป) ก่อนยืนยัน',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // [CORE LOGIC]
    try {
      // -----------------------------------------------------------------
      // [FIXED] 1. "บันทึก" Navigator และ Messenger ไว้ก่อน
      // (เราต้องทำสิ่งนี้ก่อน 'await' เพราะ 'context' จะหายไป)
      // -----------------------------------------------------------------
      if (!mounted) return; // ตรวจสอบอีกครั้งก่อนใช้ context
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      // -----------------------------------------------------------------

      // 2. อัปเดตสถานะเป็น 'delivered'
      // (ณ จุดนี้ StreamBuilder จะทำลาย UI แต่เราไม่สนแล้ว)
      await _updateOrderStatus(order.orderId, 'delivered');

      // 3. หยุดการติดตามตำแหน่ง
      _stopLocationTracking();

      // 4. ล้าง Cache (รูป File)
      RiderImageCache.clearCache();

      // 5. แจ้งเตือน (ใช้ 'messenger' ที่เราบันทึกไว้)
      messenger.showSnackBar(
        SnackBar(
          content: Text('จัดส่งสำเร็จ! ✅ ID: ${order.orderId}'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );

      // 6. นำทางกลับบ้าน (ใช้ 'navigator' ที่เราบันทึกไว้)
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DeliveryHomePage()),
        (route) => false,
      );
    } catch (e) {
      // ( ... handle error ... )
      print("Error completing delivery: $e");
      // ณ จุดนี้ 'mounted' อาจจะยังเป็น true ถ้า 'await' ล้มเหลวเร็ว
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการยืนยันการจัดส่ง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // [NEW] ฟังก์ชันสำหรับซูมแผนที่ไปยังขอบเขตของจุดรับและจุดส่ง
  void _fitMapToBounds(Order order) {
    List<LatLng> points = [];

    // 1. กำหนดพิกัดปลายทาง
    if (order.destinationLatitude != null &&
        order.destinationLongitude != null) {
      points.add(
        LatLng(order.destinationLatitude!, order.destinationLongitude!),
      );
    }

    // 2. กำหนดพิกัดต้นทาง (ผู้ส่ง)
    if (order.pickupLatitude != null && order.pickupLongitude != null) {
      points.add(LatLng(order.pickupLatitude!, order.pickupLongitude!));
    }

    // 3. (Optional) เพิ่มตำแหน่งล่าสุดของไรเดอร์ (จาก DB)
    if (order.riderLatitude != null && order.riderLongitude != null) {
      points.add(LatLng(order.riderLatitude!, order.riderLongitude!));
    }

    // ถ้าไม่มีพิกัดเลย ให้ใช้ค่าเริ่มต้น
    if (points.isEmpty) {
      points.add(
        const LatLng(16.2082, 103.2798),
      ); // ค่าเริ่มต้น (เช่น มหาสารคาม)
    }

    // 4. คำนวณขอบเขตแผนที่
    final LatLngBounds bounds = LatLngBounds.fromPoints(points);

    // 5. รอให้ Map พร้อมใช้งาน แล้วจึงสั่ง fitCamera
    // ใช้ addPostFrameCallback เพื่อให้แน่ใจว่า Widget สร้างเสร็จแล้ว
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // [FIXED] ลบ .ready ออก
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50.0), // เพิ่ม padding รอบๆ marker
          ),
        );
      }
    });
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
            gradient: LinearGradient(
              colors: [secondaryColor, primaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      // [MODIFIED] 6. เพิ่ม Stack สำหรับแสดงหน้า Loading
      body: Stack(
        children: [
          StreamBuilder<Order?>(
            stream: _fetchOngoingOrderStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text("ข้อผิดพลาดในการโหลดงาน: ${snapshot.error}"),
                );
              }

              // [CORE LOGIC] ตรวจสอบงานที่กำลังดำเนินการ (จาก Stream หรือ Constructor)
              final Order? currentOrder = snapshot.data ?? widget.acceptedOrder;

              // [ADDED] อัปเดตตัวแปร State ด้วย Order ล่าสุดจาก Stream
              _currentOrderFromStream = currentOrder;

              if (currentOrder == null) {
            
                _mapInitialized = false; // รีเซ็ตสถานะแผนที่ (อันนี้ปลอดภัย)
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Text(
                      "ไม่พบงานที่กำลังจัดส่ง กรุณากลับไปหน้าหลักเพื่อรับงาน",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }

              // [NEW] ถ้ามีงาน แต่ยังไม่เริ่มติดตาม ให้เริ่ม
              if (!_isLocationServiceEnabled) {
                _initializeLocationTracking();
              }

              // [NEW] ซูมแผนที่ไปยังจุดหมาย 1 ครั้งเมื่อโหลด Order สำเร็จ
              if (!_mapInitialized) {
                _fitMapToBounds(currentOrder);
                _mapInitialized = true;
              }

              // [STATE 2: งานถูกรับแล้ว (currentOrder != null)]
              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _buildTopGradientAndBanner(context, currentOrder),
                    // [MODIFIED] เรียกใช้ _buildMapSection เพื่อแสดงแผนที่ Flutter Map
                    _buildMapSection(currentOrder),
                    _buildPhotoSections(currentOrder), // [MODIFIED]
                    const SizedBox(height: 15),
                    _buildConfirmationButton(currentOrder),
                    const SizedBox(height: 20),
                    _buildProductInfoButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),

          // [NEW] 7. ส่วนแสดงผล Loading Overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "กำลังอัปโหลดรูปภาพ...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // **********************************************
      // ********* การเรียกใช้งาน Bottom Bar **********
      // **********************************************
      bottomNavigationBar: StatusBottomBar(
        currentIndex: 1,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryHomePage()),
              (route) => false,
            );
          } else if (index == 2) {
            // Logout Logic
            FirebaseAuth.instance.signOut(); // เพิ่มการ Sign Out
            // [NEW] ล้าง Cache รูปภาพเมื่อ Logout
            RiderImageCache.clearCache();
            // [NEW] หยุดการติดตามตำแหน่งเมื่อ Logout
            _stopLocationTracking();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // ส่วนฟังก์ชันย่อย (Widget Builders)
  // ----------------------------------------------------------

  Widget _buildTopGradientAndBanner(BuildContext context, Order? currentOrder) {
    const Color secondaryColor = Color(0xFF004D40);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [secondaryColor, Color(0xFF00897B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: 20.0,
              bottom: 20.0,
              left: 20.0,
              right: 20.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: const Text(
                'สถานะการจัดส่งสินค้า',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // [MODIFIED] เรียกใช้ฟังก์ชันที่ถูกแก้ไข
          _buildStepIndicators(currentOrder),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ******************************************************
  // [MODIFIED] ฟังก์ชัน _buildStepIndicators (เปลี่ยนข้อความสถานะ)
  // ******************************************************
  Widget _buildStepIndicators(Order? currentOrder) {
    final String status = currentOrder?.status ?? 'pending';

    // ตรรกะสถานะ:
    final isAccepted = status == 'accepted';
    final isPickedUp = status == 'pickedUp';
    final isInTransit = status == 'inTransit'; // กำลังเดินทาง
    final isCompleted = status == 'delivered'; // จัดส่งสำเร็จ

    // สถานะ 1: ไรเดอร์รับสินค้าแล้ว (Active เมื่อเป็น accepted, pickedUp, inTransit, delivered)
    final isFirstStepActive =
        isAccepted || isPickedUp || isInTransit || isCompleted;
    // สถานะ 2: กำลังเดินทาง (Active เมื่อเป็น inTransit หรือ delivered)
    final isSecondStepActive = isInTransit || isCompleted;
    // สถานะ 3: จัดส่งสินค้าสำเร็จ (Active เมื่อเป็น delivered)
    final isThirdStepActive = isCompleted;

    // เส้นเชื่อมต่อ
    final isLine1Active =
        isSecondStepActive; // เชื่อมต่อ 1 -> 2 (Active เมื่อเข้าสู่ inTransit)
    final isLine2Active =
        isCompleted; // เชื่อมต่อ 2 -> 3 (Active เมื่อเสร็จสิ้น)

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. ไรเดอร์รับสินค้าแล้ว
          _buildStepItem(
            icon: Icons.check_circle_outline,
            label: 'ไรเดอร์รับสินค้าแล้ว',
            isActive: isFirstStepActive,
            color: isFirstStepActive
                ? Colors.white
                : Colors.white.withOpacity(0.8),
          ),

          // [NEW] เส้นเชื่อมต่อ 1
          _buildConnectorLine(isActive: isLine1Active),

          // 2. กำลังเดินทาง (เปลี่ยนข้อความตามรูปภาพล่าสุด)
          _buildStepItem(
            icon: Icons.motorcycle,
            label: 'กำลังเดินทาง', // <--- แก้ไขข้อความ
            isActive: isSecondStepActive,
            color: isSecondStepActive
                ? Colors.white
                : Colors.white.withOpacity(0.8),
          ),

          // [NEW] เส้นเชื่อมต่อ 2
          _buildConnectorLine(isActive: isLine2Active),

          // 3. จัดส่งสินค้าสำเร็จ
          _buildStepItem(
            icon: Icons.check,
            label: 'จัดส่งสินค้าสำเร็จ',
            isActive: isThirdStepActive,
            color: isThirdStepActive
                ? Colors.white
                : Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  // [NEW] ฟังก์ชันสำหรับสร้างเส้นเชื่อมต่อระหว่างสถานะ
  Widget _buildConnectorLine({required bool isActive}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 15.0,
        ), // จัดให้อยู่ในแนวเดียวกับไอคอน
        child: Container(
          height: 3.0,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }
  // ******************************************************

  Widget _buildStepItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF00BFA5) : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80, // กำหนดความกว้างคงที่เพื่อป้องกันข้อความชนกัน
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // [MODIFIED] ฟังก์ชัน _buildMapSection (เพิ่ม Marker ไรเดอร์และ MapController)
  // --------------------------------------------------------------------------
  Widget _buildMapSection(Order order) {
    // 1. กำหนดพิกัดปลายทาง
    final LatLng destinationLatLng =
        (order.destinationLatitude != null &&
                order.destinationLongitude != null)
            ? LatLng(order.destinationLatitude!, order.destinationLongitude!)
            : const LatLng(16.2082, 103.2798); // ค่าเริ่มต้น

    // 2. กำหนดพิกัดต้นทาง (ผู้ส่ง)
    final LatLng pickupLatLng =
        (order.pickupLatitude != null && order.pickupLongitude != null)
            ? LatLng(order.pickupLatitude!, order.pickupLongitude!)
            : destinationLatLng; // ใช้ปลายทางแทน ถ้าไม่มีพิกัดผู้ส่ง

    // 3. กำหนด Marker สำหรับปลายทาง, ต้นทาง
    final List<Marker> markers = [
      // Marker ปลายทาง (ผู้รับ - สีแดง)
      Marker(
        point: destinationLatLng,
        width: 80,
        height: 80,
        child: const Column(
          children: [
            Icon(Icons.location_pin, color: Colors.red, size: 40),
            Text(
              "ผู้รับ",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      // Marker ต้นทาง (ผู้ส่ง - สีเขียว)
      Marker(
        point: pickupLatLng,
        width: 80,
        height: 80,
        child: const Column(
          children: [
            Icon(Icons.store, color: Colors.green, size: 40),
            Text(
              "ผู้ส่ง",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];

    // [NEW] 4. เพิ่ม Marker ของไรเดอร์ (ถ้ามีตำแหน่ง GPS สด)
    if (_currentRiderLocation != null) {
      markers.add(
        Marker(
          point: _currentRiderLocation!,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.motorcycle,
            color: Colors.blueAccent, // สีน้ำเงินสำหรับไรเดอร์
            size: 35,
            shadows: [Shadow(color: Colors.black, blurRadius: 5)],
          ),
        ),
      );
    }
    // [NEW] 5. (ทางเลือก) แสดงตำแหน่งล่าสุดของไรเดอร์จาก DB ถ้ายังไม่มี GPS สด
    else if (order.riderLatitude != null && order.riderLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(order.riderLatitude!, order.riderLongitude!),
          width: 80,
          height: 80,
          child: Icon(
            Icons.motorcycle,
            color: Colors.blueAccent.withOpacity(0.5), // สีจางลง
            size: 35,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
      child: Column(
        children: [
          // 1. Map Widget (Flutter Map)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: FlutterMap(
                  // [MODIFIED] ใช้ MapController
                  mapController: _mapController,
                  options: MapOptions(
                    // [MODIFIED] กำหนดค่าเริ่มต้น (จะถูก override โดย _fitMapToBounds)
                    initialCenter: destinationLatLng,
                    initialZoom: 14.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  // Layers ของแผนที่
                  children: [
                    // Tile Layer (OpenStreetMap Standard)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      // TODO: [สำคัญ] ต้องเปลี่ยน com.example.app เป็นชื่อแพ็กเกจจริงของคุณ
                      userAgentPackageName: 'com.example.ez_deliver_tracksure',
                    ),

                    // [MODIFIED] Marker Layer (แสดง Markers ทั้งหมด)
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          // 2. Address Details Card
          _buildAddressDetailCard(order),
        ],
      ),
    );
  }
  // --------------------------------------------------------------------------

  // [NEW] ฟังก์ชันสำหรับสร้าง Card แสดงรายละเอียดที่อยู่ผู้ส่งและผู้รับ
  Widget _buildAddressDetailCard(Order order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ส่วนผู้ส่ง
            _buildDetailRow(
              icon: Icons.storefront,
              title: 'ผู้ส่ง: ${order.customerName}',
              address: order.pickupLocation,
              // ใช้ 'N/A' ตามภาพตัวอย่าง (สมมติว่าไม่มีเบอร์โทรผู้ส่งใน Model)
              phone: 'เบอร์โทร: N/A', // หากมีข้อมูลเบอร์ผู้ส่ง ให้แก้ตรงนี้
              iconColor: Colors.green, // สีเขียว (Pickup)
            ),
            const Divider(height: 25, thickness: 1),
            // ส่วนผู้รับ
            _buildDetailRow(
              icon: Icons.person_pin_circle,
              title: 'ผู้รับ: ${order.receiverName}',
              address: order.destination,
              // ดึงเบอร์โทรผู้รับจาก Model
              phone: 'เบอร์โทร: ${order.receiverPhone}',
              iconColor: Colors.red, // สีแดง (Destination)
            ),
          ],
        ),
      ),
    );
  }

  // [NEW] ฟังก์ชันสำหรับแสดง Row รายละเอียดที่อยู่แต่ละรายการ
  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String address,
    required String phone,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Icon
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ชื่อผู้ส่ง/ผู้รับ
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // ที่อยู่
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // เบอร์โทร
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // [MODIFIED] 8. แก้ไขฟังก์ชัน PhotoSections (เล็กน้อย)
  Widget _buildPhotoSections(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildPhotoCard(
            label: 'ฉันรับสินค้าแล้ว',
            photoIndex: 0,
            // [NEW] ส่ง URL รูปจาก Firebase (ถ้ามี)
            uploadedImageUrl: order.pickupImageUrl,
          ),
          _buildPhotoCard(
            label: 'ยืนยันการจัดส่งสินค้า',
            photoIndex: 1,
            // [NEW] ส่ง URL รูปจาก Firebase (ถ้ามี)
            uploadedImageUrl: order.deliveryImageUrl,
          ),
        ],
      ),
    );
  }

  // [MODIFIED] 9. แก้ไข _buildPhotoCard (แสดงรูปจาก Firebase หรือ Cache)
  Widget _buildPhotoCard({
    required String label,
    required int photoIndex,
    String? uploadedImageUrl, // [NEW]
  }) {
    // [REVISED] ตรรกะการแสดงรูป
    // 1. ตรวจสอบ Cache ก่อน (เผื่อผู้ใช้เพิ่งถ่ายรูปและกำลังอัปโหลด)
    final File? imageFileFromCache = photoIndex == 0
        ? RiderImageCache.deliveryImage
        : RiderImageCache.successImage;

    // 2. กำหนดว่ามีรูปภาพที่จะแสดงหรือไม่
    bool hasImage =
        imageFileFromCache != null || (uploadedImageUrl?.isNotEmpty ?? false);

    // 3. กำหนดว่าจะใช้ ImageProvider ตัวไหน
    ImageProvider? imageProvider;
    if (imageFileFromCache != null) {
      imageProvider = FileImage(imageFileFromCache); // ใช้รูปจาก Cache
    } else if (uploadedImageUrl?.isNotEmpty ?? false) {
      imageProvider = NetworkImage(uploadedImageUrl!); // ใช้รูปจาก Firebase
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                // [NEW] ถ้ากำลังอัปโหลด ป้องกันไม่ให้กดถ่ายรูปซ้ำ
                if (_isUploading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณารอการอัปโหลดให้เสร็จสิ้น...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                _showImageSourceActionSheet(context, photoIndex);
              },
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                  // [REVISED] ใช้ imageProvider ที่เราเลือกไว้
                  image: hasImage
                      ? DecorationImage(
                          image: imageProvider!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                // [REVISED] แสดง Icon (กล้อง) เมื่อไม่มีรูปภาพเท่านั้น
                child: !hasImage
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // [MODIFIED] 10. แก้ไข _buildConfirmationButton (เล็กน้อย)
  Widget _buildConfirmationButton(Order order) {
    const Color primaryColor = DeliveryStatusScreen.primaryColor;

    // [REVISED] ตรวจสอบว่ารูปอัปโหลดขึ้น Firebase หรือยัง
    final bool hasAllPhotos =
        (order.pickupImageUrl != null && order.pickupImageUrl!.isNotEmpty) &&
            (order.deliveryImageUrl != null &&
                order.deliveryImageUrl!.isNotEmpty);

    // [REVISED LOGIC] (เหมือนเดิม)
    final bool isAlreadyDelivered = order.status == 'delivered';
    final bool canConfirm = hasAllPhotos && !isAlreadyDelivered;

    final String buttonText;
    final Color buttonColor;
    final IconData buttonIcon;

    if (isAlreadyDelivered) {
      buttonText = 'จัดส่งสำเร็จแล้ว';
      buttonColor = const Color(0xFF4CAF50); // เขียว
      buttonIcon = Icons.check_circle;
    } else if (hasAllPhotos) {
      buttonText = 'ยืนยันการจัดส่ง';
      buttonColor = primaryColor; // ฟ้า (พร้อมยืนยัน)
      buttonIcon = Icons.cloud_upload;
    } else {
      buttonText = 'ยืนยันการจัดส่ง';
      buttonColor = Colors.grey; // เทา (รูปไม่ครบ)
      buttonIcon = Icons.cloud_upload;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ElevatedButton.icon(
        icon: Icon(buttonIcon, color: Colors.white),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          // [NEW] ถ้ากำลังอัปโหลด ห้ามกดยืนยัน
          if (_isUploading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('กรุณารอรูปภาพอัปโหลดให้เสร็จสิ้น...'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // (ตรรกะการกดยืนยัน ... เหมือนเดิม)
          if (canConfirm) {
            _confirmDelivery(order);
          } else if (isAlreadyDelivered) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryHomePage()),
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('กรุณาอัปโหลดรูปภาพให้ครบทั้ง 2 รูปก่อน'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildProductInfoButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () {
            // โชว์ข้อมูลสินค้า
            _showProductDetails(context, _currentOrderFromStream);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'ข้อมูลสินค้า',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // [NEW] ฟังก์ชันสำหรับแสดงข้อมูลสินค้า
  void _showProductDetails(BuildContext context, Order? order) {
    if (order == null) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            // [FIXED] แก้ไข Typo จาก RoundedRectangleb
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'รายละเอียดสินค้า',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('คำอธิบาย: ${order.productDescription}'),
                const SizedBox(height: 10),
                // [REVISED] ใช้ productImageUrl (ที่ดึงมาจาก List)
                if (order.productImageUrl != null &&
                    order.productImageUrl!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('รูปภาพสินค้า:'),
                      const SizedBox(height: 5),
                      Image.network(
                        order.productImageUrl!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('ไม่สามารถโหลดรูปภาพได้'),
                      ),
                    ],
                  )
                else
                  const Text('ไม่มีรูปภาพสินค้าแนบมา'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'ปิด',
                style: TextStyle(color: DeliveryStatusScreen.primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
} // ปิด State