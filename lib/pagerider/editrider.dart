import 'package:flutter/material.dart';
// ต้องแน่ใจว่าคุณมีไฟล์ rider_bottom_bar.dart ที่มีคลาส StatusBottomBar
import 'rider_bottom_bar.dart';
import 'rider_status.dart';
import 'package:delivery_ui/pages/login.dart';

// สมมติว่าคุณมีคลาสนี้อยู่ (เพื่อให้โค้ดคอมไพล์ได้)



class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  // Widget Helper สำหรับสร้างช่องกรอกข้อมูล
  Widget _buildInputField({required String hintText, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          border: InputBorder.none, // ลบเส้นขอบเริ่มต้นของ TextField
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGradientStart = Color(0xFF00C6FF);
    const Color primaryGradientEnd = Color(0xFF0072FF);

    return Scaffold(
      // กำหนดแถบนำทางด้านล่าง
      bottomNavigationBar: StatusBottomBar(
        currentIndex: 0, // สมมติว่า EditProfileScreen คือ Index 2
        onItemSelected: (index) {
          // ฟังก์ชันนำทางเมื่อมีการคลิกแท็บ
          if (index == 1) { // Index 1 คือ 'ประวัติการส่งสินค้า'
            // ใช้ pushReplacement เพื่อแทนที่หน้าปัจจุบัน ป้องกันการสะสมของหน้าจอ
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const DeliveryStatusScreen(),
              ),
            );
          } else if (index == 2) {
      // 🚪 ออกจากระบบ → กลับไปหน้า LoginPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
          // หากต้องการเพิ่มการนำทางไปหน้าแรก (Index 0) หรือหน้าอื่นๆ (Index 2) ให้เพิ่มเงื่อนไขตรงนี้
          // else if (index == 0) { ... }
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // ส่วนหัว (Header Section)
            Container(
              width: double.infinity, 
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGradientStart, Color(0xFF00F260)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // ... ส่วนรูปโปรไฟล์และข้อความ ...
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      ClipOval(
                        child: Image.asset(
                          'assets/doraemon.png', 
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 90,
                              color: Colors.grey,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'แก้ไขข้อมูลส่วนตัว',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ส่วนฟอร์ม (Form Section)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. ชื่อ - สกุล
                  const Text('ชื่อ - สกุล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildInputField(hintText: 'ชื่อ - สกุล'),
                  const SizedBox(height: 20),
                  // 2. หมายเลขโทรศัพท์
                  const Text('หมายเลขโทรศัพท์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildInputField(hintText: 'หมายเลขโทรศัพท์', keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  // 3. ทะเบียนรถ
                  const Text('ทะเบียนรถ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildInputField(hintText: 'ทะเบียนรถ'),
                  const SizedBox(height: 40),

                  // ปุ่มบันทึกข้อมูล
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF00CC00),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 5,
                        ),
                        onPressed: () { debugPrint('บันทึกข้อมูลถูกกด'); },
                        child: const Text(
                          'บันทึกข้อมูล',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}