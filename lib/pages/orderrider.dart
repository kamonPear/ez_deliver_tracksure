import 'package:flutter/material.dart';
import 'rider_top.dart';
import 'rider_bottom_bar.dart';
import 'status_stepper.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  // Helper function สำหรับสร้างปุ่มถ่ายรูป
  Widget _buildPhotoButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // ใช้ Stack เพื่อให้ TopBar ที่เป็น Gradient อยู่ด้านหลังเนื้อหา
      body: Stack(
        children: [
          // Layer 1: พื้นหลังไล่สีทั้งหมด
          const Column(
            children: [
              StatusTopBar(),
              Expanded(
                child: SizedBox(), // ขยายพื้นที่ด้านล่าง TopBar
              ),
            ],
          ),

          // Layer 2: เนื้อหาที่สามารถ scroll ได้
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100), // ดันเนื้อหาลงมาให้พ้น TopBar
                  const StatusStepper(currentStep: 4), // แสดงขั้นตอนการส่ง
                  
                  // ▼▼▼ ส่วนเนื้อหาสีขาว ▼▼▼
                  Transform.translate(
                    offset: const Offset(0, -20), // ดึง Card ขึ้นมาทับเล็กน้อย
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ▼▼▼ ใส่ Widget แผนที่ของคุณที่นี่ ▼▼▼
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text(
                                  'พื้นที่สำหรับแผนที่',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          ),
                          // ▲▲▲ สิ้นสุดพื้นที่แผนที่ ▲▲▲

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(child: _buildPhotoButton('สถานะกำลังจัดส่ง')),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPhotoButton('สถานะจัดส่งสำเร็จ')),
                            ],
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF28A745),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('ยืนยันการส่งสินค้า', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ▼▼▼ การ์ดแสดงข้อมูลผู้ส่ง-ผู้รับ ▼▼▼
                          Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(15),
                               border: Border.all(color: Colors.grey.shade200)
                             ),
                             child: Row(
                               children: [
                                  // ▼▼▼ ใส่โลโก้ Rider ของคุณที่นี่ ▼▼▼
                                  Image.asset('assets/images/delivery_logo.png', height: 60),
                                  // ▲▲▲ สิ้นสุดพื้นที่โลโก้ ▲▲▲

                                  const SizedBox(width: 12),

                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildAddressRow(Icons.location_on, 'คณะวิทยาการสารสนเทศ', 'ชื่อผู้ส่ง:', 'เบอร์โทร: 123 4567 7890'),
                                      const Divider(height: 16),
                                      _buildAddressRow(Icons.location_on, 'หอพักเมธาพลาซ่า', 'ชื่อผู้รับ:', 'เบอร์โทร: 123 4567 7890'),
                                    ],
                                  ))
                               ],
                             ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                             width: double.infinity,
                             child: ElevatedButton(
                               onPressed: () {},
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFF07AA7C),
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(30),
                                 ),
                               ),
                               child: const Text('ข้อมูลสินค้า', style: TextStyle(fontSize: 16, color: Colors.white)),
                             ),
                           ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const StatusBottomBar(),
    );
  }
   // Helper function สำหรับสร้างแถวที่อยู่
  Widget _buildAddressRow(IconData icon, String place, String name, String phone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF07AA7C), size: 20),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(name, style: const TextStyle(fontSize: 12)),
            Text(phone, style: const TextStyle(fontSize: 12)),
          ],
        ))
      ],
    );
  }
}
