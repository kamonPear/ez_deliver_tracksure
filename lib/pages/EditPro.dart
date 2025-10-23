import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/pages/products.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'all.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';
import 'login.dart'; // <-- 1. IMPORT หน้า Login สำหรับการ Logout

// ------------------------------------------------------------------
// 2. เปลี่ยนจาก StatelessWidget เป็น StatefulWidget
// ------------------------------------------------------------------
class EditPro extends StatefulWidget {
  const EditPro({super.key});

  @override
  State<EditPro> createState() => _EditProState();
}

class _EditProState extends State<EditPro> {
  // 3. เพิ่ม State สำหรับจัดการการโหลดและเก็บข้อมูลผู้ใช้

    int _selectedIndex = 2;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // 4. เพิ่ม initState และฟังก์ชันดึงข้อมูล (เหมือนกับ HomeScreen)
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
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

  // 🚀🚀🚀 THE FIX IS HERE 🚀🚀🚀
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
          MaterialPageRoute(builder: (context) => const HomeScreen()), // ตรวจสอบว่า HomeScreen มาจาก 'all.dart'
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


  // 5. เพิ่มฟังก์ชันสำหรับ Sign Out
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // กลับไปหน้า Login และลบหน้าทั้งหมดที่เคยเปิดมาก่อนหน้า
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // ▼▼▼▼▼▼ [ CODE ที่ลบ ] ▼▼▼▼▼▼
  // ลบฟังก์ชัน _buildWideMenuButton() และ _buildSquareMenuButton()
  // เพราะไม่ได้ใช้งานแล้ว
  // ▲▲▲▲▲▲ [ CODE ที่ลบ ] ▲▲▲▲▲▲


  // ฟังก์ชันนี้ยังเก็บไว้ เพราะปุ่ม Logout ใช้งาน
  Widget _buildListMenuItem(IconData icon, String title, Color iconColor, VoidCallback onTapAction) {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
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
                Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
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
    // const int currentIndex = 2; // <-- ไม่ได้ใช้แล้ว เพราะเรามี _selectedIndex
    // const Color primaryIconColor = Color(0xFF00B09A); // <-- ไม่ได้ใช้แล้ว
    const Color logoutIconColor = Colors.red;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 6. เปลี่ยนการเรียกใช้ TopBar ให้เป็นแบบไดนามิก
            _isLoading
                ? Container(
                    height: 250, // ความสูงเท่า TopBar
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
                    userAddress: _userData?['customer_address'] ?? 'ไม่มีที่อยู่',
                  ),

            // ▼▼▼▼▼▼ [ CODE ที่ลบ ] ▼▼▼▼▼▼
            // ลบ Padding ที่ครอบปุ่ม 2 แถวบนออกทั้งหมด
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Column(
            //     children: [
            //       Row( ... ),
            //       const SizedBox(height: 10),
            //       Row( ... ),
            //     ],
            //   ),
            // ),
            // ▲▲▲▲▲▲ [ CODE ที่ลบ ] ▲▲▲▲▲▲


            // ส่วนตั้งค่าโปรไฟล์
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // <-- เพิ่ม Vartical Padding
              child: Column(
                children: [
                  // ▼▼▼▼▼▼ [ CODE ที่ลบ ] ▼▼▼▼▼▼
                  // _buildListMenuItem(
                  //   Icons.person_outline,
                  //   'แก้ไขข้อมูลส่วนตัว',
                  //   primaryIconColor,
                  //   () => print('แก้ไขข้อมูลส่วนตัว clicked'),
                  // ),
                  // _buildListMenuItem(
                  //   Icons.lock_outline,
                  //   'เปลี่ยนรหัสผ่าน',
                  //   primaryIconColor,
                  //   () => print('เปลี่ยนรหัสผ่าน clicked'),
                  // ),
                  // ▲▲▲▲▲▲ [ CODE ที่ลบ ] ▲▲▲▲▲▲

                  // 7. เรียกใช้ฟังก์ชัน _signOut() เมื่อกดปุ่ม
                  _buildListMenuItem(
                    Icons.logout,
                    'ออกจากระบบ',
                    logoutIconColor,
                    _signOut, // <-- เรียกใช้ฟังก์ชันที่สร้างไว้
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}