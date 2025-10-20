import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 

// **[NEW]** เพิ่ม Firebase Imports ที่จำเป็น
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'rider_bottom_bar.dart'; 
import 'rider_home.dart';
import 'package:ez_deliver_tracksure/pages/login.dart';

// ----------------------
// Order Model (จำเป็นต้องมีในไฟล์นี้)
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
    this.status = 'pending',
  });
  
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Order data is null for document ${doc.id}");
    
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
      status: data['status'] ?? 'pending',
    );
  }
}

// ----------------------
// 1. DeliveryStatusScreen (รับ Order object)
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
  File? _deliveryImage; 
  File? _successImage; 

  // **[NEW]** Stream สำหรับดึงงานที่ไรเดอร์ปัจจุบันรับอยู่
  Stream<Order?> _fetchOngoingOrderStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);
    
    return FirebaseFirestore.instance
        .collection('orders')
        .where('riderId', isEqualTo: user.uid)
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
  
  // 3. ฟังก์ชันสำหรับเลือกรูปภาพจาก Camera หรือ Gallery
  Future<void> _pickImage(ImageSource source, int photoIndex) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        final newImage = File(pickedFile.path);
        if (photoIndex == 0) {
          _deliveryImage = newImage;
        } else if (photoIndex == 1) {
          _successImage = newImage;
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

  // **[NEW FUNCTION]** ฟังก์ชันยืนยันการจัดส่ง
  Future<void> _confirmDelivery(Order order) async {
    if (_deliveryImage == null || _successImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มรูปภาพให้ครบทั้ง 2 สถานะ'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // 1. ลบเอกสาร Order ออกจาก Firestore (ถือว่าจัดส่งสำเร็จ)
      await FirebaseFirestore.instance.collection('orders').doc(order.orderId).delete();

      // 2. แจ้งเตือน (Snackbar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('จัดส่งสินค้าสำเร็จและลบงานออกแล้ว! ✅ ID: ${order.orderId}'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // 3. นำทางกลับไปหน้าหลัก (หน้ารับงาน)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DeliveryHomePage()),
          (route) => false,
        );
        
        // 4. **[SIMULATED NOTIFICATION]** แจ้งเตือนผู้ส่ง/ผู้รับ (Log)
        print("--- NOTIFICATION SIMULATED ---");
        print("Notification Sent: Order ${order.orderId} delivered (deleted from active list).");
      }
    } catch (e) {
      print("Error confirming delivery: $e");
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

          // **[CORE LOGIC]** ตรวจสอบงานที่กำลังดำเนินการ (จาก Stream หรือ Constructor)
          final Order? currentOrder = snapshot.data ?? widget.acceptedOrder; 

          if (currentOrder == null) {
            // **[STATE 1: ไม่ได้กดรับงาน / งานเสร็จแล้ว]**
            // ไม่แสดงข้อมูลที่อยู่ใดๆ เลย
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

          // **[STATE 2: งานถูกรับแล้ว (currentOrder != null)]**
          // ข้อมูลที่อยู่ ผู้ส่ง-ผู้รับ และเบอร์โทร จะถูกแสดงที่นี่
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _buildTopGradientAndBanner(context),
                _buildMapSection(),
                _buildPhotoSections(), 
                const SizedBox(height: 15),
                _buildConfirmationButton(currentOrder), 
                const SizedBox(height: 20),
                _buildDeliveryDetailCard(context, currentOrder), // **แสดงที่อยู่เมื่อมีงาน**
                const SizedBox(height: 20),
                _buildProductInfoButton(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
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
  // ส่วนฟังก์ชันย่อย (ใช้ข้อมูล Order ที่ถูกส่งมา)
  // -------------------------------

  Widget _buildTopGradientAndBanner(BuildContext context) {
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
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0, left: 20.0, right: 20.0),
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
          _buildStepIndicators(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStepItem(
            icon: Icons.access_time_filled,
            label: 'รอไรเดอร์รับสินค้า',
            isActive: false,
            color: Colors.white.withOpacity(0.8),
          ),
          _buildStepItem(
            icon: Icons.check_circle_outline,
            label: 'ไรเดอร์รับสินค้าแล้ว',
            isActive: true,
            color: Colors.white.withOpacity(0.8),
          ),
          _buildStepItem(
            icon: Icons.motorcycle,
            label: 'ไรเดอร์กำลังไปหาคุณ',
            isActive: true,
            color: Colors.white,
          ),
          _buildStepItem(
            icon: Icons.check,
            label: 'จัดส่งสินค้าสำเร็จ',
            isActive: false,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Flexible(
      child: Column(
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
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            'assets/map_placeholder.png',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: Text("Map Placeholder")),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildPhotoCard(
            label: 'สถานะกำลังจัดส่ง',
            photoIndex: 0,
            imageFile: _deliveryImage, 
          ),
          _buildPhotoCard(
            label: 'สถานะจัดส่งสำเร็จ',
            photoIndex: 1,
            imageFile: _successImage, 
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String label,
    required int photoIndex, 
    File? imageFile, 
  }) {
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
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF4CAF50),
                            size: 30,
                          ),
                        ),
                      )
                    : null,
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

  // **[UPDATE]** รับ Order object เพื่อใช้ในฟังก์ชัน _confirmDelivery
  Widget _buildConfirmationButton(Order order) { 
    return ElevatedButton(
      onPressed: () {
        _confirmDelivery(order); 
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF66BB6A),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      child: const Text(
        'ยืนยันการจัดส่งสินค้า',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailCard(BuildContext context, Order order) {
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
                    // **แสดงที่อยู่ผู้ส่งและเบอร์โทร**
                    _buildDetailRow(
                      context: context,
                      label: 'ผู้ส่ง: ${order.pickupLocation}', // ที่อยู่ผู้ส่ง
                      details: 'เบอร์โทร: N/A', // ไม่มีเบอร์โทรผู้ส่งใน Model, ใช้ N/A ชั่วคราว
                      isSender: true,
                    ),
                    const Divider(height: 15),
                    // **แสดงที่อยู่ผู้รับและเบอร์โทร**
                    _buildDetailRow(
                      context: context,
                      label: 'ผู้รับ: ${order.destination}', // ที่อยู่ผู้รับ
                      details: 'เบอร์โทร: ${order.receiverPhone}', // เบอร์โทรผู้รับ
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
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () {},
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
}