import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/pages/EditPro.dart';
import 'package:ez_deliver_tracksure/pages/order_list_page.dart';
import 'package:ez_deliver_tracksure/pages/pre_order.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ez_deliver_tracksure/pages/received.dart';
// ตรวจสอบการ Import!

import 'products.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State & Data Variables
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // 💡 สมมติว่านี่คือ Order ID ที่ต้องการใช้เมื่อกดปุ่ม "สถานะพัสดุที่ต้องรับ"
  // **คุณต้องเปลี่ยนเป็น orderId จริงที่ได้จากการจัดการสถานะออเดอร์ในแอปของคุณ**
  final String _testOrderId = 'ORDER_123456';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // ----------------------------------------------------------
  // MARK: - Data Fetching
  // ----------------------------------------------------------

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Check 'customers' collection
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      // 2. If not found, check 'riders' collection
      if (!docSnapshot.exists) {
        docSnapshot = await FirebaseFirestore.instance
            .collection('riders')
            .doc(user.uid)
            .get();
      }

      if (mounted) {
        if (docSnapshot.exists) {
          setState(() {
            _userData = docSnapshot.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          // print("User document not found for UID: ${user.uid}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      // print("Error fetching user data: $e");
    }
  }

  // ----------------------------------------------------------
  // MARK: - Navigation Logic
  // ----------------------------------------------------------

  // Logic สำหรับการเปลี่ยนหน้าจาก BottomBar
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    // เนื่องจาก HomeScreen เป็นหน้าแรกและหน้าหลักของ Index 0
    // การเปลี่ยนหน้าต้องใช้ pushReplacement เพื่อไม่ให้ซ้อนกัน
    switch (index) {
      case 0:
        // ถ้าอยู่ที่หน้าอื่น แล้วกด Home ให้แทนที่ด้วย HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        // ไปหน้า Products (หรือ OrderListPage) โดยการแทนที่
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Products(),
          ), // หรือ OrderListPage()
        );
        break;
      case 2:
        // ไปหน้า EditPro โดยการแทนที่
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EditPro()),
        );
        break;
    }
  }

  // ----------------------------------------------------------
  // MARK: - Widget Builders
  // ----------------------------------------------------------

  // ปุ่มเมนูแนวนอน (ส่งสินค้า/สถานะพัสดุ)
  Widget _buildWideMenuButton(
    String imagePath,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 100,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 50),
            const SizedBox(width: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ปุ่มเมนูสี่เหลี่ยม (พัสดุที่ต้องรับ/คุยกับไรเดอร์/แพ็กเกจ)
  Widget _buildSquareMenuButton(
    String imagePath,
    String label,
    VoidCallback? onTap, // ใช้ ? เพื่อให้เป็น null ได้ (เช่นสำหรับ "แพ็กเกจ")
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 118,
        height: 100,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 40),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget โปรโมชั่นย่อย (Promo Item) 1
  Widget _buildPromoItem(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F6F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Icon(Icons.local_shipping, color: Color(0xFF07AA7C), size: 30),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // Widget โปรโมชั่นย่อย (Promo Item) 2
  Widget _buildPromoItem2(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F6F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Icon(Icons.motorcycle, color: Color(0xFF07AA7C), size: 30),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // Widget โปรโมชั่นย่อย (Promo Item) 3
  Widget _buildPromoItem3(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F6F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Icon(Icons.archive, color: Color(0xFF07AA7C), size: 30),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // MARK: - Main Build Method
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Top Bar / Loading Indicator ---
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
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : TopBar(
                    userName:
                        _userData?['customer_name'] ??
                        _userData?['rider_name'] ??
                        'User',
                    profileImageUrl: _userData?['profile_image_url'],
                    userAddress: _userData?['customer_address'] ?? 'No address',
                  ),

            // --- Menu Buttons ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ส่งสินค้า
                      _buildWideMenuButton(
                        'assets/image/order.png',
                        'ส่งสินค้า',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PreOrderScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      // สถานะพัสดุ
                      _buildWideMenuButton(
                        'assets/image/order2.png',
                        'สถานะพัสดุ',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderListPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // พัสดุที่ต้องรับ
                      _buildSquareMenuButton(
                        'assets/image/order3.png',
                        'พัสดุที่ต้องรับ',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PendingPickupScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      // คุยกับไรเดอร์
                      _buildSquareMenuButton(
                        'assets/image/order4.png',
                        'คุยกับไรเดอร์',
                        null, // ปรับเปลี่ยนเป็น () { ... } ถ้ามีหน้าสำหรับแพ็กเกจ
                      ),
                      const SizedBox(width: 10),
                      // แพ็กเกจ
                      _buildSquareMenuButton(
                        'assets/image/order5.png',
                        'แพ็กเกจ',
                        null, // ปรับเปลี่ยนเป็น () { ... } ถ้ามีหน้าสำหรับแพ็กเกจ
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Promotion Banner ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'โปรส่งของ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 224, 167, 91),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'คุ้มสุดๆ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 202, 122, 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 22,
                          color: Color(0xFF07AA7C),
                        ),
                        children: [
                          TextSpan(
                            text: 'ส่งฟรี ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '50 บาท',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เมื่อส่งภายในระยะทางที่กำหนด',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPromoItem('ส่งฟรี!'),
                        _buildPromoItem2('โปรคุ้มค่า!'),
                        _buildPromoItem3('ถึงหน้าบ้านคุณ!'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
