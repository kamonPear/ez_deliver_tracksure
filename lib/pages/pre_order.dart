import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';

// เปลี่ยนชื่อ Class ให้ตรงกับไฟล์
class PreOrder extends StatefulWidget {
  const PreOrder({Key? key}) : super(key: key);

  @override
  State<PreOrder> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends State<PreOrder> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // กำหนดสีหลัก
  static const Color primaryGreen = Color(0xFF00C853);
  static const Color accentColor = Color(0xFF42A5F5);
  // BottomBar index ของหน้านี้ (สมมติว่าเป็นหน้าที่ถูกเรียกมา ไม่ใช่หน้าหลัก)
  static const int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (mounted) {
        if (docSnapshot.exists) {
          setState(() {
            _userData = docSnapshot.data();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error fetching user data: $e");
    }
  }

  // ***************************************************************
  // *********************** HELPER WIDGETS ************************
  // ***************************************************************

  // การ์ดข้อมูลผู้ส่ง (แสดงข้อมูลจาก _userData)
  Widget _buildSenderInfoCard(Map<String, dynamic>? userData) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปโปรไฟล์
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (userData?['profile_image_url'] != null &&
                      userData!['profile_image_url'].isNotEmpty)
                  ? NetworkImage(userData['profile_image_url'])
                  : null,
              child: (userData?['profile_image_url'] == null ||
                      userData!['profile_image_url'].isEmpty)
                  ? const Icon(Icons.person, color: primaryGreen)
                  : null,
            ),
            const SizedBox(width: 15),

            // รายละเอียด
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ชื่อ : ${userData?['customer_name'] ?? '...'}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('เบอร์โทร : ${userData?['customer_phone'] ?? '...'}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('ที่อยู่ : ${userData?['customer_address'] ?? '...'}',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // โค้ดส่วน Helper Widgets อื่นๆ เหมือนเดิม
  Widget _buildActionButton(
      {required String text,
      required Color color,
      required VoidCallback onPressed}) {
    return Center(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 0,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageAndActionSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.inventory_2_outlined,
                size: 80, color: Color(0xFFD3A867)),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSmallActionButton(
              icon: Icons.add_circle_outline,
              text: 'อัปโหลดรูปสินค้า',
              onPressed: () {
                debugPrint('อัปโหลดรูปสินค้า clicked');
              },
            ),
            const SizedBox(width: 15),
            _buildSmallActionButton(
              icon: Icons.camera_alt_outlined,
              text: 'ถ่ายรูปสินค้า',
              onPressed: () {
                debugPrint('ถ่ายรูปสินค้า clicked');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallActionButton(
      {required IconData icon,
      required String text,
      required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          backgroundColor: primaryGreen,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildDescriptionTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: accentColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const TextField(
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'รายละเอียดสินค้า',
          hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
          contentPadding: EdgeInsets.all(15.0),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ใช้ AppBar เพื่อให้มีปุ่ม Back กลับไปหน้า Home อัตโนมัติ
      appBar: AppBar(
        title: const Text('ส่งสินค้า'),
        backgroundColor: const Color(0xFF07AA7C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 15),
            _buildSenderInfoCard(_userData),
            const SizedBox(height: 20),
            _buildActionButton(
              text: 'แนบข้อมูลสินค้าที่จะจัดส่ง',
              color: primaryGreen,
              onPressed: () {
                debugPrint('แนบข้อมูลสินค้า clicked');
              },
            ),
            const SizedBox(height: 25),
            _buildImageAndActionSection(),
            const SizedBox(height: 20),
            const Text(
              'รายละเอียดสินค้า :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            _buildDescriptionTextField(),
            const SizedBox(height: 30),
            _buildActionButton(
              text: 'เพิ่มข้อมูลสินค้า',
              color: primaryGreen,
              onPressed: () {
                debugPrint('เพิ่มข้อมูลสินค้า clicked');
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      // BottomBar อาจจะไม่จำเป็นในหน้านี้ แต่ใส่ไว้ตามโค้ดเดิม
      bottomNavigationBar: BottomBar(
        currentIndex: currentIndex,
        onItemSelected: (index) {
          if (index == 0) {
            // ถ้ากดหน้าแรก ก็กลับไป
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }
}

