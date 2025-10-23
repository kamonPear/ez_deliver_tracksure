import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/pages/all.dart'; // Import HomeScreen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';
import 'login.dart';
import 'products.dart'; // Import Products (หรือ OrderListPage)

class EditPro extends StatefulWidget {
  const EditPro({super.key});

  @override
  State<EditPro> createState() => _EditProState();
}

class _EditProState extends State<EditPro> {
  // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
  int _selectedIndex = 2; // <--- แก้ไข: ตั้งค่า index เริ่มต้นให้ถูกต้อง (หน้า "อื่นๆ" คือ 2)
  // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
  void _onItemTapped(int index) {
  if (_selectedIndex == index) return;

  // --- ไม่ต้อง setState ที่นี่แล้ว ---
  // setState(() {
  //   _selectedIndex = index;
  // });
  // ---------------------------------


  switch (index) {
    case 0:
      // ถ้าอยู่ที่หน้าอื่น แล้วกด Home ให้แทนที่ด้วย HomeScreen
      Navigator.pushReplacement( // <--- เปลี่ยน
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      break;
    case 1:
      // ไปหน้า Products โดยการแทนที่
      Navigator.pushReplacement( // <--- เปลี่ยน
        context,
        MaterialPageRoute(builder: (context) => const Products()), // หรือ OrderListPage() ถ้าจะใช้หน้านั้น
      );
      break;
    case 2:
      // ไปหน้า EditPro โดยการแทนที่
      Navigator.pushReplacement( // <--- เปลี่ยน
        context,
        MaterialPageRoute(builder: (context) => const EditPro()),
      );
      break;
  }
}
  // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // ลองค้นหาใน 'customers' ก่อน
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      // ถ้าไม่เจอใน 'customers' ให้ลองค้นหาใน 'riders'
      if (!userDoc.exists) {
        userDoc = await FirebaseFirestore.instance
            .collection('riders')
            .doc(user.uid)
            .get();
      }

      if (mounted) {
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
           print("User document not found for UID: ${user.uid}"); // เพิ่ม print log
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error fetching user data: $e");
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // ใช้ pushAndRemoveUntil เพื่อเคลียร์ stack การนำทางทั้งหมดก่อนไปหน้า Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildListMenuItem(
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onTapAction,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapAction,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ไม่ต้องประกาศ currentIndex ที่นี่แล้ว
    const Color primaryIconColor = Color(0xFF00B09A);
    const Color logoutIconColor = Colors.red;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column( // ใช้ Column เพื่อดัน BottomBar ลงล่างสุด
        children: [
          _isLoading
              ? Container(
                  height: 250, // กำหนดความสูงที่แน่นอนสำหรับ Loading State
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
              : TopBar( // แสดง TopBar เมื่อโหลดเสร็จ
                  userName: _userData?['customer_name'] ?? _userData?['rider_name'] ?? 'ผู้ใช้',
                  profileImageUrl: _userData?['profile_image_url'],
                  userAddress: _userData?['customer_address'] ?? 'ไม่มีข้อมูล',
                ),

          // ส่วนเมนูตั้งค่า
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                _buildListMenuItem(
                  Icons.person_outline,
                  'แก้ไขข้อมูลส่วนตัว',
                  primaryIconColor,
                  () {
                      // TODO: Implement navigation to edit profile page
                      print('แก้ไขข้อมูลส่วนตัว clicked');
                      // ตัวอย่าง: Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileActualPage()));
                    },
                ),
                _buildListMenuItem(
                  Icons.logout,
                  'ออกจากระบบ',
                  logoutIconColor,
                  _signOut,
                ),
              ],
            ),
          ),
          const Spacer(), // ดัน BottomBar ไปไว้ด้านล่างสุดของจอ
        ],
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex, // ใช้ state variable ที่ถูกต้อง
        onItemSelected: _onItemTapped,
      ),
    );
  }
}