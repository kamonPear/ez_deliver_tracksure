import 'package:flutter/material.dart';
import 'bottom_bar.dart'; // ใช้ BottomBar ที่ import มา



// ------------------------------------------------------------------
// Class ChangePasswordScreen สำหรับหน้าเปลี่ยนรหัสผ่าน
// ------------------------------------------------------------------

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  // ***************************************************************
  // ************* ฟังก์ชันตัวช่วยสำหรับสร้างช่องกรอกข้อมูล *************
  // ***************************************************************
  Widget _buildPasswordField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (ป้ายชื่อ)
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333), // สีเทาเข้ม
          ),
        ),
        const SizedBox(height: 8),
        // Input Field (ช่องกรอก)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            obscureText: true, // ซ่อนข้อความรหัสผ่าน
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
              border: InputBorder.none, // ลบเส้นขอบเริ่มต้นของ TextField ออก
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20), // ระยะห่างด้านล่างสำหรับช่องถัดไป
      ],
    );
  }

  // ***************************************************************
  // *********************** ส่วน Widget build **********************
  // ***************************************************************

  @override
  Widget build(BuildContext context) {
    // กำหนด index สำหรับหน้า Profile/EditPro (สมมติว่าเป็น index 2)
    const int currentIndex = 2;

    return Scaffold(
      backgroundColor: Colors.white, // กำหนดพื้นหลังหลักเป็นสีขาว
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ------------------------------------------------
            // 1. Header ส่วนหัว (สี Gradient + รูปโปรไฟล์)
            // ------------------------------------------------
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00B09A), Color(0xFF007569)], // สีเขียว-น้ำเงิน
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // รูปโปรไฟล์ (ใช้ Container และ ClipOval จำลองรูป)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        // ใช้ URL รูป Doraemon Placeholder หรือใช้ Image.asset('assets/image/doraemon.png')
                        // ในการใช้งานจริง ท่านควรใช้ Image.asset หากมีไฟล์รูป
                        'https://placehold.co/100x100/ffffff/000000?text=Dora', 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.person, size: 60, color: Colors.blueGrey), // Fallback Icon
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // ข้อความ "เปลี่ยนรหัสผ่าน"
                  const Text(
                    'เปลี่ยนรหัสผ่าน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------
            // 2. Form แบบฟอร์ม
            // ------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ช่องกรอกรหัสผ่านเดิม
                  _buildPasswordField(
                    label: 'รหัสผ่านเดิม',
                    hint: 'รหัสผ่านเดิม',
                  ),
                  
                  // ช่องกรอกรหัสผ่านใหม่
                  _buildPasswordField(
                    label: 'รหัสผ่านใหม่',
                    hint: 'รหัสผ่านใหม่',
                  ),

                  // ช่องกรอกยืนยันรหัสผ่าน
                  _buildPasswordField(
                    label: 'ยืนยันรหัสผ่าน',
                    hint: 'ยืนยันรหัสผ่าน',
                  ),
                  
                  const SizedBox(height: 10),

                  // ปุ่มบันทึกข้อมูล
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // โค้ดสำหรับบันทึกข้อมูลรหัสผ่าน
                        debugPrint('บันทึกข้อมูล clicked');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50), // สีเขียวตามภาพ
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5, // เพิ่มเงาเล็กน้อย
                      ),
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
      
      // 3. Bottom Bar (Navigation)
      // ใช้ BottomBar ที่ถูก import มา
      bottomNavigationBar: BottomBar(
        currentIndex: currentIndex, 
        onItemSelected: (index) {
           if (index == 0) {
            // ไปหน้า Home (สมมติว่าเป็นหน้าแรกสุด)
            Navigator.popUntil(context, (route) => route.isFirst); 
          } else if (index == 2) {
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
