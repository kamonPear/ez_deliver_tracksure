// -----------------------------------------------------------------------------
// MARK: - Imports (สมมติว่าไฟล์เหล่านี้มีอยู่จริงในโปรเจกต์ของคุณ)
// -----------------------------------------------------------------------------
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Dependencies ที่ต้อง Import เพิ่มเติม (คุณต้องมีไฟล์เหล่านี้ในโปรเจกต์)
// ถ้าคุณรวมโค้ด ParcelDetailScreen ไว้ในไฟล์นี้แล้ว ให้ลบ Import 'package:ez_deliver_tracksure/pages/order_status.dart'; ออก
// และถ้า BottomBar, HomeScreen, EditPro อยู่ในไฟล์อื่น ให้คง Import เหล่านี้ไว้
import 'bottom_bar.dart'; // ดึง BottomBar ที่คุณต้องการมาใช้
import 'all.dart'; // สำหรับ HomeScreen (ต้องมีไฟล์นี้)
import 'EditPro.dart'; // สำหรับ EditPro (ต้องมีไฟล์นี้)
// import 'package:ez_deliver_tracksure/pages/order_status.dart'; // ลบออกถ้า ParcelDetailScreen อยู่ในไฟล์นี้

// -----------------------------------------------------------------------------
// MARK: - Constants
// -----------------------------------------------------------------------------

const Color primaryColor = Color(0xFF00B09B);
const Color secondaryColor = Color(0xFF4C83FF);
const Color tertiaryColor = Color(0xFF0072B5);

// -----------------------------------------------------------------------------
// MARK: - Model: Parcel
// -----------------------------------------------------------------------------

class Parcel {
  final String orderId;
  final String pickupLocation;
  final String productDescription;
  final String status;
  final double pickupLatitude;
  final double pickupLongitude;

  final String? productImageUrl; // URL รูปสินค้า
  final String customerUID; // UID ผู้ส่ง (Sender's UID)

  // ข้อมูลผู้ส่งที่ถูกผูกเข้ามา
  final String customerName;
  final String
  customerPhone; // ใช้เก็บเบอร์ผู้รับจาก order หรือเบอร์ผู้ส่งจาก customers

  final String destination;

  Parcel({
    required this.orderId,
    required this.pickupLocation,
    required this.productDescription,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.productImageUrl,
    required this.customerUID,
    required this.customerName,
    required this.customerPhone,
    required this.destination,
  });

  factory Parcel.fromMap(String orderId, Map<String, dynamic> data) {
    return Parcel(
      orderId: orderId,
      pickupLocation: data['pickupLocation'] ?? 'ไม่ระบุสถานที่รับ',
      productDescription: data['productDescription'] ?? 'ไม่มีคำอธิบาย',
      status: data['status'] ?? 'unknown',
      pickupLatitude: (data['pickup_latitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (data['pickup_longitude'] as num?)?.toDouble() ?? 0.0,
      productImageUrl: data['productImageUrl'],
      // ใช้ field 'customerId' ซึ่งเป็น UID ของผู้ส่ง
      customerUID: data['customerId'] ?? (data['senderId'] ?? ''),
      // ข้อมูลลูกค้าเริ่มต้น (จะถูกอัปเดตภายหลัง)
      customerName: data['customerName'] ?? 'กำลังโหลดผู้ส่ง...',
      // ดึงเบอร์โทรผู้รับจาก orders (Field receiverPhone)
      customerPhone: data['receiverPhone'] ?? 'N/A',
      destination: data['destination'] ?? 'ไม่ระบุที่อยู่จัดส่ง',
    );
  }

  // Factory สำหรับสร้าง Parcel ที่มีข้อมูล Customer ถูกผูกเข้ามาแล้ว
  Parcel copyWithCustomerDetails({required Map<String, dynamic> customerData}) {
    return Parcel(
      orderId: orderId,
      pickupLocation: pickupLocation,
      productDescription: productDescription,
      status: status,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      productImageUrl: productImageUrl,
      customerUID: customerUID,
      destination: destination,
      // ดึงชื่อและเบอร์โทรจาก Customer Data ที่ถูกผูกเข้ามา
      customerName: customerData['customer_name'] ?? customerName,
      // เบอร์โทรผู้ส่ง (ถ้าจำเป็น, มิฉะนั้นใช้เบอร์ผู้รับเดิม)
      customerPhone: customerData['customer_phone'] ?? customerPhone,
    );
  }
}

// -----------------------------------------------------------------------------
// MARK: - Screen: PendingPickupScreen (หน้าจอหลัก)
// -----------------------------------------------------------------------------

class PendingPickupScreen extends StatefulWidget {
  const PendingPickupScreen({super.key});

  @override
  State<PendingPickupScreen> createState() => _PendingPickupScreenState();
}

class _PendingPickupScreenState extends State<PendingPickupScreen> {
  String? _myPhoneNumber;
  late Future<void> _fetchUserPhoneNumberFuture;

  @override
  void initState() {
    super.initState();
    _fetchUserPhoneNumberFuture = _loadPhoneNumber();
  }

  // MARK: - Data Loading / State Management
  Future<void> _loadPhoneNumber() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _myPhoneNumber = userDoc.data()?['customer_phone'];
          debugPrint("Fetched Phone Number: $_myPhoneNumber");
        });
      }
    } catch (e) {
      debugPrint("Error fetching phone number: $e");
    }
  }

  /// จัดการการแตะ Bottom Bar เพื่อนำทางไปยังหน้าจออื่น
  void _handleBottomBarTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EditPro()),
        );
        break;
      // case 1 คือหน้าปัจจุบัน (PendingPickupScreen) จึงไม่ต้องทำอะไร
    }
  }

  // MARK: - Utility: Status Style
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'icon': Icons.access_time_filled,
          'color': Colors.orange,
          'text': 'สถานะ: รอการตอบรับจากไรเดอร์',
        };
      case 'accepted':
      case 'en_route':
        return {
          'icon': Icons.description,
          'color': Colors.indigo,
          'text': 'สถานะ: ไรเดอร์รับออเดอร์แล้ว',
        };
      case 'in_transit':
      case 'picked_up':
        return {
          'icon': Icons.two_wheeler,
          'color': Colors.blue,
          'text': 'สถานะ: ไรเดอร์กำลังนำส่ง',
        };
      case 'delivered':
      case 'completed':
        return {
          'icon': Icons.check_circle,
          'color': primaryColor,
          'text': 'สถานะ: จัดส่งสำเร็จ',
        };
      default:
        return {
          'icon': Icons.help_outline,
          'color': Colors.grey,
          'text': 'สถานะ: $status',
        };
    }
  }

  // MARK: - Data Fetching with Joins
  Stream<QuerySnapshot> _fetchIncomingParcels() {
    final myReceiverId = FirebaseAuth.instance.currentUser?.uid;
    final myPhoneNumber = _myPhoneNumber;

    // 💡 Priority: ใช้เบอร์โทรศัพท์ค้นหาในฟิลด์ 'receiverPhone'
    if (myPhoneNumber != null && myPhoneNumber.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('receiverPhone', isEqualTo: myPhoneNumber)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    // Fallback: ถ้าไม่มีเบอร์โทร ให้ลองค้นหาด้วย UID ในฟิลด์ 'receiverId'
    else if (myReceiverId != null && myReceiverId.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('receiverId', isEqualTo: myReceiverId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    debugPrint("Error: User not logged in (Missing Receiver ID or Phone).");
    return const Stream.empty();
  }

  Stream<List<Parcel>> _fetchParcelsWithSenderDetails() {
    const List<String> allowedStatuses = [
      'pending',
      'accepted',
      'en_route',
      'in_transit',
      'picked_up',
      'delivered',
      'completed',
    ];

    return _fetchIncomingParcels().asyncMap((querySnapshot) async {
      final List<Parcel> initialParcels = querySnapshot.docs
          .map(
            (doc) => Parcel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();

      final List<Parcel> filteredParcels = initialParcels
          .where(
            (parcel) => allowedStatuses.contains(parcel.status.toLowerCase()),
          )
          .toList();

      final List<Future<Parcel>> parcelsWithCustomerFuture = filteredParcels
          .map((parcel) async {
            if (parcel.customerUID.isEmpty) {
              return parcel;
            }

            final customerDoc = await FirebaseFirestore.instance
                .collection('customers')
                .doc(parcel.customerUID) // <-- ใช้ UID ผู้ส่ง
                .get();

            if (customerDoc.exists) {
              final customerData = customerDoc.data() as Map<String, dynamic>;
              return parcel.copyWithCustomerDetails(customerData: customerData);
            }

            return parcel;
          })
          .toList();

      return Future.wait(parcelsWithCustomerFuture);
    });
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, tertiaryColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'พัสดุที่ส่งถึงฉัน',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),

      // FutureBuilder ใช้รอการโหลดเบอร์โทรศัพท์ของผู้ใช้
      body: FutureBuilder<void>(
        future: _fetchUserPhoneNumberFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาดในการดึงเบอร์โทรศัพท์: ${snapshot.error}',
              ),
            );
          }

          // เมื่อโหลดเบอร์โทรศัพท์เสร็จแล้ว (ไม่ว่าจะมีเบอร์หรือไม่ก็ตาม)
          // ให้ใช้ StreamBuilder เพื่อดึงข้อมูลพัสดุ
          return StreamBuilder<List<Parcel>>(
            stream: _fetchParcelsWithSenderDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'เกิดข้อผิดพลาดในการดึงข้อมูล: ${snapshot.error}',
                  ),
                );
              }

              final parcels =
                  snapshot.data ?? []; // ดึง List<Parcel> ที่ผูกข้อมูลแล้ว

              // C. การจัดการข้อมูลว่างเปล่า (No Data)
              if (parcels.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        ' ไม่มีพัสดุที่ส่งถึงคุณในขณะนี้!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      if (_myPhoneNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '(ค้นหาโดย: เบอร์โทร: $_myPhoneNumber)', // แสดงว่ากำลังค้นหาด้วยเบอร์
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              // D. การแสดงผลข้อมูล
              return ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 80),
                itemCount: parcels.length,
                itemBuilder: (context, index) {
                  final parcel = parcels[index];
                  final style = _getStatusStyle(parcel.status.toLowerCase());

                  return _ParcelCard(
                    title: parcel.customerName,
                    subtitle1: style['text'],
                    subtitle2:
                        'โทร: ${parcel.customerPhone} | ที่อยู่ผู้ส่ง: ${parcel.pickupLocation}',
                    icon: style['icon'],
                    statusColor: style['color'],
                    productImageUrl: parcel.productImageUrl,
                    onTap: () {
                      // **ส่วนที่แก้ไข/ตรวจสอบให้แน่ใจว่า ParcelDetailScreen ถูก Import หรือประกาศแล้ว**
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ParcelDetailScreen(parcel: parcel),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),

      // 3. Bottom Navigation Bar
      bottomNavigationBar: BottomBar(
        currentIndex: 1,
        onItemSelected: (index) => _handleBottomBarTap(index),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MARK: - Widget: _ParcelCard (Private Widget)
// -----------------------------------------------------------------------------

class _ParcelCard extends StatelessWidget {
  final String title;
  final String subtitle1;
  final String subtitle2;
  final IconData icon;
  final Color statusColor;
  final String? productImageUrl;
  final VoidCallback? onTap;

  const _ParcelCard({
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.icon,
    required this.statusColor,
    this.productImageUrl,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        productImageUrl != null && productImageUrl!.isNotEmpty;

    Widget imageWidget;

    if (hasImage) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          productImageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Image Load Error: $error. URL: $productImageUrl");
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.broken_image,
                size: 24,
                color: Colors.red,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      imageWidget = Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 30, color: Colors.grey[700]),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image/Icon Widget
                imageWidget,
                const SizedBox(width: 15),

                // 2. Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อผู้ส่ง (Title)
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // สถานะ (Subtitle 1)
                      Text(
                        subtitle1,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // เบอร์โทรผู้ส่ง + ที่อยู่ผู้ส่ง (Subtitle 2)
                      Text(
                        subtitle2,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MARK: - Screen: ParcelDetailScreen (รายละเอียดสถานะพัสดุ)
// -----------------------------------------------------------------------------

class ParcelDetailScreen extends StatelessWidget {
  final Parcel parcel;

  const ParcelDetailScreen({super.key, required this.parcel});

  // Utility: คืนค่าสไตล์ (Icon, Color, Text) ตามสถานะของพัสดุ
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'icon': Icons.access_time_filled,
          'color': Colors.orange,
          'text': 'รอการตอบรับจากไรเดอร์',
        };
      case 'accepted':
      case 'en_route':
        return {
          'icon': Icons.description,
          'color': Colors.indigo,
          'text': 'ไรเดอร์รับออเดอร์แล้ว',
        };
      case 'in_transit':
      case 'picked_up':
        return {
          'icon': Icons.two_wheeler,
          'color': Colors.blue,
          'text': 'ไรเดอร์กำลังนำส่ง',
        };
      case 'delivered':
      case 'completed':
        return {
          'icon': Icons.check_circle,
          'color': primaryColor,
          'text': 'จัดส่งสำเร็จ',
        };
      default:
        return {
          'icon': Icons.help_outline,
          'color': Colors.grey,
          'text': 'สถานะ: ${status.isEmpty ? 'ไม่ระบุ' : status}',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStatusStyle(parcel.status);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, tertiaryColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'รายละเอียดพัสดุ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนแสดงสถานะหลัก (Status Card)
            _StatusCard(style: style, parcel: parcel),
            const SizedBox(height: 16),

            // ส่วนแสดงรูปภาพสินค้า (ถ้ามี)
            if (parcel.productImageUrl != null &&
                parcel.productImageUrl!.isNotEmpty)
              _ProductImage(productImageUrl: parcel.productImageUrl!),
            if (parcel.productImageUrl != null &&
                parcel.productImageUrl!.isNotEmpty)
              const SizedBox(height: 16),

            // รายละเอียดพัสดุ
            _DetailSection(
              title: 'รายละเอียดพัสดุ',
              children: [
                _DetailRow(label: 'หมายเลขคำสั่งซื้อ:', value: parcel.orderId),
                _DetailRow(
                  label: 'รายละเอียดสินค้า:',
                  value: parcel.productDescription,
                ),
              ],
            ),

            const Divider(height: 32),

            // ข้อมูลผู้รับ/จัดส่ง
            _DetailSection(
              title: 'ข้อมูลการจัดส่ง (Receiver/Destination)',
              children: [
                _DetailRow(label: 'ที่อยู่จัดส่ง:', value: parcel.destination),
                _DetailRow(
                  label: 'เบอร์โทรผู้รับ:',
                  value: parcel.customerPhone,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MARK: - Widget: Detail Components (สำหรับ ParcelDetailScreen)
// -----------------------------------------------------------------------------

/// Card แสดงสถานะปัจจุบัน
class _StatusCard extends StatelessWidget {
  final Map<String, dynamic> style;
  final Parcel parcel;
  const _StatusCard({required this.style, required this.parcel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: style['color'].withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สถานะปัจจุบัน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: style['color'],
              ),
            ),
            const Divider(color: Colors.black12),
            Row(
              children: [
                Icon(style['icon'], color: style['color'], size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    style['text'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: style['color'],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ส่วนแสดงรูปภาพสินค้าขนาดใหญ่
class _ProductImage extends StatelessWidget {
  final String productImageUrl;
  const _ProductImage({required this.productImageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รูปภาพสินค้า:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            productImageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.red[100],
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 50, color: Colors.red),
                    SizedBox(height: 8),
                    Text(
                      'ไม่สามารถโหลดรูปภาพได้',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ส่วนหัวข้อสำหรับกลุ่มรายละเอียด
class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

/// แถวสำหรับแสดงรายละเอียด
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130, // กำหนดความกว้างคงที่สำหรับ Label
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
