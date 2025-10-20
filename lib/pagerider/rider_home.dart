import 'package:flutter/material.dart';
import 'rider_bottom_bar.dart';
import 'rider_status.dart';
import 'package:delivery_ui/pages/login.dart';
import 'editrider.dart';

// ----------------------
// 1. กำหนดค่าสี (Colors)
// ----------------------
const Color primaryGreen = Color(0xFF00C853); // เขียวหลัก
const Color darkBlue = Color(0xFF1A237E);    // น้ำเงินเข้ม (สำหรับ Gradient)
const Color secondaryGreen = Color(0xFF4CAF50); // เขียวปุ่ม 'รับงาน'
const Color darkBottomNav = Color(0xFF00796B);  // เขียวอมน้ำเงิน (สำหรับ Bottom Nav)
const Color locationPinRed = Color(0xFFF44336);  // แดงหมุด
const Color packageBrown = Color(0xFF8D6E63);  // น้ำตาลไอคอนพัสดุ


// ----------------------
// 2. หน้าจอหลัก (DeliveryHomePage)
// ----------------------
class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  int _currentIndex = 0;

  void _onItemTapped(int index) async {
    if (index == 0) {
      // 🏠 หน้าแรก
      setState(() {
        _currentIndex = 0;
      });
    } else if (index == 1) {
      // 🏍️ หน้าข้อมูลการส่งของ
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const  DeliveryStatusScreen()),
      );
      setState(() {
        _currentIndex = 0;
      });
    } else if (index == 2) {
      // 🚪 ออกจากระบบ
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(context), // ส่วนหัว
            _buildBody(),          // เนื้อหา
          ],
        ),
      ),
      bottomNavigationBar: StatusBottomBar(
        currentIndex: _currentIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }

  // ----------------------
  // 3. ส่วน Header
  // ----------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen, darkBlue],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 32,
              child: Icon(Icons.person, size: 50, color: darkBlue),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                "สวัสดีคุณ ..........",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // ✅ ปุ่มกดเพื่อแก้ไขข้อมูลส่วนตัว
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                },
                child: const Text(
                  "แก้ไขข้อมูลส่วนตัว",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------
  // 4. ส่วน Body
  // ----------------------
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                child: Text(
                  "รายการสินค้าที่ต้องไปส่ง",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildDeliveryCard(),
        ],
      ),
    );
  }

  // ----------------------
  // 5. การ์ดข้อมูลการจัดส่ง
  // ----------------------
  Widget _buildDeliveryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const Icon(Icons.folder, color: packageBrown, size: 28),
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey.shade400,
                    ),
                    const Icon(Icons.location_on, color: locationPinRed, size: 28),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      SizedBox(height: 3),
                      Text(
                        "คณะวิทยาการสารสนเทศ",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 35),
                      Text(
                        "หอพักเมรพาลโซ่ ตึก 3",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("รับงานเรียบร้อย!");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                elevation: 3,
              ),
              child: const Text(
                "รับงาน",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
