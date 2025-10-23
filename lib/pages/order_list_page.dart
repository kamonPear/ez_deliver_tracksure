//
// 📍 ไฟล์ใหม่: order_list_page.dart
//
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/pages/EditPro.dart';
import 'package:ez_deliver_tracksure/pages/all.dart';
import 'package:ez_deliver_tracksure/pages/products.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'bottom_bar.dart';
import 'product_status.dart'; // <--- import หน้า ProductStatus ที่เราทำไว้

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<DocumentSnapshot> _orders = [];
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchOrders();
  }

    void _onItemTapped(int index) {
    // If the tapped item is the current one, do nothing.
    if (_selectedIndex == index) return;

    // We use Navigator.push so that the back button works as expected.
    // The state of _selectedIndex is only changed for the home button.
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        // Navigate to the Products (History) page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Products()),
        );
        break;
      case 2:
        // Navigate to the EditPro (Others) page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditPro()),
        );
        break;
    }
  }
  // 1. หาว่าผู้ใช้ที่ล็อกอินคือใคร
  Future<void> _loadUserDataAndFetchOrders() async {
    _user = FirebaseAuth.instance.currentUser;

    if (_user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "ไม่พบข้อมูลผู้ใช้, กรุณาล็อกอินใหม่";
        });
      }
    } else {
      _fetchOrders(); // ถ้าเจอก็ไปดึงออเดอร์
    }
  }

  // 2. ดึงออเดอร์ทั้งหมดที่ตรงกับ ID ของผู้ใช้
  Future<void> _fetchOrders() async {
    if (_user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where(
            'customerId',
            isEqualTo: _user!.uid,
          ) // <--- ค้นหาเฉพาะออเดอร์ของเรา
          .orderBy('createdAt', descending: true) // <--- เรียงจากใหม่ไปเก่า
          .get();

      if (mounted) {
        setState(() {
          _orders = querySnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "เกิดข้อผิดพลาด: ${e.toString()}";
        });
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_orders.isEmpty) {
      return const Center(child: Text("คุณยังไม่มีรายการออเดอร์"));
    }

    // 3. แสดงผลเป็น ListView
    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final orderDoc = _orders[index];
        final orderId = orderDoc.id; // <--- นี่คือ ID ที่เราจะส่งต่อ
        final data = orderDoc.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          child: ListTile(
            leading: data['productImageUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.network(
                      data['productImageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    ),
                  )
                : const Icon(Icons.inventory_2_outlined, size: 50),
            title: Text(
              data['productDescription'] ?? 'ไม่มีรายละเอียด',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'ผู้รับ: ${data['receiverName'] ?? 'N/A'}\nสถานะ: ${data['status'] ?? 'N/A'}',
            ),
            trailing: const Icon(Icons.chevron_right),
            isThreeLine: true,
            // 4. เมื่อกดที่รายการ
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // 5. ส่ง orderId ไปยังหน้า ProductStatus
                  builder: (context) => ProductStatus(orderId: orderId),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการออเดอร์ของฉัน'),
        backgroundColor: const Color(0xFF00A859),
      ),
      body: _buildBody(),
     bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
