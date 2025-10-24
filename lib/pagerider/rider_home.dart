import 'package:flutter/material.dart';
import 'rider_bottom_bar.dart';
import 'rider_status.dart';
import 'package:ez_deliver_tracksure/pages/login.dart';
import 'editrider.dart';
// **[NEW]** เพิ่ม Firebase Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// **[NEW]** เพิ่ม Geolocator
import 'package:geolocator/geolocator.dart'; // <-- ต้องเพิ่ม package: geolocator ใน pubspec.yaml ด้วย

// ----------------------
// 1. กำหนดค่าสี (Colors)
// ----------------------
const Color primaryGreen = Color(0xFF00C853); // เขียวหลัก
const Color darkBlue = Color(0xFF1A237E); // น้ำเงินเข้ม (สำหรับ Gradient)
const Color secondaryGreen = Color(0xFF4CAF50); // เขียวปุ่ม 'รับงาน'
const Color darkBottomNav = Color(0xFF00796B); // เขียวอมน้ำเงิน (สำหรับ Bottom Nav)
const Color locationPinRed = Color(0xFFF44336); // แดงหมุด
const Color packageBrown = Color(0xFF8D6E63); // น้ำตาลไอคอนพัสดุ

// ----------------------
// **[NEW]** 1.1 Order Model สำหรับจัดการข้อมูล (แก้ไข createdDate เป็น DateTime?)
// ----------------------
class Order {
  final String orderId;
  final DateTime? createdDate; // เปลี่ยนเป็น DateTime?
  final String customerName;
  final String destination;
  final String pickupLocation;
  final String productDescription;
  final String receiverName;
  final String receiverPhone;
  final String? productImageUrl;

  // *** เพิ่มสถานะของออเดอร์ (สมมติว่ามี field: 'status' ใน Firebase) ***
  final String status;

  Order({
    required this.orderId,
    this.createdDate, // อัปเดต constructor
    required this.customerName,
    required this.destination,
    required this.pickupLocation,
    required this.productDescription,
    required this.receiverName,
    required this.receiverPhone,
    this.productImageUrl,
    this.status = 'pending', // สถานะเริ่มต้น
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // ตรวจสอบว่า data ไม่เป็น null ก่อนเข้าถึง key
    if (data == null) {
      throw Exception("Order data is null for document ${doc.id}");
    }

    final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?; // ดึง Timestamp

    return Order(
      orderId: doc.id,
      createdDate: createdAtTimestamp?.toDate(), // **[FIX]** แปลงเป็น DateTime
      customerName: data['customerName'] ?? 'ไม่ระบุลูกค้า',
      destination: data['destination'] ?? 'ไม่ระบุปลายทาง', // ดึงจาก Field 'destination'
      pickupLocation: data['pickupLocation'] ?? 'ไม่ระบุต้นทาง', // ดึงจาก Field 'pickupLocation'
      productDescription: data['productDescription'] ?? 'ไม่ระบุสินค้า', // ดึงจาก Field 'productDescription'
      receiverName: data['receiverName'] ?? 'ไม่ระบุผู้รับ', // ดึงจาก Field 'receiverName'
      receiverPhone: data['receiverPhone'] ?? 'ไม่ระบุเบอร์โทร', // ดึงจาก Field 'receiverPhone'
      productImageUrl: data['productImageUrl'],
      status: data['status'] ?? 'pending', // ดึงจาก Field 'status' (ถ้ามี)
    );
  }
}

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

  // **[NEW]** ตัวแปรเก็บข้อมูลไรเดอร์
  String _riderName = "กำลังโหลด...";
  String? _profileImageUrl;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchRiderData(); // เริ่มต้นดึงข้อมูล
  }

  // **[NEW]** ฟังก์ชันดึง Stream ของเอกสารทั้งหมดใน Collection 'orders' ที่รอรับงาน
  Stream<List<Order>> _fetchPendingOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // **[NEW]** ฟังก์ชันดึงข้อมูลไรเดอร์จาก Firestore
  Future<void> _fetchRiderData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _riderName = "กรุณาเข้าสู่ระบบใหม่";
        _isLoadingData = false;
      });
      return;
    }

    try {
      final riderDoc = await FirebaseFirestore.instance
          .collection('riders')
          .doc(user.uid)
          .get();

      if (riderDoc.exists) {
        final data = riderDoc.data()!;
        setState(() {
          _riderName = data['rider_name'] ?? 'ไม่ระบุชื่อ';
          _profileImageUrl = data['profile_image_url'];
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _riderName = "ไม่พบข้อมูลไรเดอร์";
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print("Error fetching rider data: $e");
      setState(() {
        _riderName = "เกิดข้อผิดพลาดในการโหลดข้อมูล";
        _isLoadingData = false;
      });
    }
  }

  // ------------------------------------------
  // **[NEW]** ฟังก์ชันดึงพิกัดปัจจุบันของไรเดอร์
  // ------------------------------------------
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่า Location Service เปิดอยู่หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('กรุณาเปิด Location Service เพื่อรับงาน')),
        );
      }
      return null;
    }

    // ตรวจสอบและร้องขอ Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('คุณต้องอนุญาตให้เข้าถึงตำแหน่งเพื่อรับงาน')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permission ถูกปฏิเสธถาวร, ไม่สามารถรับงานได้')),
        );
      }
      return null;
    }

    // ดึงตำแหน่งปัจจุบัน
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // ความแม่นยำสูง
      );
      return position;
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถดึงตำแหน่งปัจจุบันได้')),
        );
      }
      return null;
    }
  }

  // ------------------------------------------
  // **[FIX/NEW]** ฟังก์ชันตรวจสอบว่ามีงานที่กำลังทำอยู่หรือไม่
  // ------------------------------------------
  Future<bool> _checkOngoingOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // ตรวจสอบสถานะที่เป็นงานที่กำลังดำเนินการอยู่: 'accepted' และ 'on_delivery'
      final ongoingOrders = await FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: user.uid) // ผูกกับ Rider ID ปัจจุบัน
          .where('status', whereIn: ['accepted', 'on_delivery'])
          .limit(1) // ต้องการแค่เอกสารเดียวเพื่อยืนยันว่ามีงานอยู่
          .get();

      return ongoingOrders.docs.isNotEmpty;
    } catch (e) {
      print("Error checking ongoing order: $e");
      return false; // ในกรณีที่เกิดข้อผิดพลาด ให้ป้องกันไว้ก่อน
    }
  }

  // ------------------------------------------
  // **[FIX/UPDATE]** ฟังก์ชันรับงาน (เพิ่มการตรวจสอบงานที่กำลังดำเนินการอยู่)
  // ------------------------------------------
  Future<void> _acceptOrder(String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนรับงาน')),
      );
      return;
    }

    // 1. ตรวจสอบงานที่กำลังทำอยู่
    final hasOngoingOrder = await _checkOngoingOrder();

    if (hasOngoingOrder) {
      if (mounted) {
        // แสดงข้อความแจ้งเตือนว่ามีงานที่ยังไม่เสร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('คุณมีงานที่ต้องไปส่งอยู่แล้ว กรุณาส่งงานปัจจุบันให้เสร็จก่อน'),
            backgroundColor: locationPinRed, // ใช้สีแดงเพื่อให้เห็นชัด
            duration: Duration(seconds: 4),
          ),
        );
      }
      return; // ออกจากฟังก์ชัน ไม่รับงานใหม่
    }

    // 2. ดึงตำแหน่งปัจจุบันของไรเดอร์
    final currentPosition = await _getCurrentLocation();
    if (currentPosition == null) {
      // ถ้าดึงตำแหน่งไม่ได้ จะไม่ให้รับงาน
      return;
    }

    // 3. ถ้าไม่มีงานที่กำลังทำอยู่ และมีพิกัดแล้ว ให้ดำเนินการรับงาน (ใช้ Transaction เพื่อป้องกัน Race Condition)
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final orderRef =
            FirebaseFirestore.instance.collection('orders').doc(orderId);
        final orderSnapshot = await transaction.get(orderRef);

        if (!orderSnapshot.exists) {
          throw Exception("Order does not exist!");
        }

        final currentStatus =
            (orderSnapshot.data()?['status'] ?? 'unknown') as String;

        // ตรวจสอบสถานะอีกครั้งเพื่อยืนยันว่ายังเป็น 'pending'
        if (currentStatus != 'pending') {
          throw Exception(
              "Order status is $currentStatus, not 'pending'. Job was taken.");
        }

        // อัปเดตสถานะและบันทึกพิกัดไรเดอร์
        transaction.update(orderRef, {
          'status': 'accepted', // เปลี่ยนสถานะเป็นรับงานแล้ว
          'riderId': user.uid, // ผูก Rider ID เข้ากับ Order
          'acceptedAt': FieldValue.serverTimestamp(),
          // **[NEW]** บันทึกพิกัด Latitude, Longitude ของไรเดอร์ ณ จุดรับงาน
          'rider_lat': currentPosition.latitude,
          'rider_long': currentPosition.longitude,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('รับงาน $orderId เรียบร้อยแล้ว!')),
        );
        // นำทางไปยังหน้าสถานะการจัดส่ง
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DeliveryStatusScreen()),
        );
      }
    } catch (e) {
      print("Error accepting order: $e");
      if (mounted) {
        final errorMessage = e.toString().contains('Job was taken')
            ? 'งานนี้ถูกรับไปแล้วโดยไรเดอร์คนอื่น'
            : 'เกิดข้อผิดพลาดในการรับงาน';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

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
        // *** [FIX] Assumed DeliveryStatusScreen is defined in rider_status.dart ***
        MaterialPageRoute(builder: (context) => const DeliveryStatusScreen()),
      );
      setState(() {
        _currentIndex = 0;
      });
    } else if (index == 2) {
      // 🚪 ออกจากระบบ
      await FirebaseAuth.instance.signOut(); // **[FIX]** ทำการ Logout จาก Firebase
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
            _buildBody(), // เนื้อหา
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
          // **[UPDATE]** แสดงรูปโปรไฟล์หรือไอคอนโหลด
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 32,
              backgroundImage:
                  _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
              child: _profileImageUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 50,
                      color: darkBlue,
                    ) // Placeholder
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // **[UPDATE]** แสดงชื่อไรเดอร์ที่ดึงมา
              Text(
                _isLoadingData ? "กำลังโหลด..." : "สวัสดีคุณ $_riderName",
                style: const TextStyle(
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
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
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
  // 4. ส่วน Body (อัปเดตใช้ StreamBuilder)
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

          // **[UPDATE]** ใช้ StreamBuilder ดึงรายการ Orders จาก Firebase
          StreamBuilder<List<Order>>(
            stream: _fetchPendingOrdersStream(), // ดึงเฉพาะออเดอร์ที่รอรับงาน
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: primaryGreen));
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text("เกิดข้อผิดพลาดในการโหลด: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Text(
                      "🎉 ไม่มีรายการจัดส่งใหม่ในขณะนี้ 🎉",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }

              final orders = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true, // สำคัญเมื่ออยู่ใน SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), // ปิดการ Scroll ของ ListView
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    // **[UPDATE]** ส่งข้อมูล Order เข้าไปใน Card
                    child: _buildDeliveryCard(order),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------
  // 5. การ์ดข้อมูลการจัดส่ง (ปรับให้แสดงแค่ที่อยู่ผู้ส่งและผู้รับ)
  // ----------------------
  Widget _buildDeliveryCard(Order order) {
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
            // ส่วนแสดงเฉพาะที่อยู่
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Icon และเส้น
                Column(
                  children: <Widget>[
                    // ไอคอนจุดรับ (ผู้ส่ง)
                    const Icon(Icons.outbox,
                        color: primaryGreen, size: 28),
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey.shade400,
                    ),
                    // ไอคอนจุดส่ง (ผู้รับ)
                    const Icon(Icons.location_on,
                        color: locationPinRed, size: 28),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1. ที่อยู่ผู้ส่ง (Pickup Location)
                      const SizedBox(height: 3),
                      const Text(
                        "จุดรับ (ผู้ส่ง):",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54),
                      ),
                      Text(
                        order.pickupLocation,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),

                      // 2. ที่อยู่ผู้รับ (Destination)
                      const Text(
                        "จุดส่ง (ผู้รับ):",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54),
                      ),
                      Text(
                        order.destination,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // **[UPDATE]** เรียกฟังก์ชันรับงาน
                _acceptOrder(order.orderId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
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