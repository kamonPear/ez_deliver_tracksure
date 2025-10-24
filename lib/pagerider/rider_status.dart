import 'dart:async';
import 'dart:io';

// Flutter Core Imports
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Package Imports (External Libraries)
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// +++ เพิ่ม GEOLOCATOR +++
import 'package:geolocator/geolocator.dart'; 
// +++

// Firebase Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Cloudinary Imports (สมมติว่าไฟล์นี้มีอยู่จริง)
import 'package:ez_deliver_tracksure/api/api_service_image.dart'; 

// Local Imports (สมมติว่าไฟล์เหล่านี้มีอยู่จริง)
import 'rider_bottom_bar.dart'; 
import 'rider_home.dart'; 
import 'package:ez_deliver_tracksure/pages/login.dart'; 

// **********************************************
// 1. CLASS สำหรับเก็บสถานะรูปภาพชั่วคราว (Cache)
// **********************************************
class RiderImageCache {
  static File? deliveryImage;
  static File? successImage;

  static void clearCache() {
    deliveryImage = null;
    successImage = null;
  }
}

// ----------------------
// 2. Order Model (ไม่เปลี่ยนแปลง)
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
  final String? productImageUrl;
  final String? pickupImageUrl; // URL รูปที่ไรเดอร์ถ่ายตอนรับของ
  final String? deliveryImageUrl; // URL รูปที่ไรเดอร์ถ่ายตอนส่งของ
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
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Order data is null for document ${doc.id}");
    }

    final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;

    return Order(
      orderId: doc.id,
      createdDate: createdAtTimestamp?.toDate(),
      customerName: data['customerName'] ?? 'ไม่ระบุลูกค้า',
      destination: data['destination'] ?? 'ไม่ระระบุปลายทาง',
      pickupLocation: data['pickupLocation'] ?? 'ไม่ระระบุต้นทาง',
      productDescription: data['productDescription'] ?? 'ไม่ระบุสินค้า',
      receiverName: data['receiverName'] ?? 'ไม่ระระบุผู้รับ',
      receiverPhone: data['receiverPhone'] ?? 'ไม่ระบุเบอร์โทร',
      productImageUrl: data['productImageUrl'],
      pickupImageUrl: data['pickupImageUrl'],
      deliveryImageUrl: data['deliveryImageUrl'],
      status: data['status'] ?? 'accepted',
      destinationLatitude: (data['destination_latitude'] as num?)?.toDouble(),
      destinationLongitude: (data['destination_longitude'] as num?)?.toDouble(),
      pickupLatitude: (data['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickup_longitude'] as num?)?.toDouble(),
    );
  }
}

// ----------------------
// 3. DeliveryStatusScreen Widget
// ----------------------
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

  // ตัวแปรสำหรับสถานะการอัปโหลด
  bool _isUploadingPhoto = false;

  // สร้าง Instance ของ ImageUploadService
  final ImageUploadService _imageUploadService = ImageUploadService();
  
  // +++ [NEW CODE: Location Tracking] +++
  StreamSubscription<Position>? _positionStreamSubscription;
  final String? _riderId = FirebaseAuth.instance.currentUser?.uid; 
  // +++


  @override
  void initState() {
    super.initState();
    // +++ [NEW CALL] +++
    // เริ่มติดตามและอัปเดตตำแหน่งเมื่อเข้าหน้านี้
    _checkPermissionAndStartLocationUpdates();
    // +++
  }

  @override
  void dispose() {
    // +++ [NEW DISPOSE] +++
    _positionStreamSubscription?.cancel();
    // +++
    super.dispose();
  }

  // ----------------------------------------------------------
  // MARK: - Location Logic 🚀 (NEW SECTION)
  // ----------------------------------------------------------

  Future<void> _checkPermissionAndStartLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบบริการ GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเปิด GPS เพื่อให้สามารถติดตามตำแหน่งได้', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // ตรวจสอบสิทธิ์
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('การอนุญาตตำแหน่งถูกปฏิเสธ', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาไปตั้งค่าเพื่ออนุญาตการเข้าถึงตำแหน่งแบบถาวร', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // เริ่มอัปเดตตำแหน่งถ้าทุกอย่างพร้อม
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    if (_riderId == null) return;

    // ตั้งค่าความถี่ในการอัปเดต (High accuracy, อัปเดตทุก 10 เมตร)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, 
    );

    // ยกเลิกการ Stream เก่าถ้ามี
    _positionStreamSubscription?.cancel();
    
    // เริ่ม Stream ตำแหน่ง
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings
    ).listen(
      (Position position) {
        // อัปเดตตำแหน่งไปยัง Firestore collection 'riders'
        _updateRiderLocation(position);
      },
      onError: (e) {
        print("Error getting location updates: $e");
      }
    );
    print("Location stream started for rider: $_riderId");
  }

  Future<void> _updateRiderLocation(Position position) async {
    if (_riderId == null) return;
    
    // อัปเดตตำแหน่งปัจจุบันของไรเดอร์ไปยัง Collection 'riders'
    try {
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(_riderId)
          .update({
            'current_latitude': position.latitude,
            'current_longitude': position.longitude,
            'last_updated': FieldValue.serverTimestamp(),
          });
      // print("Rider location updated: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("Error updating rider location in Firestore: $e");
    }
  }


  // ----------------------------------------------------------
  // MARK: - Firebase & Data Logic (ส่วนเดิม)
  // ----------------------------------------------------------
  
  Stream<Order?> _fetchOngoingOrderStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('riderId', isEqualTo: user.uid)
        // เราจะแสดงจนถึง 'delivered'
        .where('status',
            whereIn: ['accepted', 'pickedUp', 'inTransit', 'delivered'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Order.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

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

  /// ฟังก์ชันสำหรับอัปโหลดรูปภาพด้วย Cloudinary และอัปเดต Firestore
  Future<void> _uploadImageAndUpdateFirestore(
      File imageFile, String orderId, String imageFieldName, String? newStatus) async {
    
    try {
      // 1. อัปโหลดไฟล์ไปยัง Cloudinary
      final String? downloadUrl =
          await _imageUploadService.uploadImageToCloudinary(imageFile);

      if (downloadUrl == null) {
        throw Exception("Cloudinary upload failed: received null URL");
      }

      // 2. สร้าง Map สำหรับอัปเดต Firestore
      final Map<String, dynamic> updateData = {
        imageFieldName: downloadUrl, 
      };

      // 3. (Optional) เพิ่มการอัปเดตสถานะถ้ามี
      if (newStatus != null) {
        updateData['status'] = newStatus; 
      }

      // 4. อัปเดต Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      print("Firestore updated: $imageFieldName and status $newStatus with Cloudinary URL");
      
    } catch (e) {
      print("Error uploading image to Cloudinary/Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดรูปภาพล้มเหลว: $e')),
        );
      }
      rethrow; 
    }
  }


  // 3. ฟังก์ชันสำหรับเลือกรูปภาพจาก Camera หรือ Gallery
  Future<void> _pickImage(ImageSource source, int photoIndex) async {
    
    // ป้องกันการอัปโหลดซ้ำซ้อน
    if (_isUploadingPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังอัปโหลดรูปภาพก่อนหน้า...')),
      );
      return;
    }
    
    if (mounted) setState(() => _isUploadingPhoto = true); // เริ่มโหลด

    final Order? currentOrder = _currentOrderFromStream;

    if (currentOrder == null) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false); // หยุดโหลดถ้าไม่มีงาน
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('ไม่พบงานที่กำลังจัดส่ง กรุณากลับไปหน้าหลักเพื่อรับงาน')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      final newImage = File(pickedFile.path);

      // อัปเดต UI (Cache) ทันที
      setState(() {
        if (photoIndex == 0) {
          RiderImageCache.deliveryImage = newImage;
        } else if (photoIndex == 1) {
          RiderImageCache.successImage = newImage;
        }
      });

      // --- เริ่มการอัปโหลดรูปภาพไปยัง Cloudinary ---
      try {
        if (photoIndex == 0) {
          // 1. อัปโหลดรูปภาพรับสินค้า (ไม่เปลี่ยนสถานะทันที)
          await _uploadImageAndUpdateFirestore(
            newImage,
            currentOrder.orderId,
            'pickupImageUrl', 
            null, 
          );

          if (mounted) {
            // แจ้งเตือนไรเดอร์ว่ารูปอัปโหลดแล้ว และจะเริ่มนับถอยหลัง
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'อัปโหลดรูปรับสินค้าสำเร็จ! สถานะ "กำลังไปส่งของ" จะอัปเดตใน 30 วินาที'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 4),
              ),
            );
            
            // 2. หน่วงเวลา 30 วินาที แล้วอัปเดตสถานะเป็น 'inTransit'
            Future.delayed(const Duration(seconds: 30), () async {
              try {
                // ตรวจสอบว่ายังเป็นออเดอร์เดิม และยังไม่ได้ถูกส่งสำเร็จ
                if (_currentOrderFromStream?.orderId == currentOrder.orderId && 
                    _currentOrderFromStream?.status != 'delivered' && 
                    _currentOrderFromStream?.status != 'completed') {
                        
                    await _updateOrderStatus(currentOrder.orderId, 'inTransit');

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('สถานะงานเปลี่ยนเป็น "กำลังไปส่งของ" แล้ว'),
                          backgroundColor: DeliveryStatusScreen.primaryColor,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                }
              } catch (e) {
                print("Error in delayed status update: $e");
              }
            });
          }

        } else if (photoIndex == 1) {
          // นี่คือ "รูปส่งสำเร็จ"
          await _uploadImageAndUpdateFirestore(
            newImage,
            currentOrder.orderId,
            'deliveryImageUrl', 
            null, 
          );
        }
      } catch (e) {
        // หากมีข้อผิดพลาดในการอัปโหลด
        if (mounted) {
          setState(() {
            if (photoIndex == 0) {
              RiderImageCache.deliveryImage = null;
            } else if (photoIndex == 1) {
              RiderImageCache.successImage = null;
            }
          });
        }
        // ไม่ต้องทำอะไรเพิ่ม เนื่องจาก _uploadImageAndUpdateFirestore จัดการ SnackBar ไปแล้ว
      } finally {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    } else {
      // ถ้าไม่ได้เลือกรูป
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }


  // [MODIFIED FUNCTION] ฟังก์ชันยืนยันการจัดส่ง
  Future<void> _confirmDelivery(Order order) async {
    
    // ตรวจสอบว่ากำลังอัปโหลดรูปอยู่หรือไม่
    if (_isUploadingPhoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณารอการอัปโหลดรูปภาพให้เสร็จสิ้น...')),
        );
      return;
    }
    
    // 1. ตรวจสอบว่ารูปภาพครบ 2 รูปหรือไม่ (จาก Cache)
    final bool hasAllPhotos = RiderImageCache.deliveryImage != null &&
        RiderImageCache.successImage != null;

    // 2. ตรวจสอบเงื่อนไขการสิ้นสุดงาน (ต้องมีรูปภาพครบ AND สถานะเป็น 'delivered' แล้ว)
    // Note: 'delivered' คือสถานะที่กดครั้งที่ 1
    final bool isReadyToComplete = hasAllPhotos && order.status == 'delivered';

    // ----------------------------------------------------
    // กรณีที่ 1: รูปภาพครบ แต่สถานะยังไม่เป็น 'delivered' (กดยืนยันครั้งที่ 1)
    // ----------------------------------------------------
    if (hasAllPhotos && order.status != 'delivered') {
      // อัปเดตสถานะเป็น 'delivered'
      await _updateOrderStatus(order.orderId, 'delivered');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('รูปภาพครบ! กรุณากดปุ่ม "สิ้นสุดงานจัดส่ง" อีกครั้งเพื่อจบงาน'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return; 
    }

    // ----------------------------------------------------
    // กรณีที่ 2: เงื่อนไขการจบงานครบถ้วน (isReadyToComplete == true) (กดยืนยันครั้งที่ 2)
    // ----------------------------------------------------
    if (isReadyToComplete) {
      try {
        
        // 1. เปลี่ยนสถานะเป็น 'completed' เพื่อเก็บประวัติ
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.orderId)
            .update({'status': 'completed'});
            
        // 2. ล้าง Cache รูปภาพและหยุด Location Tracking
        RiderImageCache.clearCache();
        _positionStreamSubscription?.cancel(); // **สำคัญ: หยุดส่งตำแหน่ง**

        // 3. แจ้งเตือน (Snackbar)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('สิ้นสุดงานจัดส่งสำเร็จ! ✅ ID: ${order.orderId}'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );

          // 4. นำทางกลับไปหน้าหลัก (หน้ารับงาน)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const DeliveryHomePage()), // ไปหน้า Home
            (route) => false,
          );
        }
      } catch (e) {
        print("Error completing delivery: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการสิ้นสุดการจัดส่ง'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // ----------------------------------------------------
    // กรณีที่ 3: รูปยังไม่ครบ (แสดงข้อความเตือน)
    // ----------------------------------------------------
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาอัปโหลดรูปภาพสถานะให้ครบก่อนยืนยัน'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // ----------------------------------------------------------
  // MARK: - UI Helper Functions (Bottom Sheets)
  // ----------------------------------------------------------

  // 5. ฟังก์ชันสำหรับแสดง Bottom Sheet
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

  // ฟังก์ชัน _showProductDetails (เหมือนเดิม)
  void _showProductDetails(BuildContext context, Order? order) {
    if (order == null) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('รายละเอียดสินค้า',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('คำอธิบาย: ${order.productDescription}'),
                const SizedBox(height: 10),
                if (order.productImageUrl != null &&
                    order.productImageUrl!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('รูปภาพสินค้า (จากผู้ส่ง):'),
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
                  ),
                if (order.productImageUrl == null ||
                    order.productImageUrl!.isEmpty)
                  const Text('ไม่มีรูปภาพสินค้าแนบมา'),
                
                // แสดงรูปที่ไรเดอร์อัปโหลด (ถ้ามี)
                const Divider(height: 20),
                if (order.pickupImageUrl != null && order.pickupImageUrl!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('รูปภาพตอนรับสินค้า (ไรเดอร์):'),
                      const SizedBox(height: 5),
                      Image.network(
                        order.pickupImageUrl!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('ไม่สามารถโหลดรูปภาพได้'),
                      ),
                    ],
                  ),
                if (order.deliveryImageUrl != null && order.deliveryImageUrl!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('รูปภาพตอนส่งสินค้า (ไรเดอร์):'),
                      const SizedBox(height: 5),
                      Image.network(
                        order.deliveryImageUrl!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('ไม่สามารถโหลดรูปภาพได้'),
                      ),
                    ],
                  ),

              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ปิด',
                  style: TextStyle(color: DeliveryStatusScreen.primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------
  // MARK: - Widget Builders (ส่วนเดิม)
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
                top: 20.0, bottom: 20.0, left: 20.0, right: 20.0),
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
          _buildStepIndicators(currentOrder),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepIndicators(Order? currentOrder) {
    final String status = currentOrder?.status ?? 'pending';
    
    // Logic สถานะ 4 ขั้นตอน:
    final isPending = status == 'pending';
    final isAcceptedOrEnroute = status == 'accepted' || status == 'en_route';
    final isPickedUpOrInTransit = status == 'picked_up' || status == 'inTransit';
    final isCompletedOrDelivered = status == 'completed' || status == 'delivered';

    // การกำหนด Active State สำหรับ 4 ขั้นตอนใหม่
    final isStep1Active = isPending; 
    final isStep2Active = isAcceptedOrEnroute || isPickedUpOrInTransit || isCompletedOrDelivered;
    final isStep3Active = isPickedUpOrInTransit || isCompletedOrDelivered;
    final isStep4Active = isCompletedOrDelivered;


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. รอไรเดอร์รับสินค้า (Pending)
          _buildStepItem(
            icon: Icons.access_time_filled,
            label: 'รอไรเดอร์รับสินค้า',
            isActive: isStep1Active,
            color: isStep1Active ? Colors.white : Colors.white.withOpacity(0.8),
          ),
          // เส้นเชื่อมต่อ 1->2
          _buildConnectorLine(isActive: isStep2Active || isStep3Active || isStep4Active),

          // 2. ได้รับออเดอร์แล้ว (Accepted/Enroute)
          _buildStepItem(
            icon: Icons.description,
            label: 'ได้รับออเดอร์แล้ว',
            isActive: isStep2Active,
            color: isStep2Active ? Colors.white : Colors.white.withOpacity(0.8),
          ),
          // เส้นเชื่อมต่อ 2->3
          _buildConnectorLine(isActive: isStep3Active || isStep4Active),

          // 3. กำลังไปส่งของ (PickedUp/InTransit)
          _buildStepItem(
            icon: Icons.motorcycle,
            label: 'กำลังไปส่งของ',
            isActive: isStep3Active,
            color: isStep3Active ? Colors.white : Colors.white.withOpacity(0.8),
          ),
          // เส้นเชื่อมต่อ 3->4
          _buildConnectorLine(isActive: isStep4Active),

          // 4. จัดส่งสินค้าสำเร็จ (Completed/Delivered)
          _buildStepItem(
            icon: Icons.check_circle,
            label: 'จัดส่งสำเร็จ',
            isActive: isStep4Active,
            color: isStep4Active ? Colors.white : Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectorLine({required bool isActive}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          height: 3.0,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }

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
          width: 80, 
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

  Widget _buildMapSection(Order order) {
    final LatLng destinationLatLng =
        (order.destinationLatitude != null && order.destinationLongitude != null)
            ? LatLng(order.destinationLatitude!, order.destinationLongitude!)
            : const LatLng(16.2082, 103.2798); 
    final LatLng pickupLatLng =
        (order.pickupLatitude != null && order.pickupLongitude != null)
            ? LatLng(order.pickupLatitude!, order.pickupLongitude!)
            : destinationLatLng; 

    final LatLngBounds bounds =
        LatLngBounds.fromPoints([destinationLatLng, pickupLatLng]);

    final List<Marker> markers = [
      Marker(
        point: destinationLatLng,
        width: 80,
        height: 80,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red, 
          size: 40,
        ),
      ),
      Marker(
        point: pickupLatLng,
        width: 80,
        height: 80,
        child: const Icon(
          Icons.location_on,
          color: Colors.green,
          size: 40,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: bounds,
                      padding:
                          const EdgeInsets.all(50.0), 
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ez_deliver_tracksure', 
                    ),
                    MarkerLayer(
                      markers: markers,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          _buildAddressDetailCard(order),
        ],
      ),
    );
  }

  Widget _buildAddressDetailCard(Order order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildDetailRow(
              icon: Icons.location_pin,
              title: 'ผู้ส่ง: ${order.customerName}',
              address: order.pickupLocation,
              phone: 'เบอร์โทร: N/A', 
              iconColor: Colors.green, 
            ),
            const Divider(height: 25, thickness: 1),
            _buildDetailRow(
              icon: Icons.location_pin,
              title: 'ผู้รับ: ${order.receiverName}',
              address: order.destination,
              phone: 'เบอร์โทร: ${order.receiverPhone}',
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

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
        Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildPhotoCard(
            label: 'ฉันรับสินค้าแล้ว',
            photoIndex: 0,
          ),
          _buildPhotoCard(
            label: 'ยืนยันการจัดส่งสินค้า',
            photoIndex: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String label,
    required int photoIndex,
  }) {
    final File? imageFile = photoIndex == 0
        ? RiderImageCache.deliveryImage
        : RiderImageCache.successImage;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImageSourceActionSheet(context, photoIndex),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  image: imageFile != null
                      ? DecorationImage(
                          image: FileImage(imageFile),
                          fit: BoxFit.cover,
                        )
                      : null, 
                ),
                child: imageFile == null
                    ? Center(
                        // แสดง Loading หรือ Icon
                        child: _isUploadingPhoto 
                            ? const CircularProgressIndicator(
                                color: DeliveryStatusScreen.primaryColor,
                              )
                            : Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 4)
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationButton(Order order) {
    final isReadyToComplete = order.status == 'delivered' &&
        RiderImageCache.deliveryImage != null &&
        RiderImageCache.successImage != null;

    final String buttonText =
        isReadyToComplete ? 'สิ้นสุดงานจัดส่ง' : 'ยืนยันการจัดส่งสินค้า';
    final Color buttonColor = isReadyToComplete
        ? DeliveryStatusScreen.primaryColor
        : const Color(0xFF66BB6A);

    return ElevatedButton(
      onPressed: () {
        _confirmDelivery(order);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      child: Text(
        buttonText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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

  // ----------------------------------------------------------
  // MARK: - Main Build Method (ส่วนเดิม)
  // ----------------------------------------------------------

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

      body: StreamBuilder<Order?>(
        stream: _fetchOngoingOrderStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text("ข้อผิดพลาดในการโหลดงาน: ${snapshot.error}"));
          }

          final Order? currentOrder = snapshot.data ?? widget.acceptedOrder;
          _currentOrderFromStream = currentOrder;

          if (currentOrder == null) {
            // [STATE 1: ไม่ได้กดรับงาน / งานเสร็จแล้ว]
            if (RiderImageCache.deliveryImage != null ||
                RiderImageCache.successImage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    RiderImageCache.clearCache(); 
                  });
                }
              });
            }

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

          // [STATE 2: งานถูกรับแล้ว (currentOrder != null)]
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _buildTopGradientAndBanner(context, currentOrder),
                _buildMapSection(currentOrder),
                _buildPhotoSections(),
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
            FirebaseAuth.instance.signOut(); 
            RiderImageCache.clearCache();
            _positionStreamSubscription?.cancel(); // **สำคัญ: หยุดส่งตำแหน่งเมื่อ Log out**
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
}