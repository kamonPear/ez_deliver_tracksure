import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/pages/EditPro.dart';
import 'package:ez_deliver_tracksure/pages/all.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';

// ▼▼▼ [แก้ไข] ▼▼▼
// Import หน้า ProductStatus เพื่อให้เรากดลิงก์ไปได้
import 'product_status.dart'; // <-- ตรวจสอบว่าชื่อไฟล์ถูกต้อง (product_status.dart)
// ▲▲▲ [แก้ไข] ▲▲▲

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  // ▼▼▼ [แก้ไข] ▼▼▼
  // เราจะตั้งค่า selectedIndex เป็น 1 เพราะหน้านี้คือ "ประวัติ" (ปุ่มที่ 2)
  int _selectedIndex = 1;
  // ▲▲▲ [แก้ไข] ▲▲▲

  bool _isLoading = true;
  Map<String, dynamic>? _userData; // สำหรับ TopBar
  List<QueryDocumentSnapshot> _orders = []; // สำหรับเก็บรายการออเดอร์

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    User? user = FirebaseAuth.instance.currentUser;

    print('--- DEBUGGING ---');
    print('Current User UID from Auth: ${user?.uid}');
    print('-----------------');

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userDocFuture =
          FirebaseFirestore.instance.collection('customers').doc(user.uid).get();

      // ▼▼▼ [แก้ไข] ▼▼▼
      // นี่คือจุดสำคัญ: เราเพิ่ม .where('status', whereIn: ['completed', 'delivered'])
      // เพื่อกรองเอาเฉพาะออเดอร์ที่ "ส่งสำเร็จ" แล้วเท่านั้น
      final ordersFuture = FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: user.uid)
          .where('status', whereIn: ['completed', 'delivered']) // <-- กรองสถานะที่นี่
          .orderBy('createdAt', descending: true)
          .get();
      // ▲▲▲ [แก้ไข] ▲▲▲

      final responses = await Future.wait([userDocFuture, ordersFuture]);
      final userDoc = responses[0] as DocumentSnapshot;
      final ordersSnapshot = responses[1] as QuerySnapshot;

      if (mounted) {
        setState(() {
          if (userDoc.exists) {
            _userData = userDoc.data() as Map<String, dynamic>?;
            print('✅ SUCCESS: Found document! Data is: $_userData');
          } else {
            print(
                '❌ ERROR: Document with ID "${user.uid}" was NOT FOUND in "customers" collection.');
            _userData = null;
          }
          _orders = ordersSnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // พิมพ์ Error เพื่อให้เห็นใน Console (สำคัญมากสำหรับการแก้ไขปัญหา Index)
      print("🚨 เกิดข้อผิดพลาดในการดึงข้อมูล Products: $e");

      // ▼▼▼ [แจ้งเตือน] ▼▼▼
      // หากเกิด Error ที่นี่ ส่วนใหญ่มักเกิดจาก Firestore Index
      // ให้ดูใน Console ตอนรันแอป จะมีลิงก์สำหรับสร้าง Index ให้ครับ
      // ▲▲▲ [แจ้งเตือน] ▲▲▲
    }
  }

  void _onItemTapped(int index) {
    // If the tapped item is the current one, do nothing.
    if (_selectedIndex == index) return;

    // ▼▼▼ [แก้ไข] ▼▼▼
    // เปลี่ยน _selectedIndex ที่นี่ด้วย
    setState(() {
      _selectedIndex = index;
    });
    // ▲▲▲ [แก้ไข] ▲▲▲

    switch (index) {
      case 0:
        Navigator.pushReplacement( // ใช้ pushReplacement เพื่อไม่ให้ย้อนกลับมาซ้ำ
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        // หน้านี้อยู่แล้ว ไม่ต้องทำอะไร (หรือจะ refresh ก็ได้)
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const Products()),
        // );
        break;
      case 2:
        Navigator.pushReplacement( // ใช้ pushReplacement
          context,
          MaterialPageRoute(builder: (context) => const EditPro()),
        );
        break;
    }
  }

  // --- WIDGETS สำหรับแสดงผล ---

  Widget _buildShippingListCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        decoration: BoxDecoration(
          color: const Color(0xFF074F77),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ▼▼▼ [แก้ไข] ▼▼▼
        // เปลี่ยน Icon และ ข้อความ ให้สื่อว่าเป็น "ประวัติ"
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, color: Colors.white, size: 30), // <-- เปลี่ยน Icon
                SizedBox(width: 12),
                Text(
                  'ประวัติการส่งสำเร็จ', // <-- เปลี่ยนข้อความ
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
        // ▲▲▲ [แก้ไข] ▲▲▲
      ),
    );
  }

  Widget _buildDeliveryItemCard(QueryDocumentSnapshot orderDoc) {
    const Color primaryColor = Color(0xFF07AA7C);
    final data = orderDoc.data() as Map<String, dynamic>;

    final pickupLocation = data['pickupLocation'] ?? 'ไม่มีข้อมูลต้นทาง';
    final senderName = data['senderName'] ?? 'ไม่มีชื่อผู้ส่ง';
    final destination = data['destination'] ?? 'ไม่มีข้อมูลปลายทาง';
    final receiverName = data['receiverName'] ?? 'ไม่มีชื่อผู้รับ';
    final logoUrl = data['logoUrl'];

    // ▼▼▼ [แก้ไข] ▼▼▼
    // ห่อทั้ง Card ด้วย InkWell เพื่อให้กดได้
    return InkWell(
      onTap: () {
        // สั่งให้ Navigator ไปยังหน้า ProductStatus
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductStatus(orderId: orderDoc.id),
          ),
        );
      },
      child: Padding(
        // ▲▲▲ [แก้ไข] ▲▲▲
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.only(right: 15.0),
                    child: Center(
                      child: logoUrl != null
                          ? Image.network(
                              logoUrl,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.delivery_dining,
                                color: primaryColor,
                                size: 70,
                              ),
                            )
                          : const Icon(
                              Icons.delivery_dining,
                              color: primaryColor,
                              size: 70,
                            ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationRow(
                          Icons.location_on,
                          Colors.red,
                          pickupLocation,
                          senderName,
                        ),
                        const SizedBox(height: 5),
                        _buildLocationRow(
                          Icons.location_on,
                          primaryColor,
                          destination,
                          receiverName, // <-- นี่คือผู้รับที่คุณต้องการ
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ▼▼▼ [แก้ไข] ▼▼▼
              // เปลี่ยนปุ่ม "รายละเอียด" เป็น Badge "ส่งสำเร็จ"
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF90EE90), // สีเขียวอ่อน (Light Green)
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.black, size: 18), // Icon สำเร็จ
                      SizedBox(width: 8),
                      Text(
                        'ส่งสำเร็จ', // <-- เปลี่ยนข้อความ
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ▲▲▲ [แก้ไข] ▲▲▲
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, Color color, String location, String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2, // กันข้อความยาวเกิน
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                name,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
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
      body: Column(
        children: [
          // ส่วน TopBar
          _isLoading
              ? Container(
                  height: 250, // ปรับความสูงให้เหมาะสม (ถ้า TopBar สูงเท่านี้)
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF07AA7C), Color(0xFF11598D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : TopBar(
                  userName: _userData?['customer_name'] ?? 'ผู้ใช้',
                  profileImageUrl: _userData?['profile_image_url'],
                  userAddress:
                      _userData?['customer_address'] ?? 'ไม่มีที่อยู่',
                ),

          // ส่วนเนื้อหาที่ scroll ได้
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // --- ส่วนที่ 1: แสดงรายการส่งของ (Orders) ---
                  _buildShippingListCard(context),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_orders.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('ไม่มีประวัติการส่งสินค้า',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ))
                  else
                    Column(
                      // สร้าง Card จาก List ที่ดึงมา
                      children: _orders
                          .map((orderDoc) => _buildDeliveryItemCard(orderDoc))
                          .toList(),
                    ),

                  const SizedBox(height: 20), // Padding ด้านล่างสุด
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}

//#ควายยยยยยยยยยยยยยยยยยยยยยยย