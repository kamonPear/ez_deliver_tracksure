import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'products.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // <--- 1. ย้ายฟังก์ชันทั้งหมดออกมาให้อยู่ในระดับของ Class ครับ

  @override
  void initState() {
    super.initState();
    // เรียกใช้ฟังก์ชันดึงข้อมูลตอนที่ Widget ถูกสร้างครั้งแรกเท่านั้น
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // อาจจะดีกว่าถ้าส่งผู้ใช้กลับไปหน้า login หากไม่มี user
      setState(() => _isLoading = false);
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (mounted) { // เช็คว่า widget ยังอยู่บนหน้าจอก่อนเรียก setState
        if (docSnapshot.exists) {
          setState(() {
            _userData = docSnapshot.data();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          print("ไม่พบข้อมูลผู้ใช้ใน Firestore สำหรับ UID: ${user.uid}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("เกิดข้อผิดพลาดในการดึงข้อมูล: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // ไม่ต้องทำอะไร เพราะนี่คือหน้า HomeScreen อยู่แล้ว
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Products()),
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('หน้านี้ยังไม่พร้อมใช้งาน')),
        );
        break;
    }
  }

  // ฟังก์ชันสร้างปุ่มเมนูต่างๆ (โค้ดเดิมของคุณ)
  Widget _buildWideMenuButton(String imagePath, String label) {
    return Container(
      width: 180,
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
          Image.asset(imagePath, height: 50),
          const SizedBox(width: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareMenuButton(String imagePath, String label) {
    return Container(
      width: 118,
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
          Image.asset(imagePath, height: 40),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // <--- 2. แก้ไขการเรียกใช้ TopBar ตรงนี้
            _isLoading
                ? Container(
                    // สร้าง Container ที่มีขนาดเท่า TopBar เพื่อไม่ให้หน้าจอกระพริบตอนโหลด
                    height: 250, // ปรับความสูงให้ใกล้เคียงกับ TopBar ของคุณ
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
                    // ส่งข้อมูลที่ดึงมาได้ไปให้ TopBar
                    userName: _userData?['customer_name'] ?? 'ผู้ใช้',
                    profileImageUrl: _userData?['profile_image_url'],
                    userAddress: _userData?['customer_address'] ?? 'ไม่มีที่อยู่',
                  ),

            // ส่วนที่ 2: เมนูหลัก
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWideMenuButton(
                        'assets/image/order.png',
                        'สั่งสินค้า',
                      ),
                      const SizedBox(width: 10),
                      _buildWideMenuButton(
                        'assets/image/order2.png',
                        'สถานะพัสดุ',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSquareMenuButton(
                        'assets/image/order3.png',
                        'พัสดุที่ต้องรับ',
                      ),
                      const SizedBox(width: 10),
                      _buildSquareMenuButton(
                        'assets/image/order4.png',
                        'คุยกับไรเดอร์',
                      ),
                      const SizedBox(width: 10),
                      _buildSquareMenuButton(
                        'assets/image/order5.png',
                        'แพ็กเกจ',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ส่วนที่ 3: แบนเนอร์โปรโมชัน (เหมือนเดิม)
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
                      textAlign:
                          TextAlign.center,
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
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }

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
}
