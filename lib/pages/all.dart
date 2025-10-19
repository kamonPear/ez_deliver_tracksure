import 'package:flutter/material.dart';
import 'products.dart';
import 'top_bar.dart';
import 'bottom_bar.dart';

// 1. เปลี่ยนจาก StatelessWidget เป็น StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 2. สร้างตัวแปร State เพื่อเก็บว่าเมนูไหนถูกเลือกอยู่ (เริ่มต้นที่ 0 คือหน้าแรก)
  int _selectedIndex = 0;

  // 3. สร้างฟังก์ชันเพื่อจัดการเมื่อมีการกดปุ่ม BottomBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // เพิ่มเงื่อนไขการเปลี่ยนหน้า
    switch (index) {
      case 0:
        // ไม่ต้องทำอะไร เพราะนี่คือหน้า HomeScreen อยู่แล้ว
        break;
      case 1:
        // ไปยังหน้าประวัติการส่งสินค้า (Products)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Products()),
        );
        break;
      case 2:
        // ไปยังหน้าอื่นๆ (สมมติว่าคือหน้า EditPro)
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => const EditPro()),
        // );
        // หรือแสดงข้อความถ้ายังไม่มีหน้านี้
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('หน้านี้ยังไม่พร้อมใช้งาน')),
        );
        break;
    }
  }

  // ฟังก์ชันสำหรับสร้างปุ่มเมนูแต่ละอัน
  // ฟังก์ชันสำหรับสร้างปุ่มเมนูแต่ละอัน (รูปข้างๆข้อความ)
  Widget _buildWideMenuButton(String imagePath, String label) {
    return Container(
      width: 180, // กำหนดความกว้างของปุ่ม
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
          Image.asset(imagePath, height: 50), // ใช้รูปไอคอนของคุณ
          const SizedBox(width: 8), // ระยะห่างระหว่างรูปและข้อความ
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มสี่เหลี่ยม
  Widget _buildSquareMenuButton(String imagePath, String label) {
    return Container(
      width: 118, // กำหนดขนาดของปุ่ม
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
          Image.asset(imagePath, height: 40), // ใช้รูปไอคอนของคุณ
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
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

            // ส่วนที่ 3: แบนเนอร์โปรโมชัน
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  // ใส่รูปพื้นหลังของแบนเนอร์ที่นี่
                  // image: DecorationImage(
                  //   image: AssetImage("assets/images/banner_bg.png"),
                  //   fit: BoxFit.cover,
                  // ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Center the entire column
                  children: [
                    const Text(
                      'โปรส่งของ',
                      textAlign: TextAlign.center, // Center the header text
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 224, 167, 91),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'คุ้มสุดๆ',
                      textAlign: TextAlign.center, // Center the header text
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 202, 122, 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign:
                          TextAlign.center, // Center the RichText content
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 22,
                          color: Color(0xFF07AA7C),
                        ),
                        children: [
                          TextSpan(
                            text: 'ส่งฟรี ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '50 บาท',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เมื่อส่งภายในระยะทางที่กำหนด',
                      textAlign: TextAlign.center, // Center the header text
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ส่วนไอคอนย่อย 3 อันด้านล่าง
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPromoItem('ส่งฟรี!'),
                        _buildPromoItem2('โปรคุ้มค่า!'),
                        _buildPromoItem3('ถึงหน้าบ้านคุณ!'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20), // เพิ่มระยะห่างด้านล่าง
          ],
        ),
      ),
      // ส่วนที่ 4: บาร์ด้านล่าง
      // 4. แก้ไขการเรียกใช้ BottomBar ให้ถูกต้อง
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped, // <--- เติม _ เข้าไป
      ),
    );
  }

  // ฟังก์ชันสร้าง item ย่อยในแบนเนอร์
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
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
