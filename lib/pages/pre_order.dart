import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/api/api_service_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'bottom_bar.dart';


class PreOrderScreen extends StatefulWidget {
  const PreOrderScreen({Key? key}) : super(key: key);

  @override
  State<PreOrderScreen> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends State<PreOrderScreen> {
  // --- State Variables ---
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSearching = false;
  Map<String, dynamic>? _userData;

  // -- Form, Search, and Selection Variables --
  final _descriptionController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _newAddressNameController = TextEditingController();
  final _newAddressController = TextEditingController();
  final _addAddressFormKey = GlobalKey<FormState>();
  File? _productImage;
  Map<String, dynamic>? _receiverData;
  List<Map<String, dynamic>> _senderAddresses = [];
  Map<String, dynamic>? _selectedSenderAddress;
  final List<Map<String, dynamic>> _addedItems = []; // <-- รายการสินค้าที่เพิ่ม

  // --- Services & Helpers ---
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();

  // --- Constants ---
  static const Color primaryGreen = Color(0xFF00C853);
  static const Color accentColor = Color(0xFF42A5F5);
  static const int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _receiverPhoneController.dispose();
    _newAddressNameController.dispose();
    _newAddressController.dispose();
    super.dispose();
  }

  // --- Functions ---

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();
      if (mounted) {
        if (docSnapshot.exists) {
          setState(() {
            _userData = docSnapshot.data();
            final List<Map<String, dynamic>> tempAddresses = [];
            if (_userData?['addresses'] != null &&
                _userData!['addresses'] is List) {
              for (var item in (_userData!['addresses'] as List)) {
                if (item is Map) {
                  tempAddresses.add(Map<String, dynamic>.from(item));
                }
              }
            }
            if (_userData?['customer_address'] != null &&
                _userData!['customer_address'].toString().isNotEmpty) {
              final mainAddressString =
                  _userData!['customer_address'].toString();
              final isDuplicate =
                  tempAddresses.any((addr) => addr['address'] == mainAddressString);
              if (!isDuplicate) {
                tempAddresses.insert(0, {
                  'name': 'ที่อยู่หลัก',
                  'address': mainAddressString,
                });
              }
            }
            _senderAddresses = tempAddresses;
            if (_senderAddresses.isNotEmpty) {
              _selectedSenderAddress = _senderAddresses.first;
            } else {
              _selectedSenderAddress = null;
            }
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching user data: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _productImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูป: $e')),
        );
      }
    }
  }

  Future<void> _searchReceiverByPhone() async {
    final phone = _receiverPhoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์เพื่อค้นหา')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _receiverData = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('customer_phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (mounted) {
        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _receiverData = querySnapshot.docs.first.data();
            _receiverData!['id'] = querySnapshot.docs.first.id;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('พบข้อมูลผู้รับ'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ไม่พบข้อมูลผู้รับจากเบอร์โทรนี้'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการค้นหา: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _addItemToList() async {
    if (_selectedSenderAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกที่อยู่ผู้ส่ง')),
      );
      return;
    }
    if (_receiverData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาค้นหาและเลือกข้อมูลผู้รับก่อน')),
      );
      return;
    }
    if (_productImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มรูปภาพสินค้า')),
      );
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรายละเอียดสินค้า')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final imageUrl =
          await _imageUploadService.uploadImageToCloudinary(_productImage!);

      final newItem = {
        'productImageUrl': imageUrl,
        'productDescription': _descriptionController.text,
        'receiverData': _receiverData,
      };

      if (mounted) {
        setState(() {
          _addedItems.add(newItem);
          _productImage = null;
          _descriptionController.clear();
          _receiverPhoneController.clear();
          _receiverData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('เพิ่มรายการสำเร็จ'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitAllOrders() async {
    if (_addedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มสินค้าอย่างน้อย 1 รายการ')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ไม่พบข้อมูลผู้ใช้');

      final batch = FirebaseFirestore.instance.batch();
      final ordersCollection = FirebaseFirestore.instance.collection('orders');

      for (final item in _addedItems) {
        final orderRef = ordersCollection.doc();
        final receiverInfo = item['receiverData'] as Map<String, dynamic>;

        final orderData = {
          'customerId': user.uid,
          'customerName': _userData?['customer_name'] ?? 'ไม่มีชื่อ',
          'pickupLocation': _selectedSenderAddress!['address'] ?? 'ไม่มีที่อยู่',
          'productImageUrl': item['productImageUrl'],
          'productDescription': item['productDescription'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'receiverId': receiverInfo['id'],
          'receiverName': receiverInfo['customer_name'] ?? 'N/A',
          'destination': receiverInfo['customer_address'] ?? 'N/A',
          'receiverPhone': receiverInfo['customer_phone'] ?? 'N/A',
        };
        batch.set(orderRef, orderData);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ส่งออเดอร์ทั้งหมดสำเร็จ!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออเดอร์: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSelectSenderAddressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('เลือกที่อยู่ผู้ส่ง'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ..._senderAddresses.map((address) {
                  return ListTile(
                    title: Text(address['name'] ?? 'ที่อยู่'),
                    subtitle: Text(address['address'] ?? ''),
                    onTap: () {
                      setState(() {
                        _selectedSenderAddress = address;
                      });
                      Navigator.of(dialogContext).pop();
                    },
                  );
                }).toList(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined,
                      color: primaryGreen),
                  title: const Text('เพิ่มที่อยู่ใหม่',
                      style: TextStyle(color: primaryGreen)),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _showAddNewAddressDialog();
                  },
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddNewAddressDialog() async {
    _newAddressNameController.clear();
    _newAddressController.clear();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('เพิ่มที่อยู่ใหม่'),
          content: SingleChildScrollView(
            child: Form(
              key: _addAddressFormKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: _newAddressNameController,
                    decoration: const InputDecoration(
                        labelText: 'ชื่อที่อยู่ (เช่น บ้าน, ที่ทำงาน)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณาใส่ชื่อที่อยู่';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _newAddressController,
                    decoration: const InputDecoration(labelText: 'ที่อยู่เต็ม'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณาใส่ที่อยู่';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('บันทึก'),
              onPressed: () async {
                if (_addAddressFormKey.currentState!.validate()) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final newAddress = {
                    'name': _newAddressNameController.text.trim(),
                    'address': _newAddressController.text.trim(),
                  };

                  try {
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(user.uid)
                        .update({
                      'addresses': FieldValue.arrayUnion([newAddress]),
                    });

                    if (mounted) {
                      setState(() {
                        _senderAddresses.add(newAddress);
                        _selectedSenderAddress = newAddress;
                      });

                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('เพิ่มที่อยู่ใหม่สำเร็จ'),
                            backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ***************************************************************
  // *********************** HELPER WIDGETS ************************
  // ***************************************************************

  Widget _buildSenderInfoCard(
      Map<String, dynamic>? userData, Map<String, dynamic>? selectedAddress) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลผู้ส่ง',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen),
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (userData?['profile_image_url'] != null &&
                          userData!['profile_image_url'].isNotEmpty)
                      ? NetworkImage(userData['profile_image_url'])
                      : null,
                  child: (userData?['profile_image_url'] == null ||
                          userData!['profile_image_url'].isEmpty)
                      ? const Icon(Icons.person, color: primaryGreen)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ชื่อ : ${userData?['customer_name'] ?? '...'}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('เบอร์โทร : ${userData?['customer_phone'] ?? '...'}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                          'ที่อยู่ : ${selectedAddress?['address'] ?? 'กรุณาเลือกที่อยู่'}',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showSelectSenderAddressDialog,
                child: const Text('เปลี่ยนที่อยู่'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ค้นหาข้อมูลผู้รับ',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _receiverPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'กรอกเบอร์โทรผู้รับ...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              _isSearching
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: primaryGreen),
                      onPressed: _searchReceiverByPhone,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiverInfoCard(Map<String, dynamic>? receiverData) {
    if (receiverData == null) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.only(top: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลผู้รับ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (receiverData['profile_image_url'] != null &&
                          receiverData['profile_image_url'].isNotEmpty)
                      ? NetworkImage(receiverData['profile_image_url'])
                      : null,
                  child: (receiverData['profile_image_url'] == null ||
                          receiverData['profile_image_url'].isEmpty)
                      ? const Icon(Icons.person_pin_circle, color: primaryGreen)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ชื่อ : ${receiverData['customer_name'] ?? '...'}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('เบอร์โทร : ${receiverData['customer_phone'] ?? '...'}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                          'ที่อยู่ : ${receiverData['customer_address'] ?? '...'}',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required String text,
      required Color color,
      required VoidCallback onPressed,
      bool isSubmitting = false}) {
    return Center(
      child: Container(
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
          onPressed: isSubmitting ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 0,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Text(
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

  Widget _buildImageAndActionSection() {
    return Column(
      children: [
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
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _productImage != null
                ? Image.file(_productImage!, fit: BoxFit.cover)
                : const Center(
                    child: Icon(Icons.inventory_2_outlined,
                        size: 80, color: Color(0xFFD3A867)),
                  ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSmallActionButton(
              icon: Icons.add_circle_outline,
              text: 'อัปโหลดรูปสินค้า',
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 15),
            _buildSmallActionButton(
              icon: Icons.camera_alt_outlined,
              text: 'ถ่ายรูปสินค้า',
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallActionButton(
      {required IconData icon,
      required String text,
      required VoidCallback onPressed}) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildDescriptionTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: accentColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'รายละเอียดสินค้า',
          hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
          contentPadding: EdgeInsets.all(15.0),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAddedItemsList() {
    if (_addedItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายการสินค้าที่จะจัดส่ง',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333)),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addedItems.length,
            itemBuilder: (context, index) {
              final item = _addedItems[index];
              return _buildAddedItemCard(item, index);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAddedItemCard(Map<String, dynamic> item, int index) {
    final receiverInfo = item['receiverData'] as Map<String, dynamic>;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['productImageUrl'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.error, size: 80),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productDescription'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ผู้รับ: ${receiverInfo['customer_name'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    'ที่อยู่: ${receiverInfo['customer_address'] ?? 'N/A'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () {
                setState(() {
                  _addedItems.removeAt(index);
                });
              },
              tooltip: 'ลบรายการนี้',
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ส่งสินค้า'),
        backgroundColor: const Color(0xFF07AA7C),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 15),
                  _buildSenderInfoCard(_userData, _selectedSenderAddress),
                  const SizedBox(height: 20),
                  _buildReceiverSearch(),
                  _buildReceiverInfoCard(_receiverData),
                  const SizedBox(height: 25),
                  _buildImageAndActionSection(),
                  const SizedBox(height: 20),
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
                  _buildActionButton(
                    text: 'เพิ่มลงในรายการ', // <-- เปลี่ยนข้อความ
                    color: accentColor, // <-- เปลี่ยนสี
                    onPressed: _addItemToList, // <-- เปลี่ยนฟังก์ชัน
                    isSubmitting: _isSubmitting,
                  ),
                  
                  // --- ส่วนรายการสินค้าที่เพิ่มเข้ามา ---
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: BottomBar(
        currentIndex: currentIndex,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }
}


