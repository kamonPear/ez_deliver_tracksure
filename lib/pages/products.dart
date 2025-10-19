import 'package:flutter/material.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';


class Products extends StatelessWidget {
  const Products({super.key});

  // ฟังก์ชันสำหรับจัดการการแตะที่ BottomNavigationBar
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) { // หากกดปุ่ม 'หน้าแรก' (Index 0)
      // ใช้ Navigator.pop() เพื่อกลับไปยังหน้า HomeScreen ที่เรียกหน้านี้มา
      Navigator.pop(context);
    } else if (index == 2) { // ⭐ หากกดปุ่ม 'อื่นๆ' (Index 2)
      // แสดง Snackbar/Toast เพื่อแจ้งเตือนว่าหน้านี้ยังไม่พร้อมใช้งาน
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('หน้านี้กำลังอยู่ระหว่างการพัฒนา กรุณากลับมาใหม่ภายหลัง'),
          duration: Duration(milliseconds: 1500), // แสดงผล 1.5 วินาที
        ),
      );
    }
    // ถ้า index เป็น 1 (Products) จะไม่ทำอะไร (เพราะอยู่หน้านี้อยู่แล้ว)
  }

  // ฟังก์ชันสำหรับสร้างปุ่มเมนูแนวกว้าง (รูปข้างๆข้อความ)
  Widget _buildWideMenuButton(String imagePath, String label) {
    return Expanded( // ใช้ Expanded เพื่อให้ปุ่มขยายเต็มพื้นที่ที่เหลือ
      child: Container(
        height: 100, // กำหนดความสูงของปุ่ม
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
            // ต้องมั่นใจว่า asset path ถูกต้องและมีรูปภาพอยู่ในโฟลเดอร์ assets/image/
            Image.asset(imagePath, height: 50, errorBuilder: (context, error, stackTrace) {
              // กรณีไม่พบรูปภาพ ให้แสดงไอคอนแทน
              return const Icon(Icons.info, size: 50, color: Colors.red);
            }), 
            const SizedBox(width: 8), // ระยะห่างระหว่างรูปและข้อความ
            Flexible( // ใช้ Flexible เพื่อป้องกันข้อความยาวเกินไป
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มเมนูสี่เหลี่ยมจัตุรัส
  Widget _buildSquareMenuButton(String imagePath, String label) {
    return Expanded( // ใช้ Expanded เพื่อให้ปุ่มขยายเต็มพื้นที่ที่เหลือ
      child: Container(
        height: 100, // กำหนดขนาดของปุ่ม
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
            // ต้องมั่นใจว่า asset path ถูกต้องและมีรูปภาพอยู่ในโฟลเดอร์ assets/image/
            Image.asset(imagePath, height: 40, errorBuilder: (context, error, stackTrace) {
              // กรณีไม่พบรูปภาพ ให้แสดงไอคอนแทน
              return const Icon(Icons.info, size: 40, color: Colors.red);
            }), 
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับสร้างช่องรายการสินค้าที่กำลังส่ง (Header Card)
  Widget _buildShippingListCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity, // ขยายเต็มความกว้าง
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        decoration: BoxDecoration(
          color: const Color(0xFF074F77), // สีน้ำเงินเข้ม
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ใช้ Stack เพื่อจัดให้ข้อความอยู่กึ่งกลางและให้ลูกศรอยู่ขวาสุด
        child: Stack( 
          alignment: Alignment.center, // ให้เนื้อหาหลักอยู่กึ่งกลาง
          children: [
            // 1. ส่วน Icon และ Text (จัดให้อยู่ตรงกลาง)
            const Row(
              mainAxisSize: MainAxisSize.min, // จำกัดความกว้างของ Row ให้เท่ากับเนื้อหา
              children: [
                // ไอคอนรถบรรทุก (หรือไอคอนอื่นที่เกี่ยวข้อง)
                Icon(Icons.local_shipping, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Text(
                  'รายการสินค้าที่กำลังส่ง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            // 2. ไอคอนลูกศรชี้ไปด้านขวา (จัดให้อยู่ทางขวาของ Container)
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ** ฟังก์ชันสำหรับสร้างกล่องแสดงรายละเอียดการจัดส่งสินค้า (ปรับให้รูปภาพมีกรอบคงที่) **
  Widget _buildDeliveryItemCard() {
    // กำหนดสีเขียวสำหรับปุ่มและไอคอนที่เกี่ยวข้อง
    const Color primaryColor = Color(0xFF07AA7C); 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10.0), // ลด Padding ภายใน
        decoration: BoxDecoration(
          color: Colors.white, // สีพื้นหลังขาว
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // ส่วนหลัก: รูปภาพด้านซ้าย รายละเอียดด้านขวา
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. รูปภาพ/โลโก้ (ด้านซ้าย)
                // ใช้ Container กำหนดความสูง/กว้างคงที่ (90x90) เพื่อล็อกพื้นที่ของโลโก้
                Container(
                  width: 90, // ** เพิ่มความกว้างของพื้นที่โลโก้เป็น 90 **
                  height: 90, // ** เพิ่มความสูงของพื้นที่โลโก้เป็น 90 **
                  margin: const EdgeInsets.only(right: 15.0), // ระยะห่างด้านขวา
                  child: Center(
                    child: Image.asset('assets/image/logo.png', height: 130, width: 90, errorBuilder: (context, error, stackTrace) { 
                      // รูปภาพ/ไอคอน ถูกเพิ่มขนาดเป็น 70x70 และอยู่ตรงกลางในกรอบ 90x90
                      return const Icon(Icons.delivery_dining, color: primaryColor, size: 70);
                    }),
                  ),
                ),

                // 2. ส่วนรายละเอียดสถานที่รับ-ส่ง (ด้านขวา)
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // จุดรับสินค้า
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 20),
                          SizedBox(width: 5),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'คณะวิทยาการสารสนเทศ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), // ขนาดตัวอักษรคงเดิม
                                ),
                                Text(
                                  'ชื่อผู้ส่ง : ............',
                                  style: TextStyle(fontSize: 14, color: Colors.black54), // ขนาดตัวอักษรคงเดิม
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5), // ลดระยะห่างระหว่างจุดรับ-ส่ง
                      // จุดส่งสินค้า
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: primaryColor, size: 20),
                          SizedBox(width: 5),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'หอพักเมธาพลาซ่าโซน ตึก 3',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), // ขนาดตัวอักษรคงเดิม
                                ),
                                Text(
                                  'ชื่อผู้รับ : ............',
                                  style: TextStyle(fontSize: 14, color: Colors.black54), // ขนาดตัวอักษรคงเดิม
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // 3. ปุ่ม "รายละเอียด" ที่มุมล่างขวา
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(top: 5), // ลด Margin ด้านบน
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF90EE90), // สีเขียวอ่อนคล้ายในรูป
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'รายละเอียด',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16), // ขนาดตัวอักษรคงเดิม
                    ),
                    Icon(Icons.chevron_right, color: Colors.black, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // **********************************************
  // ฟังก์ชันสร้าง item ย่อยในแบนเนอร์ (คงไว้ตามเดิม)
  // **********************************************

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
            textAlign: TextAlign.center, // จัดข้อความให้อยู่ตรงกลาง
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
            textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
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
            // ส่วนที่ 1: บาร์ด้านบน
            const TopBar(),

            // ส่วนที่ 2: เมนูหลัก 
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // แถวบน (ปุ่มยาว 2 ปุ่ม)
                  Row(
                    children: [
                      _buildWideMenuButton(
                        'assets/image/order.png',
                        'สั่งสินค้า',
                      ),
                      const SizedBox(width: 10), // ระยะห่างระหว่างปุ่ม
                      _buildWideMenuButton(
                        'assets/image/order2.png',
                        'สถานะพัสดุ',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // ระยะห่างระหว่างแถว
                  // แถวล่าง (ปุ่มสั้น 3 ปุ่ม)
                  Row(
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

            // ** ส่วนที่ 3A: ช่องรายการสินค้าที่กำลังส่ง (Header Card) **
            _buildShippingListCard(context),

            // ** ส่วนที่ 3B: กล่องแสดงรายละเอียดการจัดส่งสินค้า **
            _buildDeliveryItemCard(),
            _buildDeliveryItemCard(),
            _buildDeliveryItemCard(),

            const SizedBox(height: 20), // เพิ่มระยะห่างด้านล่าง

          ],
        ),
      ),
      // ส่วนที่ 4: บาร์ด้านล่าง (แก้ไขเพื่อส่งฟังก์ชัน _onItemTapped)
      bottomNavigationBar: BottomBar(
        // แก้ไขให้ส่งค่า Index และ onItemSelected เข้าไป
        currentIndex: 1, // กำหนด Index เป็น 1 (ประวัติการส่งสินค้า)
        // ส่งฟังก์ชัน _onItemTapped และแนบ context เข้าไปเพื่อใช้ Navigator และ SnackBar
        onItemSelected: (index) => _onItemTapped(context, index),
      ),
    );
  }
}