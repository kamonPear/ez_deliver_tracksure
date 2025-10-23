import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';

// 1. เปลี่ยนเป็น StatefulWidget
class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  // 2. เพิ่ม State สำหรับจัดการข้อมูล
  bool _isLoading = true;
  Map<String, dynamic>? _userData; // สำหรับ TopBar
  List<QueryDocumentSnapshot> _orders = []; // สำหรับเก็บรายการออเดอร์

  // 3. เพิ่ม initState และฟังก์ชันดึงข้อมูล
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // ฟังก์ชันสำหรับดึงทั้งข้อมูลผู้ใช้และข้อมูลออเดอร์
  Future<void> _fetchData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // ดึงข้อมูลผู้ใช้สำหรับ TopBar
      final userDocFuture = FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      // ดึงข้อมูลออเดอร์ของผู้ใช้
      // !!! หมายเหตุ: ผมสมมติว่า collection ชื่อ 'orders' และมี field 'customerId'
      // !!! คุณอาจจะต้องเปลี่ยนชื่อให้ตรงกับโครงสร้าง Firestore ของคุณ
      final ordersFuture = FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true) // เรียงจากใหม่ไปเก่า
          .get();

      // รอให้ทั้งสองอย่างเสร็จสิ้น
      final responses = await Future.wait([userDocFuture, ordersFuture]);
      
      final userDoc = responses[0] as DocumentSnapshot;
      final ordersSnapshot = responses[1] as QuerySnapshot;

      if (mounted) {
        setState(() {
          if (userDoc.exists) {
            _userData = userDoc.data() as Map<String, dynamic>?;
          }
          _orders = ordersSnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("เกิดข้อผิดพลาดในการดึงข้อมูล Products: $e");
    }
  }


  // ฟังก์ชันสำหรับจัดการการแตะที่ BottomNavigationBar
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('หน้านี้กำลังอยู่ระหว่างการพัฒนา'),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }
  
  // Widget ต่างๆ (ส่วนใหญ่คงเดิม)
  Widget _buildWideMenuButton(String imagePath, String label) {
     return Expanded( 
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 50, errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.info, size: 50, color: Colors.red);
            }), 
            const SizedBox(width: 8), 
            Flexible( 
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareMenuButton(String imagePath, String label) {
     return Expanded( 
      child: Container(
        height: 100, 
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 40, errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.info, size: 40, color: Colors.red);
            }), 
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

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
        child: Stack( 
          alignment: Alignment.center, 
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Icon(Icons.local_shipping, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Text(
                  'รายการสินค้าที่กำลังส่ง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // 4. แก้ไข _buildDeliveryItemCard ให้รับข้อมูลออเดอร์เข้ามา
  Widget _buildDeliveryItemCard(QueryDocumentSnapshot orderDoc) {
    const Color primaryColor = Color(0xFF07AA7C);
    // ดึงข้อมูลจาก document (ใช้ .data() แล้ว cast เป็น Map)
    final data = orderDoc.data() as Map<String, dynamic>;

    // ใช้ ?? '...' เพื่อกำหนดค่า default ถ้าไม่มีข้อมูล
    final pickupLocation = data['pickupLocation'] ?? 'ไม่มีข้อมูลต้นทาง';
    final senderName = data['senderName'] ?? 'ไม่มีชื่อผู้ส่ง';
    final destination = data['destination'] ?? 'ไม่มีข้อมูลปลายทาง';
    final receiverName = data['receiverName'] ?? 'ไม่มีชื่อผู้รับ';
    final logoUrl = data['logoUrl']; // อาจจะเป็น null

    return Padding(
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
                    // แสดงรูปจาก URL ถ้ามี, ถ้าไม่มีแสดง Icon
                    child: logoUrl != null
                        ? Image.network(
                            logoUrl,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.delivery_dining, color: primaryColor, size: 70),
                          )
                        : const Icon(Icons.delivery_dining, color: primaryColor, size: 70),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationRow(Icons.location_on, Colors.red, pickupLocation, senderName),
                      const SizedBox(height: 5),
                      _buildLocationRow(Icons.location_on, primaryColor, destination, receiverName),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF90EE90),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'รายละเอียด',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Icon(Icons.chevron_right, color: Colors.black, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันย่อยสำหรับแสดงแถวที่อยู่
  Widget _buildLocationRow(IconData icon, Color color, String location, String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(location, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(name, style: const TextStyle(fontSize: 14, color: Colors.black54)),
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
          // 5. แสดง TopBar แบบไดนามิก
          _isLoading
              ? Container(
                  height: 250,
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
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              : TopBar(
                  userName: _userData?['customer_name'] ?? 'ผู้ใช้',
                  profileImageUrl: _userData?['profile_image_url'],
                  userAddress: _userData?['customer_address'] ?? 'ไม่มีที่อยู่',
                ),

          // 6. ทำให้เนื้อหาส่วนที่เหลือ scroll ได้
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildShippingListCard(context),
                  const SizedBox(height: 10),

                  // 7. แสดงรายการออเดอร์แบบไดนามิก หรือแสดงข้อความถ้าไม่มีข้อมูล
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'ไม่มีประวัติการส่งสินค้า',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    // สร้าง Widget สำหรับแต่ละออเดอร์ใน List
                    Column(
                      children: _orders.map((orderDoc) => _buildDeliveryItemCard(orderDoc)).toList(),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: 1, // หน้านี้คือ index 1
        onItemSelected: (index) => _onItemTapped(context, index),
      ),
    );
  }
}
<<<<<<< HEAD

//#ควายยยยยยยยยยยยยยยยยยยยยยยย
=======
>>>>>>> 91169f95046f0773c14f544c7671afd93acf04df
