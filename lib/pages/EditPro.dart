import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // ฟังก์ชันตัวช่วยต่างๆ (โค้ดเดิมของคุณ)
  Widget _buildWideMenuButton(String imagePath, String title) {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 30,
            height: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareMenuButton(String imagePath, String title) {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
     return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: 35,
            height: 35,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

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
    const int currentIndex = 2;
    const Color primaryIconColor = Color(0xFF00B09A);
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

            // ส่วนเมนู (เหมือนเดิม)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => print('สั่งสินค้า clicked'),
                          child: _buildWideMenuButton(
                              'assets/image/order.png', 'สั่งสินค้า'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => print('สถานะพัสดุ clicked'),
                          child: _buildWideMenuButton(
                              'assets/image/order2.png', 'สถานะพัสดุ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => print('พัสดุที่ต้องรับ clicked'),
                          child: _buildSquareMenuButton(
                              'assets/image/order3.png', 'พัสดุที่ต้องรับ'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => print('คุยกับไรเดอร์ clicked'),
                          child: _buildSquareMenuButton(
                              'assets/image/order4.png', 'คุยกับไรเดอร์'),
                        ),
                      ),
                      const SizedBox(width: 10),
                       Expanded(
                        child: GestureDetector(
                          onTap: () => print('ส่วนลดแพ็กเกจ clicked'),
                          child: _buildSquareMenuButton(
                              'assets/image/order5.png', 'ส่วนลดแพ็กเกจ'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ส่วนตั้งค่าโปรไฟล์
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  _buildListMenuItem(
                    Icons.person_outline,
                    'แก้ไขข้อมูลส่วนตัว',
                    primaryIconColor,
                    () => print('แก้ไขข้อมูลส่วนตัว clicked'),
                  ),
                  _buildListMenuItem(
                    Icons.lock_outline,
                    'เปลี่ยนรหัสผ่าน',
                    primaryIconColor,
                    () => print('เปลี่ยนรหัสผ่าน clicked'),
                  ),
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
        currentIndex: currentIndex,
        onItemSelected: (index) {
           if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst); 
          } else if (index == 1) {
            debugPrint('Navigate to Products');
          }
        },
      ),
    );
  }
}
