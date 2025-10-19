import 'package:flutter/material.dart';
import 'top_bar.dart'; // ใช้ TopBar ที่ import มา
import 'bottom_bar.dart'; // ใช้ BottomBar ที่ import มา
import 'all.dart'; // Import ที่ไม่จำเป็น แต่เก็บไว้ตามโค้ดเดิม

class ShippingOrderScreen extends StatelessWidget {
  const ShippingOrderScreen({Key? key}) : super(key: key);

  // **กำหนดสีหลักที่เห็นในรูปภาพ**
  static const Color primaryGreen = Color(0xFF00C853);
  static const Color accentColor = Color(0xFF42A5F5); // สีฟ้าสำหรับขอบ Input

  // **แก้ไข: เพิ่ม currentIndex เป็นค่าคงที่สำหรับหน้านี้**
  // สมมติว่าหน้านี้ตรงกับ Index 0 ('หน้าแรก')
  static const int currentIndex = 0; 

  // ***************************************************************
  // *********************** HELPER WIDGETS ************************
  // ***************************************************************

  // 1. ข้อมูลผู้ส่ง/ผู้รับ Card
  Widget _buildSenderInfoCard() {
    return Card(
      margin: EdgeInsets.zero, // ลบ margin เริ่มต้นของ Card
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูป Doraemon เล็ก
            ClipOval(
              child: Image.network(
                'https://placehold.co/40x40/ffffff/000000?text=Dora', 
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.person_outline, size: 40, color: primaryGreen),
              ),
            ),
            const SizedBox(width: 15),
            
            // รายละเอียด
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('ชื่อ : ................', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 4),
                  Text('เบอร์โทร : 123 456 8900', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 4),
                  Text('ที่อยู่ : หอพักเมฆพาลสไลซอ', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. ปุ่ม Action Button (แนบข้อมูล/เพิ่มข้อมูล)
  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Container(
        // ปรับเป็นความกว้างเต็มพื้นที่ padding
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
            elevation: 0, // ลบเงาซ้ำซ้อน
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

  // 3. ส่วนแสดงรูปภาพและปุ่มอัปโหลด
  Widget _buildImageAndActionSection() {
    return Column(
      children: [
        // กล่องแสดงรูปสินค้า (ใช้ Icon/Image Placeholder)
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
            // Icon กล่องพัสดุ
            child: Icon(Icons.inventory_2_outlined, size: 80, color: Color(0xFFD3A867)), 
          ),
        ),

        // ปุ่มอัปโหลด/ถ่ายรูป
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ปุ่ม "อัปโหลดรูปสินค้า"
            _buildSmallActionButton(
              icon: Icons.add_circle_outline,
              text: 'อัปโหลดรูปสินค้า',
              onPressed: () {
                debugPrint('อัปโหลดรูปสินค้า clicked');
              },
            ),
            const SizedBox(width: 15),
            // ปุ่ม "ถ่ายรูปสินค้า"
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

  // 4. ปุ่มเล็กสำหรับอัปโหลด/ถ่ายรูป
  Widget _buildSmallActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  // 5. ช่องกรอกรายละเอียดสินค้า (Text Area)
  Widget _buildDescriptionTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: accentColor), // **ขอบสีฟ้าตามรูปภาพ**
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
    // ----------------------------------------------------------------------
    // ส่วนหลักของ Build Method
    // ----------------------------------------------------------------------
    return Scaffold(
      backgroundColor: Colors.white, 
      
      body: Column(
        // ใช้ Column เพื่อวาง TopBar ไว้ด้านบนสุดของ Body
        children: [
          // ------------------------------------------------
          // 1. Header (TopBar)
          // ------------------------------------------------
          const TopBar(), // ใช้ Widget TopBar ที่ import มาสำหรับส่วนหัว

          // ------------------------------------------------
          // 2. Content ส่วนที่เหลือ (Scrollable)
          // ------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 15),

                  // ข้อมูลผู้ส่ง/ผู้รับ (Card สีขาว)
                  _buildSenderInfoCard(),
                  const SizedBox(height: 20),

                  // ปุ่ม "แนบข้อมูลสินค้าที่จะจัดส่ง"
                  _buildActionButton(
                    text: 'แนบข้อมูลสินค้าที่จะจัดส่ง',
                    color: primaryGreen,
                    onPressed: () {
                      debugPrint('แนบข้อมูลสินค้า clicked');
                    },
                  ),
                  const SizedBox(height: 25),

                  // ช่องสำหรับรูปภาพและปุ่มอัปโหลด/ถ่ายรูป
                  _buildImageAndActionSection(),
                  const SizedBox(height: 20),

                  // รายละเอียดสินค้า (Text Area)
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
                  
                  // ปุ่ม "เพิ่มข้อมูลสินค้า"
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
          ),
        ],
      ),
      
      // ------------------------------------------------
      // 3. Bottom Bar (Navigation)
      // ------------------------------------------------
      bottomNavigationBar: BottomBar(
        currentIndex: currentIndex, 
        onItemSelected: (index) {
          debugPrint('BottomBar tapped at index $index');
        }, 
      ),
    );
  }
}
