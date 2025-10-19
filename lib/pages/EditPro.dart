import 'package:flutter/material.dart';
import 'top_bar.dart'; // ใช้ TopBar ที่ import มา
import 'bottom_bar.dart'; // ใช้ BottomBar ที่ import มา
// import 'password.dart'; // **อัปเดต: IMPORT ไฟล์ password.dart**
// import 'proedit.dart';

// ------------------------------------------------------------------
// Class EditPro ที่รวม TopBar และ BottomBar
// ------------------------------------------------------------------

class EditPro extends StatelessWidget {
  const EditPro({super.key});

  // ***************************************************************
  // ************* ฟังก์ชันตัวช่วยสำหรับสร้างปุ่มเมนู ***************
  // ***************************************************************

  // ปุ่มเมนูยาว 2 ปุ่มต่อแถว
  Widget _buildWideMenuButton(String imagePath, String title) {
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

  // ปุ่มเมนูสั้น 3 ปุ่มต่อแถว
  Widget _buildSquareMenuButton(String imagePath, String title) {
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

  // ***************************************************************
  // ************* ฟังก์ชันตัวช่วยสำหรับสร้างปุ่มเมนูแบบรายการ *
  // ***************************************************************
  /// สร้างปุ่มเมนูแบบเต็มความกว้าง (List-style) สำหรับเมนูตั้งค่า
  Widget _buildListMenuItem(IconData icon, String title, Color iconColor, VoidCallback onTapAction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // ระยะห่างด้านล่างระหว่างรายการ
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
      child: Material( // ใช้ Material/InkWell เพื่อเพิ่ม Feedback เมื่อกด
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

  // ***************************************************************
  // *********************** ส่วน Widget build **********************
  // ***************************************************************

  @override
  Widget build(BuildContext context) {
    // กำหนด index สำหรับหน้า Profile/EditPro
    const int currentIndex = 2;
    // กำหนดสีเขียว/น้ำเงินที่ใช้สำหรับไอคอน (อ้างอิงจากภาพตัวอย่าง)
    const Color primaryIconColor = Color(0xFF00B09A); 
    // กำหนดสีแดงสำหรับออกจากระบบ
    const Color logoutIconColor = Colors.red;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      
      // เปลี่ยนจาก Stack มาเป็น SingleChildScrollView > Column
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนที่ 1: บาร์ด้านบน
            const TopBar(), // ใช้ TopBar ที่ import มา

            // ส่วนที่ 2: เมนูหลัก (ใช้ GestureDetector เพื่อให้ปุ่มที่กำหนดมีฟังก์ชันการคลิก)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // แถวบน (ปุ่มยาว 2 ปุ่ม)
                  Row(
                    children: [
                      // ห่อด้วย Expanded และ GestureDetector
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // โค้ดสำหรับปุ่ม 'สั่งสินค้า'
                            print('สั่งสินค้า clicked'); 
                          },
                          child: _buildWideMenuButton(
                            'assets/image/order.png',
                            'สั่งสินค้า',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // ระยะห่างระหว่างปุ่ม
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // โค้ดสำหรับปุ่ม 'สถานะพัสดุ'
                            print('สถานะพัสดุ clicked');
                          },
                          child: _buildWideMenuButton(
                            'assets/image/order2.png',
                            'สถานะพัสดุ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // ระยะห่างระหว่างแถว
                  // แถวล่าง (ปุ่มสั้น 3 ปุ่ม)
                  Row(
                    children: [
                      // ห่อด้วย Expanded และ GestureDetector
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            print('พัสดุที่ต้องรับ clicked');
                          },
                          child: _buildSquareMenuButton(
                            'assets/image/order3.png',
                            'พัสดุที่ต้องรับ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            print('คุยกับไรเดอร์ clicked');
                          },
                          child: _buildSquareMenuButton(
                            'assets/image/order4.png',
                            'คุยกับไรเดอร์',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            print('ส่วนลดแพ็กเกจ clicked');
                          },
                          child: _buildSquareMenuButton(
                            'assets/image/order5.png',
                            'ส่วนลดแพ็กเกจ',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // ส่วนที่ 3: เมนูการตั้งค่าโปรไฟล์ใหม่
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  // 1. แก้ไขข้อมูลส่วนตัว
                  _buildListMenuItem(
                    Icons.person_outline, 
                    'แก้ไขข้อมูลส่วนตัว',
                    primaryIconColor,
                    () {
                      debugPrint('แก้ไขข้อมูลส่วนตัว clicked -> Navigate to ProEditScreen');
                      // **โค้ดนำทางไปหน้า ProEditScreen**
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => const ProEditScreen()), // **อัปเดต: ใช้ ProEditScreen**
                      // );
                    },
                  ),
                
                  _buildListMenuItem(
                    Icons.lock_outline, 
                    'เปลี่ยนรหัสผ่าน',
                    primaryIconColor,
                    () {
                      debugPrint('เปลี่ยนรหัสผ่าน clicked -> Navigate to PasswordScreen');
                      // **โค้ดนำทางไปหน้า PasswordScreen**
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => const ChangePasswordScreen()), // **อัปเดต: ใช้ PasswordScreen**
                      // );
                    },
                  ),
                  // 3. ออกจากระบบ
                  _buildListMenuItem(
                    Icons.logout, 
                    'ออกจากระบบ',
                    logoutIconColor,
                    () {
                      debugPrint('ออกจากระบบ clicked');
                      // TODO: เพิ่มโค้ด Logout
                    },
                  ),
                  // เพิ่มระยะห่างด้านล่างอีกนิด เพื่อให้ BottomBar ไม่ติดเนื้อหาจนเกินไป
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
          ],
        ),
      ),
      
      // 3. Bottom Bar (Navigation)
      bottomNavigationBar: BottomBar(
        currentIndex: currentIndex, 
        onItemSelected: (index) {
          if (index == 0) {
            // ไปหน้า Home (สมมติว่าเป็นหน้าแรกสุด)
            Navigator.popUntil(context, (route) => route.isFirst); 
          } else if (index == 1) {
            // โค้ดนำทางไปหน้า Products ถูกคอมเมนต์ออก เพราะคลาส Products ไม่มีในไฟล์นี้
            debugPrint('Navigate to Products (Disabled: Products class is missing)');
            // Navigator.push( 
            // 	context,
            // 	MaterialPageRoute(builder: (context) => const Products()), 
            // );
          }
        }, 
      ),
    );
  }
}
