import 'package:flutter/material.dart';
import 'bottom_bar.dart'; // ใช้ BottomBar ที่ import มา

// ------------------------------------------------------------------
// Class ProEditScreen สำหรับหน้าแก้ไขข้อมูลส่วนตัว (อ้างอิงจากรูปภาพ)
// ------------------------------------------------------------------

class ProEditScreen extends StatelessWidget {
  const ProEditScreen({super.key});

  // ***************************************************************
  // ************* ฟังก์ชันตัวช่วยสำหรับสร้างช่องกรอกข้อมูล (TextField) *************
  // ***************************************************************
  Widget _buildTextField({
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    // กำหนดสีหลักที่เห็นในรูปภาพ
    const Color inputTextColor = Color(0xFF333333); 
    const Color inputHintColor = Color(0xFFB0B0B0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (ป้ายชื่อ)
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: inputTextColor, 
          ),
        ),
        const SizedBox(height: 8),
        // Input Field (ช่องกรอก)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
            // สีขอบและเงาเลียนแบบในรูปภาพ
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
            keyboardType: keyboardType,
            maxLines: maxLines,
            // ในรูปภาพดูเหมือนไม่มีขอบเมื่อโฟกัส แต่มีเส้นขอบสีฟ้าจางๆ
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: inputHintColor),
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
              // ลบเส้นขอบเริ่มต้นของ TextField
              border: InputBorder.none, 
              // กำหนดสีเส้นเมื่อโฟกัสให้เหมือนในภาพ (สีฟ้าอ่อน)
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blueAccent, width: 1.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              enabledBorder: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 16, color: inputTextColor),
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
    // กำหนดสีตามภาพที่ให้มา
    const Color primaryGreen = Color(0xFF00C853); 
    const Color gradientStart = Color(0xFF00B09B); 
    const Color gradientEnd = Color(0xFF96C93D); 

    // กำหนด index สำหรับหน้า Profile/EditPro (สมมติว่าเป็น index 2)
    const int currentIndex = 2;

    return Scaffold(
      backgroundColor: Colors.white, 
      
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
                  // ใช้สี Gradient จากรูปภาพ
                  colors: [gradientStart, gradientEnd], 
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // รูปโปรไฟล์ Doraemon
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
                        // URL รูป Doraemon Placeholder (ต้องแทนที่ด้วยรูปจริง)
                        'https://placehold.co/100x100/ffffff/000000?text=Doraemon', 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.person, size: 60, color: Color(0xFF42A5F5)), // Fallback Icon
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // ข้อความ "แก้ไขข้อมูลส่วนตัว"
                  const Text(
                    'แก้ไขข้อมูลส่วนตัว',
                    style: TextStyle(
                      fontSize: 22,
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
              padding: const EdgeInsets.only(top: 30, left: 30.0, right: 30.0, bottom: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ช่องที่ 1: ชื่อ - สกุล
                  _buildTextField(
                    label: 'ชื่อ - สกุล',
                    hint: 'ชื่อ - สกุล',
                  ),
                  
                  // ช่องที่ 2: หมายเลขโทรศัพท์
                  _buildTextField(
                    label: 'หมายเลขโทรศัพท์',
                    hint: 'หมายเลขโทรศัพท์',
                    keyboardType: TextInputType.phone,
                  ),

                  // ช่องที่ 3: ที่อยู่หรือสถานที่ที่พิกัด
                  _buildTextField(
                    label: 'ที่อยู่หรือสถานที่ที่พิกัด',
                    hint: 'ที่อยู่หรือสถานที่ที่พิกัด',
                    maxLines: 1, // กำหนดเป็น 1 ตามรูปภาพ
                  ),
                  
                  // ช่องที่ 4: พิกัด GPS หรือสถานที่ที่รับสินค้า
                  _buildTextField(
                    label: 'พิกัด GPS หรือสถานที่ที่รับสินค้า',
                    hint: 'พิกัดรับสินค้า',
                  ),
                  
                  const SizedBox(height: 20),

                  // ปุ่มบันทึกข้อมูล
                  Center(
                    child: SizedBox(
                      width: double.infinity, // ให้ปุ่มกว้างเต็มพื้นที่ตาม Padding
                      child: ElevatedButton(
                        onPressed: () {
                          // โค้ดสำหรับบันทึกข้อมูลส่วนตัว
                          debugPrint('บันทึกข้อมูลส่วนตัว clicked');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen, // ใช้สีเขียวหลัก
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 5, 
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
                  ),
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

