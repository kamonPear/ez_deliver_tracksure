<<<<<<< HEAD
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// [NEW] Import สำหรับ Flutter Map และพิกัด
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// [NEW] เพิ่ม Firebase Imports ที่จำเป็น
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Local Imports
// สมมติว่าไฟล์เหล่านี้มีอยู่จริง (ตามโค้ดต้นฉบับ)
import 'rider_bottom_bar.dart'; // สมมติว่ามี StatusBottomBar อยู่ในนี้
import 'rider_home.dart'; // สมมติว่ามี DeliveryHomePage อยู่ในนี้
import 'package:ez_deliver_tracksure/pages/login.dart'; // สมมติว่ามี LoginPage อยู่ในนี้

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
// Order Model
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
  final String status;
  final double? destinationLatitude;
  final double? destinationLongitude;
  // [ADDED] เพิ่มพิกัดสำหรับจุดรับสินค้า
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
    this.status = 'accepted',
    this.destinationLatitude,
    this.destinationLongitude,
    // [MODIFIED] เพิ่มพารามิเตอร์สำหรับพิกัดต้นทาง
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
      // ดึงเบอร์โทรผู้รับจาก 'receiverPhone'
      receiverPhone: data['receiverPhone'] ?? 'ไม่ระบุเบอร์โทร',
      productImageUrl: data['productImageUrl'],
      status: data['status'] ?? 'accepted',
      // [MODIFIED] ดึงและแปลง Lat/Lng ปลายทาง
      destinationLatitude: (data['destination_latitude'] as num?)?.toDouble(),
      destinationLongitude: (data['destination_longitude'] as num?)?.toDouble(),
      // [ADDED] ดึงและแปลง Lat/Lng ต้นทาง
      pickupLatitude: (data['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickup_longitude'] as num?)?.toDouble(),
    );
  }
}

// ----------------------
// 2. DeliveryStatusScreen
// ----------------------
class DeliveryStatusScreen extends StatefulWidget {
  final Order? acceptedOrder; // ทำให้เป็น optional

  const DeliveryStatusScreen({super.key, this.acceptedOrder});
=======
import 'package:flutter/material.dart';
import 'rider_bottom_bar.dart'; 
import 'rider_home.dart';
import 'rider_home.dart'; 
import 'package:ez_deliver_tracksure/pages/login.dart';

class DeliveryStatusScreen extends StatelessWidget {
  const DeliveryStatusScreen({super.key});
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af

  static const Color primaryColor = Color(0xFF00BFA5);
  static const Color secondaryColor = Color(0xFF004D40);

  @override
<<<<<<< HEAD
  State<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> {
  // [ADDED] ตัวแปรสำหรับเก็บ Order ล่าสุดจาก Stream
  Order? _currentOrderFromStream;

  @override
  void initState() {
    super.initState();
    // ไม่ต้องทำอะไรใน initState เนื่องจากใช้ Static Cache
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

  // 3. ฟังก์ชันสำหรับเลือกรูปภาพจาก Camera หรือ Gallery
  Future<void> _pickImage(ImageSource source, int photoIndex) async {
    // [MODIFIED] ดึง Order ล่าสุดจากตัวแปร State
    final Order? currentOrder = _currentOrderFromStream;

    if (currentOrder == null) {
      if (mounted) {
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
      setState(() {
        final newImage = File(pickedFile.path);
        if (photoIndex == 0) {
          // [MODIFIED] บันทึกใน Static Cache
          RiderImageCache.deliveryImage = newImage;

          // [CORE MODIFICATION] เมื่อถ่ายรูป "ฉันได้รับสินค้าแล้ว" (photoIndex 0)
          // ให้อัปเดตสถานะเป็น 'inTransit' (กำลังเดินทาง) ทันที
          // ตรวจสอบสถานะเดิมก่อนอัปเดตเพื่อไม่ให้เรียกซ้ำ
          if (currentOrder.status == 'accepted' ||
              currentOrder.status == 'pickedUp') {
            _updateOrderStatus(currentOrder.orderId, 'inTransit');
          }
        } else if (photoIndex == 1) {
          // [MODIFIED] บันทึกใน Static Cache
          RiderImageCache.successImage = newImage;

          // **[แก้ไขตามคำขอ: ลบการเปลี่ยนสถานะอัตโนมัติออก]**
          // การเปลี่ยนสถานะเป็น 'delivered' และการนำทางจะทำเมื่อกดยืนยันการจัดส่งเท่านั้น
        }
      });
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

  // [MODIFIED FUNCTION] ฟังก์ชันยืนยันการจัดส่ง (แก้ไขให้กดยืนยัน 2 ขั้นตอน)
  Future<void> _confirmDelivery(Order order) async {
    // 1. ตรวจสอบว่ารูปภาพครบ 2 รูปหรือไม่
    final bool hasAllPhotos = RiderImageCache.deliveryImage != null &&
        RiderImageCache.successImage != null;

    // 2. ตรวจสอบเงื่อนไขการสิ้นสุดงาน (ต้องมีรูปภาพครบ AND สถานะเป็น 'delivered' แล้ว)
    final bool isReadyToComplete = hasAllPhotos && order.status == 'delivered';

    // ----------------------------------------------------
    // กรณีที่ 1: รูปภาพครบ แต่สถานะยังไม่เป็น 'delivered' (กดยืนยันครั้งที่ 1)
    // ----------------------------------------------------
    if (hasAllPhotos && order.status != 'delivered') {
      // อัปเดตสถานะเป็น 'delivered' (แต่ยังไม่ลบงานและยังไม่กลับหน้าหลัก)
      await _updateOrderStatus(order.orderId, 'delivered');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // ข้อความแจ้งให้กดปุ่มอีกครั้ง (ปุ่มจะเปลี่ยนเป็น 'สิ้นสุดงานจัดส่ง' โดยอัตโนมัติ)
            content:
                Text('รูปภาพครบ! กรุณากดปุ่ม "สิ้นสุดงานจัดส่ง" อีกครั้งเพื่อจบงาน'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return; // หยุดการทำงาน ยังไม่สิ้นสุดงาน
    }

    // ----------------------------------------------------
    // กรณีที่ 2: เงื่อนไขการจบงานครบถ้วน (isReadyToComplete == true) (กดยืนยันครั้งที่ 2)
    // ----------------------------------------------------
    if (isReadyToComplete) {
      try {
        // 1. **ลบเอกสาร Order ออกจาก Firestore** (ถือว่าจัดส่งสำเร็จและเสร็จสิ้นงาน)
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.orderId)
            .delete();

        // 2. **ล้าง Cache รูปภาพ**
        RiderImageCache.clearCache();

        // 3. แจ้งเตือน (Snackbar)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('สิ้นสุดงานจัดส่งสำเร็จ! ✅ ID: ${order.orderId}'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );

          // 4. **นำทางกลับไปหน้าหลัก (หน้ารับงาน)**
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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = DeliveryStatusScreen.primaryColor;
    const Color secondaryColor = DeliveryStatusScreen.secondaryColor;

=======
  Widget build(BuildContext context) {
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
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
<<<<<<< HEAD
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

          // [CORE LOGIC] ตรวจสอบงานที่กำลังดำเนินการ (จาก Stream หรือ Constructor)
          final Order? currentOrder = snapshot.data ?? widget.acceptedOrder;

          // [ADDED] อัปเดตตัวแปร State ด้วย Order ล่าสุดจาก Stream
          _currentOrderFromStream = currentOrder;

          if (currentOrder == null) {
            // [STATE 1: ไม่ได้กดรับงาน / งานเสร็จแล้ว]

            // ************************************************************
            // [การแก้ไข: ล้าง Static Cache เมื่อไม่มีงานในระบบ]
            // ************************************************************
            if (RiderImageCache.deliveryImage != null ||
                RiderImageCache.successImage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    RiderImageCache.clearCache(); // ล้างรูปภาพเก่าทันที
                  });
                }
              });
            }
            // ************************************************************

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
                // [MODIFIED] เรียกใช้ _buildMapSection เพื่อแสดงแผนที่ Flutter Map
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
=======
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildTopGradientAndBanner(context),
            _buildMapSection(),
            _buildPhotoSections(),
            const SizedBox(height: 15),
            _buildConfirmationButton(),
            const SizedBox(height: 20),
            _buildDeliveryDetailCard(context),
            const SizedBox(height: 20),
            _buildProductInfoButton(),
            const SizedBox(height: 40),
          ],
        ),
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
      ),

      // **********************************************
      // ********* การเรียกใช้งาน Bottom Bar **********
      // **********************************************
      bottomNavigationBar: StatusBottomBar(
<<<<<<< HEAD
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
=======
  currentIndex: 1, // ✅ index ของหน้าปัจจุบัน (ข้อมูลการส่งของ)
  onItemSelected: (index) {
    if (index == 0) {
      // 🏠 กดหน้าแรก → กลับไปหน้า DeliveryHomePage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DeliveryHomePage()),
        (route) => false,
      );
    } else if (index == 2) {
      // 🚪 ออกจากระบบ → กลับไปหน้า LoginPage
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

  // -------------------------------
  // ส่วนฟังก์ชันย่อย (เหมือนเดิม)
  // -------------------------------
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af

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
    final isLine2Active = isCompleted; // เชื่อมต่อ 2 -> 3 (Active เมื่อเสร็จสิ้น)

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
            color: isFirstStepActive ? Colors.white : Colors.white.withOpacity(0.8),
          ),

          // [NEW] เส้นเชื่อมต่อ 1
          _buildConnectorLine(isActive: isLine1Active),

          // 2. กำลังเดินทาง (เปลี่ยนข้อความตามรูปภาพล่าสุด)
          _buildStepItem(
            icon: Icons.motorcycle,
            label: 'กำลังเดินทาง', // <--- แก้ไขข้อความ
            isActive: isSecondStepActive,
            color:
                isSecondStepActive ? Colors.white : Colors.white.withOpacity(0.8),
          ),

          // [NEW] เส้นเชื่อมต่อ 2
          _buildConnectorLine(isActive: isLine2Active),

          // 3. จัดส่งสินค้าสำเร็จ
          _buildStepItem(
            icon: Icons.check,
            label: 'จัดส่งสินค้าสำเร็จ',
            isActive: isThirdStepActive,
            color:
                isThirdStepActive ? Colors.white : Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  // [NEW] ฟังก์ชันสำหรับสร้างเส้นเชื่อมต่อระหว่างสถานะ
  Widget _buildConnectorLine({required bool isActive}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0), // จัดให้อยู่ในแนวเดียวกับไอคอน
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
// [MODIFIED] ฟังก์ชัน _buildMapSection (ปรับการใช้ CameraFit)
// --------------------------------------------------------------------------
  Widget _buildMapSection(Order order) {
    // 1. กำหนดพิกัดปลายทาง
    final LatLng destinationLatLng =
        (order.destinationLatitude != null && order.destinationLongitude != null)
            ? LatLng(order.destinationLatitude!, order.destinationLongitude!)
            : const LatLng(16.2082, 103.2798); // ค่าเริ่มต้น

    // 2. กำหนดพิกัดต้นทาง (ผู้ส่ง)
    final LatLng pickupLatLng =
        (order.pickupLatitude != null && order.pickupLongitude != null)
            ? LatLng(order.pickupLatitude!, order.pickupLongitude!)
            : destinationLatLng; // ใช้ปลายทางแทน ถ้าไม่มีพิกัดผู้ส่ง

    // 3. คำนวณขอบเขตแผนที่เพื่อให้แสดงทั้งสองจุดพอดี
    final LatLngBounds bounds =
        LatLngBounds.fromPoints([destinationLatLng, pickupLatLng]);

    // 4. กำหนด Marker สำหรับปลายทางและต้นทาง
    final List<Marker> markers = [
      // Marker ปลายทาง (ผู้รับ - สีแดง)
      Marker(
        point: destinationLatLng,
        width: 80,
        height: 80,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red, // สีแดงสำหรับผู้รับ (ปลายทาง)
          size: 40,
        ),
      ),
      // Marker ต้นทาง (ผู้ส่ง - สีเขียว)
      Marker(
        point: pickupLatLng,
        width: 80,
        height: 80,
        child: const Icon(
          Icons.location_on,
          color: Colors.green, // สีเขียวสำหรับผู้ส่ง (ต้นทาง)
          size: 40,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
      child: Column(
        children: [
          // 1. Map Widget (Flutter Map)
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
                  // ควบคุมการแสดงผลเริ่มต้น
                  options: MapOptions(
                    // ใช้ initialCameraFit เพื่อซูมให้เห็นขอบเขตของทั้งสองพิกัด
                    initialCameraFit: CameraFit.bounds(
                      bounds: bounds,
                      padding:
                          const EdgeInsets.all(50.0), // เพิ่ม padding รอบๆ marker
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  // Layers ของแผนที่
                  children: [
                    // Tile Layer (OpenStreetMap Standard)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      // IMPORTANT: ต้องเปลี่ยน com.example.app เป็นชื่อแพ็กเกจจริงของคุณ
                      userAgentPackageName: 'com.example.ez_deliver_tracksure',
                    ),

                    // Marker Layer (หมุดปลายทางและต้นทาง)
                    MarkerLayer(
                      markers: markers,
                    ),
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
              icon: Icons.location_pin,
              title: 'ผู้ส่ง: ${order.customerName}',
              address: order.pickupLocation,
              // ใช้ 'N/A' ตามภาพตัวอย่าง (สมมติว่าไม่มีเบอร์โทรผู้ส่งใน Model)
              phone: 'เบอร์โทร: N/A',
              iconColor: Colors.green, // สีเขียว (Pickup)
            ),
            const Divider(height: 25, thickness: 1),
            // ส่วนผู้รับ
            _buildDetailRow(
              icon: Icons.location_pin,
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
        // Icon หมุด
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
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
<<<<<<< HEAD
          _buildPhotoCard(
            label: 'ฉันรับสินค้าแล้ว',
            photoIndex: 0,
          ),
          _buildPhotoCard(
            label: 'ยืนยันการจัดส่งสินค้า',
            photoIndex: 1,
          ),
=======
          _buildPhotoCard(label: 'สถานะกำลังจัดส่ง'),
          _buildPhotoCard(label: 'สถานะจัดส่งสำเร็จ'),
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildPhotoCard({
    required String label,
    required int photoIndex,
  }) {
    // [MODIFIED] ดึงรูปภาพจาก Static Cache
    final File? imageFile = photoIndex == 0
        ? RiderImageCache.deliveryImage
        : RiderImageCache.successImage;

=======
  Widget _buildPhotoCard({required String label}) {
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Column(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF4CAF50),
                    size: 30,
                  ),
                ),
<<<<<<< HEAD
                child: imageFile == null
                    ? Center(
                        child: Container(
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
=======
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
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

<<<<<<< HEAD
  // รับ Order object เพื่อใช้ในฟังก์ชัน _confirmDelivery
  Widget _buildConfirmationButton(Order order) {
    // [ADDED] กำหนดข้อความปุ่มตามสถานะของงานและรูปภาพใน Cache
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
=======
  Widget _buildConfirmationButton() {
    return ElevatedButton(
      onPressed: () {},
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
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

<<<<<<< HEAD
=======
  Widget _buildDeliveryDetailCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.motorcycle,
                  color: Color(0xFF00ACC1),
                  size: 40,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildDetailRow(
                      context: context,
                      label: 'ผู้ส่ง: คณะวิทยาศาสตร์การเกษตร',
                      details: 'เบอร์โทร : 123 4567 7890',
                      isSender: true,
                    ),
                    const Divider(height: 15),
                    _buildDetailRow(
                      context: context,
                      label: 'ผู้รับ: หอพักพรานพลาซ่าใต้อ่าง',
                      details: 'เบอร์โทร : 123 4567 7890',
                      isSender: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required String label,
    required String details,
    required bool isSender,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on,
              color: isSender ? Colors.red : Colors.green,
              size: 18,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 23.0),
          child: Text(
            details,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
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
<<<<<<< HEAD

  // [NEW] ฟังก์ชันสำหรับแสดงข้อมูลสินค้า
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
                      const Text('รูปภาพสินค้า:'),
                      const SizedBox(height: 5),
                      // ใช้ NetworkImage สำหรับรูปภาพจาก URL
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
}
=======
}
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
