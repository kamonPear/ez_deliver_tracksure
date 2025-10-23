import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/pages/EditPro.dart';
import 'package:ez_deliver_tracksure/pages/all.dart'; // Import HomeScreen
// --- เพิ่ม Import สำหรับ ProductStatus ---
import 'package:ez_deliver_tracksure/pages/product_status.dart';
// ------------------------------------
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';
// ไม่จำเป็นต้อง import login.dart ที่นี่
// import 'login.dart';
// import 'products.dart'; // ไม่ต้อง import ตัวเอง

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
  int _selectedIndex = 1; // <--- แก้ไข: ตั้งค่า index เริ่มต้นให้ถูกต้อง (หน้าประวัติคือ 1)
  // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

  bool _isLoading = true;
  Map<String, dynamic>? _userData; // สำหรับ TopBar
  List<QueryDocumentSnapshot> _completedOrders = []; // <--- เปลี่ยนชื่อตัวแปร

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // ตั้งค่า isLoading เป็น true ก่อนเริ่มดึงข้อมูล
    if (mounted) setState(() => _isLoading = true);


    try {
      // ดึงข้อมูล User (เหมือนเดิม)
      final userDocFuture = FirebaseFirestore.instance.collection('customers').doc(user.uid).get();

      // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
      // ดึง Orders เฉพาะที่เสร็จแล้ว ('completed' หรือ 'delivered')
      final ordersFuture = FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: user.uid)
          // --- เพิ่มเงื่อนไข Status ---
          .where('status', whereIn: ['completed', 'delivered']) // <-- กรองสถานะที่นี่
          // --------------------------
          .orderBy('createdAt', descending: true)
          .get();
      // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

      final responses = await Future.wait([userDocFuture, ordersFuture]);
      final userDoc = responses[0] as DocumentSnapshot;
      final ordersSnapshot = responses[1] as QuerySnapshot;

      if (mounted) {
        setState(() {
          if (userDoc.exists) {
            _userData = userDoc.data() as Map<String, dynamic>?;
          } else {
            // ลองหาใน riders ถ้าไม่เจอใน customers (เผื่อกรณีไรเดอร์ดูประวัติตัวเอง)
            FirebaseFirestore.instance.collection('riders').doc(user.uid).get().then((riderDoc) {
               if (mounted && riderDoc.exists) {
                 setState(() {
                    _userData = riderDoc.data() as Map<String, dynamic>?;
                 });
               } else {
                  _userData = null;
                   print('User document not found in customers or riders for UID: ${user.uid}');
               }
            });
          }
          _completedOrders = ordersSnapshot.docs; // <--- ใช้ตัวแปรใหม่
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("🚨 Error fetching completed orders: $e");
    }
  }

  // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
  // แก้ไข Logic การนำทางให้เหมือนหน้าอื่นๆ
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    switch (index) {
      case 0:
        // ถ้ากดปุ่ม Home (index 0) ให้แทนที่ด้วย HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        // ถ้ากดปุ่ม ประวัติ (index 1) ซึ่งคือหน้าปัจจุบัน ไม่ต้องทำอะไร
        break;
      case 2:
        // ถ้ากดปุ่ม อื่นๆ (index 2) ให้แทนที่ด้วย EditPro
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EditPro()),
        );
        break;
    }
  }
  // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲


  // --- WIDGETS สำหรับแสดงผล ---

  Widget _buildShippingListCard(BuildContext context) {
    // ปรับข้อความหัวข้อเล็กน้อย
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        decoration: BoxDecoration(
          color: const Color(0xFF074F77), // อาจจะเปลี่ยนสีให้เข้ากับประวัติ? เช่น สีเทาเข้ม
          borderRadius: BorderRadius.circular(15),
          boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4), ), ],
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, color: Colors.white, size: 30), // เปลี่ยนไอคอนเป็น history
                SizedBox(width: 12),
                Text(
                  'ประวัติการส่งสำเร็จ', // เปลี่ยนข้อความ
                  style: TextStyle( color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, ),
                ),
              ],
            ),
            // อาจจะไม่ต้องมีลูกศรชี้ขวาแล้ว เพราะนี่คือรายการประวัติ
            // Align( alignment: Alignment.centerRight, child: Icon( Icons.arrow_forward_ios, color: Colors.white, size: 20, ), ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryItemCard(QueryDocumentSnapshot orderDoc) {
    const Color primaryColor = Color(0xFF07AA7C);
    final data = orderDoc.data() as Map<String, dynamic>;
    final orderId = orderDoc.id; // <-- ดึง ID ของเอกสาร

    // --- ตรวจสอบชื่อ Field ให้ตรงกับ Firestore ---
    final pickupLocation = data['pickupLocation'] ?? 'ไม่มีข้อมูลต้นทาง';
    // ชื่อผู้ส่งน่าจะอยู่ใน customerName
    final senderName = data['customerName'] ?? _userData?['customer_name'] ?? 'ไม่มีชื่อผู้ส่ง';
    final destination = data['destination'] ?? 'ไม่มีข้อมูลปลายทาง';
    final receiverName = data['receiverName'] ?? 'ไม่มีชื่อผู้รับ';
    // รูปสินค้าน่าจะอยู่ใน productImageUrl
    final productImageUrl = data['productImageUrl'];
    final Timestamp? createdAt = data['createdAt'] as Timestamp?; // ดึงเวลาสร้าง
    // ------------------------------------------


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // ลด Vertical Padding
      child: InkWell( // <--- หุ้มด้วย InkWell เพื่อให้กดได้
        onTap: () {
          // --- Navigate ไปหน้า ProductStatus เมื่อกด ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductStatus(orderId: orderId),
            ),
          );
          // ------------------------------------------
        },
        borderRadius: BorderRadius.circular(15), // ทำให้ InkWell มีมุมโค้ง
        child: Container(
          padding: const EdgeInsets.all(12.0), // เพิ่ม Padding ภายในเล็กน้อย
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2), ), ], // ลดเงาเล็กน้อย
          ),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start, // <-- จัดชิดซ้ายบน
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- แสดงรูปสินค้า ---
                  Container(
                     width: 80, // ปรับขนาดรูปให้เล็กลง
                     height: 80,
                     margin: const EdgeInsets.only(right: 12.0),
                     decoration: BoxDecoration( // เพิ่มกรอบและมุมโค้งให้รูป
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade200, width: 1.0)
                     ),
                     child: ClipRRect( // ตัดรูปให้โค้งตามกรอบ
                       borderRadius: BorderRadius.circular(8.0),
                       child: productImageUrl != null && productImageUrl.isNotEmpty
                           ? Image.network(
                               productImageUrl,
                               fit: BoxFit.cover, // ให้รูปเต็มกรอบ
                               errorBuilder: (context, error, stackTrace) => const Center(child: Icon( Icons.broken_image, color: Colors.grey, size: 40,)),
                               loadingBuilder:(context, child, loadingProgress) {
                                   if (loadingProgress == null) return child;
                                   return Center(child: CircularProgressIndicator( value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, strokeWidth: 2.0,));
                               },
                             )
                           : const Center(child: Icon( Icons.inventory_2_outlined, color: Colors.grey, size: 40,)), // Icon ถ้าไม่มีรูป
                     ),
                   ),
                  // ---------------------
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // --- แสดงเวลาที่สร้าง (ถ้ามี) ---
                         if (createdAt != null)
                           Text(
                             // จัดรูปแบบวันที่เวลาให้อ่านง่ายขึ้น (ต้อง import intl package)
                             // '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year} ${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}',
                              'วันที่สั่ง: ${createdAt.toDate().toString().substring(0, 16)}', // แบบง่าย
                             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                           ),
                         if (createdAt != null) const SizedBox(height: 5), // ระยะห่าง
                         // ------------------------------
                        _buildLocationRow( Icons.storefront, Colors.blueGrey, pickupLocation, senderName, "จาก: "),
                        const SizedBox(height: 8),
                        _buildLocationRow( Icons.person_pin_circle, primaryColor, destination, receiverName, "ถึง: "),
                      ],
                    ),
                  ),
                ],
              ),
              // --- ย้ายปุ่ม "รายละเอียด" มาไว้ตรงนี้ ---
              Align(
                alignment: Alignment.bottomRight,
                child: Padding( // เพิ่ม Padding รอบๆ ปุ่ม
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton.icon( // เปลี่ยนเป็น TextButton.icon
                    icon: const Icon(Icons.info_outline, size: 18, color: primaryColor),
                    label: const Text( 'ดูรายละเอียด', style: TextStyle( color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14, ), ),
                    onPressed: () {
                         Navigator.push( context, MaterialPageRoute( builder: (context) => ProductStatus(orderId: orderId), ), );
                    },
                    style: TextButton.styleFrom(
                       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // ปรับ padding ปุ่ม
                       tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ลดขนาดพื้นที่กด
                       visualDensity: VisualDensity.compact // ทำให้ปุ่มแน่นขึ้น
                    ),
                  ),
                ),
              ),
              // --------------------------------------
            ],
          ),
        ),
      ),
    );
  }

  // ปรับ Widget นี้เล็กน้อย เพิ่ม prefix
 Widget _buildLocationRow( IconData icon, Color color, String location, String name, String prefix) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18), // ลดขนาดไอคอน
        const SizedBox(width: 8),
        Expanded( // ใช้ Expanded แทน Flexible
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText( // ใช้ RichText เพื่อผสมข้อความ
                 maxLines: 1, // จำกัด 1 บรรทัด
                 overflow: TextOverflow.ellipsis, // ถ้าเกินให้แสดง ...
                 text: TextSpan(
                   style: TextStyle(fontSize: 14, color: Colors.black87), // Style เริ่มต้น
                   children: <TextSpan>[
                     TextSpan(text: prefix, style: TextStyle(color: Colors.grey.shade700)), // ใส่ prefix
                     TextSpan(text: name, style: TextStyle(fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
              const SizedBox(height: 2),
              Text(
                location,
                maxLines: 2, // จำกัด 2 บรรทัด
                overflow: TextOverflow.ellipsis, // ถ้าเกินให้แสดง ...
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column( // ใช้ Column ครอบทั้งหมด
        children: [
          // ส่วน TopBar
          _isLoading
              ? Container( /* ... Loading Indicator เหมือนเดิม ... */
                 height: 250, width: double.infinity,
                 decoration: const BoxDecoration( gradient: LinearGradient( colors: [Color(0xFF07AA7C), Color(0xFF11598D)], begin: Alignment.topLeft, end: Alignment.bottomRight, ), borderRadius: BorderRadius.only( bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20), ), ),
                 child: const Center( child: CircularProgressIndicator(color: Colors.white), ),
               )
              : TopBar( /* ... User Info เหมือนเดิม ... */
                 userName: _userData?['customer_name'] ?? _userData?['rider_name'] ?? 'ผู้ใช้',
                 profileImageUrl: _userData?['profile_image_url'],
                 userAddress: _userData?['customer_address'] ?? 'ไม่มีข้อมูล',
               ),

          // ส่วนเนื้อหาที่ scroll ได้
          Expanded( // ทำให้ ListView ขยายเต็มพื้นที่ที่เหลือ
            child: _isLoading // เช็ค Loading ตรงนี้
                ? const Center(child: CircularProgressIndicator())
                : _completedOrders.isEmpty // เช็คว่ามีข้อมูลหรือไม่
                    ? Center( // แสดงข้อความถ้าไม่มีข้อมูล
                        child: Text(
                          'ไม่มีประวัติการส่งสินค้าที่เสร็จสมบูรณ์',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView( // ใช้ ListView แทน SingleChildScrollView+Column
                        padding: EdgeInsets.zero, // เอา Padding เริ่มต้นของ ListView ออก
                        children: [
                          const SizedBox(height: 16),
                          _buildShippingListCard(context), // แสดงหัวข้อ
                          const SizedBox(height: 8), // ลดระยะห่าง
                          // สร้างรายการ Card จาก _completedOrders โดยตรง
                          ..._completedOrders.map((orderDoc) => _buildDeliveryItemCard(orderDoc)).toList(),
                          const SizedBox(height: 16), // Padding ด้านล่าง
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex, // ใช้ state variable ที่ถูกต้อง
        onItemSelected: _onItemTapped,
      ),
    );
  }
}