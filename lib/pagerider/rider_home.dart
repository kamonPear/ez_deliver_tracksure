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
// **[NEW]** เพิ่ม CachedNetworkImage สำหรับการจัดการรูปภาพ (แนะนำ)
// ignore: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart'; // <-- ต้องเพิ่ม package: cached_network_image ใน pubspec.yaml ด้วย
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

// ----------------------
// 1. กำหนดค่าสี (Colors)
// ----------------------
const Color primaryGreen = Color(0xFF00C853); // เขียวหลัก
const Color darkBlue = Color(0xFF1A237E); // น้ำเงินเข้ม (สำหรับ Gradient)
const Color secondaryGreen = Color(0xFF4CAF50); // เขียวปุ่ม 'รับงาน'
const Color darkBottomNav = Color(
  0xFF00796B,
); // เขียวอมน้ำเงิน (สำหรับ Bottom Nav)
const Color locationPinRed = Color(0xFFF44336); // แดงหมุด
const Color packageBrown = Color(0xFF8D6E63); // น้ำตาลไอคอนพัสดุ

// ----------------------
// **[NEW]** 1.1 Order Model สำหรับจัดการข้อมูล
// ----------------------
class Order {
  final String orderId;
  final DateTime? createdDate;
  final String customerName;
  final String destination;
  final String pickupLocation;
  final String productDescription;
  final String receiverName;
  final String receiverPhone;
  final String? productImageUrl;
  final double? pickupLat;
  final double? pickupLong;
  final double? destLat;
  final double? destLong;

  final String status;

  Order({
    required this.orderId,
    this.createdDate,
    required this.customerName,
    required this.destination,
    required this.pickupLocation,
    required this.productDescription,
    required this.receiverName,
    required this.receiverPhone,
    this.productImageUrl,
    this.status = 'pending',
    this.pickupLat,
    this.pickupLong,
    this.destLat,
    this.destLong,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Order data is null for document ${doc.id}");
    }

    final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;

    return Order(
      orderId: doc.id,
      createdDate: createdAtTimestamp?.toDate(),
      customerName: data['customerName'] ?? 'ไม่ระบุลูกค้า',
      destination: data['destination'] ?? 'ไม่ระบุปลายทาง',
      pickupLocation: data['pickupLocation'] ?? 'ไม่ระบุต้นทาง',
      productDescription: data['productDescription'] ?? 'ไม่ระบุสินค้า',
      receiverName: data['receiverName'] ?? 'ไม่ระบุผู้รับ',
      receiverPhone: data['receiverPhone'] ?? 'ไม่ระบุเบอร์โทร',
      productImageUrl: data['productImageUrl'],
      status: data['status'] ?? 'pending',
      // แปลงข้อมูลพิกัดจาก num? เป็น double?
      pickupLat: (data['pickup_latitude'] as num?)?.toDouble(),
      pickupLong: (data['pickup_longitude'] as num?)?.toDouble(),
      destLat: (data['destination_latitude'] as num?)?.toDouble(),
      destLong: (data['destination_longitude'] as num?)?.toDouble(),
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

  String _riderName = "กำลังโหลด...";
  String? _profileImageUrl;
  bool _isLoadingData = true;
  // [NEW] เพิ่มตัวแปรสำหรับสถานะกำลังรับงาน
  bool _isAcceptingOrder = false;
  String?
  _acceptingOrderId; // เก็บ ID งานที่กำลังพยายามรับ (Optional แต่ช่วยให้ชัดเจนขึ้น)

  @override
  void initState() {
    super.initState();
    _fetchRiderData();
  }

  Stream<List<Order>> _fetchPendingOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList(),
        );
  }

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

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเปิด Location Service เพื่อรับงาน'),
          ),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('คุณต้องอนุญาตให้เข้าถึงตำแหน่งเพื่อรับงาน'),
            ),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission ถูกปฏิเสธถาวร, ไม่สามารถรับงานได้'),
          ),
        );
      }
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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

  Future<bool> _checkOngoingOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final ongoingOrders = await FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: user.uid)
          .where('status', whereIn: ['accepted', 'on_delivery'])
          .limit(1)
          .get();

      return ongoingOrders.docs.isNotEmpty;
    } catch (e) {
      print("Error checking ongoing order: $e");
      return false;
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    // [NEW] ป้องกันการกดซ้ำ ถ้ากำลังรับงานอื่นอยู่
    if (_isAcceptingOrder) {
      print("Already trying to accept an order...");
      return;
    }

    // [NEW] เริ่มสถานะ Loading
    if (mounted) {
      setState(() {
        _isAcceptingOrder = true;
        _acceptingOrderId = orderId; // ระบุว่ากำลังรับงานไหน
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // ... (SnackBar กรุณาเข้าสู่ระบบ) ...
      // [NEW] หยุด Loading ถ้าเกิด Error เร็ว
      if (mounted) setState(() => _isAcceptingOrder = false);
      return;
    }

    // 1. ตรวจสอบงานที่กำลังทำอยู่
    final hasOngoingOrder = await _checkOngoingOrder();
    if (hasOngoingOrder) {
      // ... (SnackBar มีงานค้าง) ...
      // [NEW] หยุด Loading
      if (mounted) setState(() => _isAcceptingOrder = false);
      return;
    }

    // 2. ดึงตำแหน่งปัจจุบันของไรเดอร์
    final currentPosition = await _getCurrentLocation();
    if (currentPosition == null) {
      // ... (SnackBar ดึงพิกัดไม่ได้) ...
      // [NEW] หยุด Loading
      if (mounted) setState(() => _isAcceptingOrder = false);
      return;
    }

    // 3. ดำเนินการรับงาน (Transaction)
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // ... (โค้ด Transaction เหมือนเดิม) ...
        final orderRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId);
        final orderSnapshot = await transaction.get(orderRef);

        if (!orderSnapshot.exists) {
          throw Exception("Order does not exist!");
        }

        final currentStatus =
            (orderSnapshot.data()?['status'] ?? 'unknown') as String;

        if (currentStatus != 'pending') {
          throw Exception(
            "Order status is $currentStatus, not 'pending'. Job was taken.",
          );
        }

        transaction.update(orderRef, {
          'status': 'accepted',
          'riderId': user.uid,
          'acceptedAt': FieldValue.serverTimestamp(),
          'rider_lat': currentPosition.latitude,
          'rider_long': currentPosition.longitude,
        });
      });

      // ถ้า Transaction สำเร็จ
      if (mounted) {
        // [MODIFIED] ใช้ context ที่ยังอยู่ (ก่อน Navigator.push)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('รับงาน $orderId เรียบร้อยแล้ว!')),
        );
        // นำทางไปยังหน้าสถานะ
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      // [NEW] หยุดสถานะ Loading ไม่ว่าจะสำเร็จหรือล้มเหลว
      if (mounted) {
        setState(() {
          _isAcceptingOrder = false;
          _acceptingOrderId = null; // เคลียร์ ID งานที่กำลังรับ
        });
      }
    }
  }

  void _onItemTapped(int index) async {
    if (index == 0) {
      setState(() {
        _currentIndex = 0;
      });
    } else if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeliveryStatusScreen()),
      );
      setState(() {
        _currentIndex = 0;
      });
    } else if (index == 2) {
      await FirebaseAuth.instance.signOut();
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
          children: <Widget>[_buildHeader(context), _buildBody()],
        ),
      ),
      bottomNavigationBar: StatusBottomBar(
        currentIndex: _currentIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }

  // ----------------------
  // 3. ส่วน Header (ไม่เปลี่ยนแปลง)
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
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 32,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: _profileImageUrl == null
                  ? const Icon(Icons.person, size: 50, color: darkBlue)
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _isLoadingData ? "กำลังโหลด..." : "สวัสดีคุณ $_riderName",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
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
  // 4. ส่วน Body (ไม่เปลี่ยนแปลง)
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

          StreamBuilder<List<Order>>(
            stream: _fetchPendingOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text("เกิดข้อผิดพลาดในการโหลด: ${snapshot.error}"),
                );
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
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
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

  // ----------------------------------------------------
  // 5. การ์ดข้อมูลการจัดส่ง (เพิ่มรูปภาพและวิดเจ็ตแผนที่)
  // ----------------------------------------------------
  Widget _buildDeliveryCard(Order order) {
    // ฟังก์ชันช่วยแสดงพิกัด
    String _formatLocation(double? lat, double? long) {
      if (lat == null || long == null) return "ไม่ระบุพิกัด";
      return "${lat.toStringAsFixed(4)}, ${long.toStringAsFixed(4)}"; // แสดงทศนิยม 4 ตำแหน่ง
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --------------------
            // **[NEW SECTION]** รูปภาพสินค้า
            // --------------------
            if (order.productImageUrl != null &&
                order.productImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey.shade200, // สีพื้นหลังขณะโหลด
                  child: CachedNetworkImage(
                    // ใช้ CachedNetworkImage เพื่อประสิทธิภาพที่ดีกว่า
                    imageUrl: order.productImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ),
              )
            else
              // กรณีไม่มีรูป
              Container(
                height: 50,
                alignment: Alignment.center,
                child: const Text(
                  "ไม่มีรูปภาพสินค้าแนบมา",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 15),

            // --------------------
            // รายละเอียดสินค้า
            // --------------------
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: packageBrown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "สินค้า: ${order.productDescription}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 25),

            // --------------------
            // ที่อยู่และพิกัด
            // --------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const Icon(Icons.outbox, color: primaryGreen, size: 28),
                    Container(
                      width: 2,
                      height: 50,
                      color: Colors.grey.shade400,
                    ),
                    const Icon(
                      Icons.location_on,
                      color: locationPinRed,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1. ที่อยู่ผู้ส่ง (Pickup Location)
                      const Text(
                        "จุดรับ (ผู้ส่ง):",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        order.pickupLocation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "พิกัด: ${_formatLocation(order.pickupLat, order.pickupLong)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 2. ที่อยู่ผู้รับ (Destination)
                      const Text(
                        "จุดส่ง (ผู้รับ):",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        order.destination,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "พิกัด: ${_formatLocation(order.destLat, order.destLong)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            // --------------------
            // **[NEW SECTION]** แผนที่แสดงหมุด
            // --------------------
            _buildOpenStreetMap(order),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                // [MODIFIED] ถ้ากำลังรับงาน (อันไหนก็ได้) หรือนี่คืองานที่กำลังรับ ให้ disable ปุ่ม
                onPressed: (_isAcceptingOrder)
                    ? null // ปุ่มกดไม่ได้
                    : () {
                        _acceptOrder(order.orderId);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryGreen,
                  // [NEW] ทำให้ปุ่มเป็นสีเทาถ้ากดไม่ได้
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical:
                        8, // ลด Padding แนวตั้งเล็กน้อยเพื่อให้พอดีกับ Loading
                  ),
                  elevation: 3,
                ),
                child: (_isAcceptingOrder && _acceptingOrderId == order.orderId)
                    // [NEW] แสดง Loading Indicator ขนาดเล็กถ้ากำลังรับงานนี้
                    ? const SizedBox(
                        height: 20, // กำหนดขนาด Indicator
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    // แสดง Text ปกติ
                    : const Text(
                        "รับงาน",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // **[NEW WIDGET]** วิดเจ็ตสำหรับแสดงแผนที่ (Placeholder)
  // ----------------------------------------------------
  Widget _buildOpenStreetMap(Order order) {
    // ตรวจสอบว่ามีพิกัดครบถ้วนหรือไม่
    final hasCoords =
        order.pickupLat != null &&
        order.pickupLong != null &&
        order.destLat != null &&
        order.destLong != null;

    if (!hasCoords) {
      return const Center(
        child: Text(
          "ไม่สามารถแสดงแผนที่ได้เนื่องจากพิกัดไม่สมบูรณ์",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    // สร้างจุด LatLng สำหรับหมุด
    final latlong.LatLng pickupPoint = latlong.LatLng(
      order.pickupLat!,
      order.pickupLong!,
    );
    final latlong.LatLng destPoint = latlong.LatLng(
      order.destLat!,
      order.destLong!,
    );

    // สร้างรายการหมุด
    final List<Marker> markers = [
      // หมุดจุดรับ (สีเขียว)
      Marker(
        width: 80.0,
        height: 80.0,
        point: pickupPoint,
        child: const Column(
          children: [
            Icon(Icons.location_pin, color: primaryGreen, size: 40),
            Text(
              "จุดรับ",
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // หมุดจุดส่ง (สีแดง)
      Marker(
        width: 80.0,
        height: 80.0,
        point: destPoint,
        child: const Column(
          children: [
            Icon(Icons.location_pin, color: locationPinRed, size: 40),
            Text(
              "จุดส่ง",
              style: TextStyle(
                color: locationPinRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ตำแหน่งจัดส่งบนแผนที่:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200, // เพิ่มความสูงแผนที่เล็กน้อย
          clipBehavior: Clip.hardEdge, // ตัดขอบให้โค้งมน
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: pickupPoint, // ให้แผนที่เริ่มต้นที่จุดรับ
              initialZoom: 13.0, // สามารถปรับค่าซูมได้ตามต้องการ
            ),
            children: [
              // 1. TileLayer (ตัวแผนที่ฐาน)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ez_deliver_tracksure',
              ),
              // 2. MarkerLayer (ชั้นของหมุด)
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      ],
    );
  }
}
