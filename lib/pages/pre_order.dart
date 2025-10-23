import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez_deliver_tracksure/api/api_service_image.dart'; // <--- ตรวจสอบว่า path นี้ถูกต้อง
import 'package:ez_deliver_tracksure/gps/mapgps.dart';
import 'package:ez_deliver_tracksure/pages/EditPro.dart';
import 'package:ez_deliver_tracksure/pages/all.dart';
import 'package:ez_deliver_tracksure/pages/products.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'bottom_bar.dart'; // <--- ตรวจสอบว่า path นี้ถูกต้อง

// 📍 --- เพิ่ม 2 บรรทัดนี้ --- 📍
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// 📍 --- และเพิ่มบรรทัดนี้ --- 📍

class PreOrderScreen extends StatefulWidget {
  const PreOrderScreen({Key? key}) : super(key: key);

  @override
  State<PreOrderScreen> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends State<PreOrderScreen> {
  // --- State Variables ---
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSearching = false;
  Map<String, dynamic>? _userData;

  // -- Form, Search, and Selection Variables --
  final _descriptionController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _newAddressNameController = TextEditingController();
  // 📍 --- ลบ _newAddressController --- 📍
  final _addAddressFormKey = GlobalKey<FormState>();
  File? _productImage;
  Map<String, dynamic>? _receiverData;
  List<Map<String, dynamic>> _senderAddresses = [];
  Map<String, dynamic>? _selectedSenderAddress;
  final List<Map<String, dynamic>> _addedItems = []; // <-- รายการสินค้าที่เพิ่ม

  // --- 📍 Customer List Variables (เพิ่มใหม่) 📍 ---
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoadingCustomers = false;
  final _receiverListSearchController = TextEditingController();
  // ------------------------------------------

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
    _fetchAllCustomers(); // <-- 📍 เรียกฟังก์ชันดึงรายชื่อลูกค้า
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _receiverPhoneController.dispose();
    _newAddressNameController.dispose();
    // 📍 --- ลบ _newAddressController.dispose() --- 📍
    _receiverListSearchController.dispose(); // <-- 📍 เพิ่ม dispose
    super.dispose();
  }

  // --- Functions ---

  // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
  //         <--- จุดแก้ไขที่ 1
  // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
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
              final mainAddressString = _userData!['customer_address']
                  .toString();
              final isDuplicate = tempAddresses.any(
                (addr) => addr['address'] == mainAddressString,
              );
              if (!isDuplicate) {
                // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
                // ดึงค่า latitude และ longitude (Number) โดยตรง
                // ใช้วิธี (as num?)?.toDouble() เพื่อความปลอดภัย
                final double? lat = (_userData!['latitude'] as num?)
                    ?.toDouble();
                final double? lng = (_userData!['longitude'] as num?)
                    ?.toDouble();
                // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

                tempAddresses.insert(0, {
                  'name': 'ที่อยู่หลัก',
                  'address': mainAddressString,
                  'latitude': lat, // <-- ใช้ค่าที่แยกได้
                  'longitude': lng, // <-- ใช้ค่าที่แยกได้
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
  // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

  // --- 📍 ฟังก์ชันดึงรายชื่อลูกค้าทั้งหมด (เพิ่มใหม่) 📍 ---
  Future<void> _fetchAllCustomers() async {
    if (mounted) {
      setState(() {
        _isLoadingCustomers = true;
      });
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();

      final user = FirebaseAuth.instance.currentUser;
      final List<Map<String, dynamic>> customers = [];

      for (var doc in querySnapshot.docs) {
        // กรองผู้ใช้ปัจจุบันออกจากรายชื่อผู้รับ
        if (user != null && doc.id == user.uid) {
          continue; // ข้าม user ตัวเอง
        }
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // เพิ่ม ID ของ doc เข้าไปใน map ด้วย
        customers.add(data);
      }

      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _filteredCustomers = customers;
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCustomers = false;
        });
      }
      print("Error fetching all customers: $e");
    }
  }
  // ------------------------------------------

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
              content: Text('พบข้อมูลผู้รับ'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบข้อมูลผู้รับจากเบอร์โทรนี้'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการค้นหา: $e'),
            backgroundColor: Colors.red,
          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกที่อยู่ผู้ส่ง')));
      return;
    }
    if (_receiverData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาค้นหาและเลือกข้อมูลผู้รับก่อน')),
      );
      return;
    }
    if (_productImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเพิ่มรูปภาพสินค้า')));
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
      final imageUrl = await _imageUploadService.uploadImageToCloudinary(
        _productImage!,
      );

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
            content: Text('เพิ่มรายการสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
  //         <--- จุดแก้ไขที่ 2
  // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
  Future<void> _submitAllOrders() async {
    if (_addedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มสินค้าอย่างน้อย 1 รายการ')),
      );
      return; //
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

        // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
        // ดึงค่า latitude และ longitude (Number) ของผู้รับโดยตรง
        final double? destLat = (receiverInfo['latitude'] as num?)?.toDouble();
        final double? destLng = (receiverInfo['longitude'] as num?)?.toDouble();
        // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

        final orderData = {
          'customerId': user.uid,
          'customerName': _userData?['customer_name'] ?? 'ไม่มีชื่อ',
          'pickupLocation':
              _selectedSenderAddress!['address'] ?? 'ไม่มีที่อยู่',

          // --- ส่วนของผู้ส่ง (อันนี้ดึงมาจาก _selectedSenderAddress ซึ่งถูกแล้ว) ---
          'pickup_latitude': _selectedSenderAddress!['latitude'] ?? null,
          'pickup_longitude': _selectedSenderAddress!['longitude'] ?? null,

          // ----------------------------------
          'productImageUrl': item['productImageUrl'],
          'productDescription': item['productDescription'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'receiverId': receiverInfo['id'],
          'receiverName': receiverInfo['customer_name'] ?? 'N/A',
          'destination': receiverInfo['customer_address'] ?? 'N/A',
          'receiverPhone': receiverInfo['customer_phone'] ?? 'N/A',

          // --- แก้ไข 2 บรรทัดนี้ (ของผู้รับ) ---
          'destination_latitude': destLat, // <-- ใช้ค่าที่แยกได้
          'destination_longitude': destLng, // <-- ใช้ค่าที่แยกได้
        };

        batch.set(orderRef, orderData);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งออเดอร์ทั้งหมดสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
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
  // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

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
                  leading: const Icon(
                    Icons.add_location_alt_outlined,
                    color: primaryGreen,
                  ),
                  title: const Text(
                    'เพิ่มที่อยู่ใหม่',
                    style: TextStyle(color: primaryGreen),
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop(); // 📍 ปิด Dialog นี้ก่อน
                    _showAddNewAddressDialog(); // 📍 แล้วค่อยเปิด Dialog ใหม่
                  },
                ),
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

  // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
  //         <--- 📍 จุดแก้ไขที่ 3 (แก้ไขใหม่ทั้งหมด) 📍
  // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
  Future<void> _showAddNewAddressDialog() async {
    // This map will hold the result from Mapgps.dart
    Map<String, dynamic>? _selectedMapData;
    _newAddressNameController.clear(); // Clear the name controller

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิด dialog เเมื่อแตะข้างนอก
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the state of the dialog content
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('เพิ่มที่อยู่ใหม่'),
              content: SingleChildScrollView(
                child: Form(
                  key: _addAddressFormKey,
                  child: ListBody(
                    children: <Widget>[
                      // 1. Input for the address name (e.g., "Home", "Work")
                      TextFormField(
                        controller: _newAddressNameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อที่อยู่ (เช่น บ้าน, ที่ทำงาน)',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาใส่ชื่อที่อยู่';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 2. Button to open the map
                      OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('เลือกตำแหน่งบนแผนที่'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryGreen,
                          side: const BorderSide(color: primaryGreen),
                        ),
                        onPressed: () async {
                          // Navigate to Mapgps screen
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Mapgps(),
                            ),
                          );

                          // When the map screen returns a result
                          if (result != null &&
                              result is Map<String, dynamic>) {
                            dialogSetState(() {
                              _selectedMapData = result;

                              // 📍 --- CODE ที่เพิ่มเข้ามา --- 📍
                              // กรอกชื่อที่อยู่ให้อัตโนมัติด้วยที่อยู่ที่ได้จากแผนที่
                              // ผู้ใช้ยังสามารถแก้ไขเองได้
                              _newAddressNameController.text =
                                  _selectedMapData?['address'] as String? ?? '';
                              // 📍 --------------------------- 📍
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 3. Display the selected address
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedMapData?['address'] as String? ??
                              'ยังไม่ได้เลือกตำแหน่ง',
                          style: TextStyle(
                            color: _selectedMapData == null
                                ? Colors.grey[600]
                                : Colors.black,
                            fontStyle: _selectedMapData == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    // Validate both the name and the map selection
                    if (_addAddressFormKey.currentState!.validate() &&
                        _selectedMapData != null) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      // Get data from map result
                      final LatLng latlng =
                          _selectedMapData!['latlng'] as LatLng;
                      final String address =
                          _selectedMapData!['address'] as String;

                      // Create the new address map
                      final newAddress = {
                        'name': _newAddressNameController.text.trim(),
                        'address': address, // <-- Use address from map
                        'latitude': latlng.latitude, // <-- Use lat from map
                        'longitude': latlng.longitude, // <-- Use lng from map
                      };

                      try {
                        // Save to Firestore
                        await FirebaseFirestore.instance
                            .collection('customers')
                            .doc(user.uid)
                            .update({
                              'addresses': FieldValue.arrayUnion([newAddress]),
                            });

                        if (mounted) {
                          // Update local state
                          setState(() {
                            _senderAddresses.add(newAddress);
                            _selectedSenderAddress = newAddress;
                          });

                          Navigator.of(dialogContext).pop(); // Close the dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('เพิ่มที่อยู่ใหม่สำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else if (_selectedMapData == null) {
                      // Show error if map was not used
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณาเลือกตำแหน่งบนแผนที่'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

  // --- 📍 ฟังก์ชันสำหรับฟิลเตอร์รายชื่อ (ใช้ใน Dialog) (เพิ่มใหม่) 📍 ---
  void _filterCustomers(String query, StateSetter dialogSetState) {
    if (query.isEmpty) {
      dialogSetState(() {
        _filteredCustomers = _allCustomers;
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final filteredList = _allCustomers.where((customer) {
      final name = customer['customer_name']?.toString().toLowerCase() ?? '';
      final phone = customer['customer_phone']?.toString().toLowerCase() ?? '';
      return name.contains(lowerCaseQuery) || phone.contains(lowerCaseQuery);
    }).toList();

    dialogSetState(() {
      _filteredCustomers = filteredList;
    });
  }

  // --- 📍 ฟังก์ชันสำหรับแสดง Dialog เลือกผู้รับ (เพิ่มใหม่) 📍 ---
  void _showSelectReceiverDialog() {
    // รีเซ็ต list ที่ filter ไว้ก่อนเปิด
    _filteredCustomers = _allCustomers;
    _receiverListSearchController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('เลือกผู้รับ'),
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    TextField(
                      controller: _receiverListSearchController,
                      decoration: InputDecoration(
                        labelText: 'ค้นหาชื่อ หรือ เบอร์โทร',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onChanged: (value) {
                        _filterCustomers(value, dialogSetState);
                      },
                    ),
                    const SizedBox(height: 16),
                    _isLoadingCustomers
                        ? const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : Expanded(
                            child: _filteredCustomers.isEmpty
                                ? const Center(child: Text('ไม่พบข้อมูล'))
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredCustomers.length,
                                    itemBuilder: (context, index) {
                                      final customer =
                                          _filteredCustomers[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage:
                                              (customer['profile_image_url'] !=
                                                      null &&
                                                  customer['profile_image_url']
                                                      .isNotEmpty)
                                              ? NetworkImage(
                                                  customer['profile_image_url'],
                                                )
                                              : null,
                                          child:
                                              (customer['profile_image_url'] ==
                                                      null ||
                                                  customer['profile_image_url']
                                                      .isEmpty)
                                              ? const Icon(
                                                  Icons.person,
                                                  color: primaryGreen,
                                                )
                                              : null,
                                        ),
                                        title: Text(
                                          customer['customer_name'] ?? 'N/A',
                                        ),
                                        subtitle: Text(
                                          customer['customer_phone'] ?? 'N/A',
                                        ),
                                        onTap: () {
                                          // เมื่อเลือก user
                                          setState(() {
                                            _receiverData = customer;
                                            // (Optional) อาจจะใส่เบอร์โทรในช่องค้นหาให้ด้วย
                                            _receiverPhoneController.text =
                                                customer['customer_phone'] ??
                                                '';
                                          });
                                          Navigator.of(dialogContext).pop();
                                        },
                                      );
                                    },
                                  ),
                          ),
                  ],
                ),
              ),
              actions: [
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
      },
    );
  }
  // ------------------------------------------

  // ***************************************************************
  // *********************** HELPER WIDGETS ************************
  // ***************************************************************

  Widget _buildSenderInfoCard(
    Map<String, dynamic>? userData,
    Map<String, dynamic>? selectedAddress,
  ) {
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
                color: primaryGreen,
              ),
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      (userData?['profile_image_url'] != null &&
                          userData!['profile_image_url'].isNotEmpty)
                      ? NetworkImage(userData['profile_image_url'])
                      : null,
                  child:
                      (userData?['profile_image_url'] == null ||
                          userData!['profile_image_url'].isEmpty)
                      ? const Icon(Icons.person, color: primaryGreen)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ชื่อ : ${userData?['customer_name'] ?? '...'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เบอร์โทร : ${userData?['customer_phone'] ?? '...'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ที่อยู่ : ${selectedAddress?['address'] ?? 'กรุณาเลือกที่อยู่'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // ส่วนนี้จะแสดงผลถูกต้อง เมื่อ _selectedSenderAddress มีค่าที่ถูกต้อง
                        'พิกัด: ${selectedAddress?['latitude'] ?? 'N/A'}, ${selectedAddress?['longitude'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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
            ),
          ],
        ),
      ),
    );
  }

  // --- 📍 Widget ค้นหาผู้รับ (แก้ไข) 📍 ---
  Widget _buildReceiverSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ค้นหาข้อมูลผู้รับ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              _isSearching
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: primaryGreen),
                      onPressed: _searchReceiverByPhone,
                    ),
            ],
          ),
        ),
        // --- 📍 ส่วนที่เพิ่มเข้ามา 📍 ---
        const SizedBox(height: 8),
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.people_outline),
            label: const Text('หรือเลือกจากรายชื่อทั้งหมด'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryGreen,
              side: const BorderSide(color: primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: _showSelectReceiverDialog, // <-- เรียก Dialog
          ),
        ),
        // --- 📍 ---------------- 📍 ---
      ],
    );
  }
  // ------------------------------------------

  // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
  //         <--- 📍 จุดแก้ไขที่ 4 (ใช้ flutter_map) 📍
  // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
  Widget _buildReceiverInfoCard(Map<String, dynamic>? receiverData) {
    if (receiverData == null) {
      return const SizedBox.shrink();
    }

    // ▼▼▼▼▼▼ [ CODE ที่แก้ไข ] ▼▼▼▼▼▼
    // ดึงค่า lat/lng ของผู้รับ
    final double? latNum = (receiverData['latitude'] as num?)?.toDouble();
    final double? lngNum = (receiverData['longitude'] as num?)?.toDouble();
    String lat = latNum?.toString() ?? 'N/A';
    String lng = lngNum?.toString() ?? 'N/A';

    // --- สร้างตัวแปรสำหรับแผนที่ ---
    LatLng? receiverLocation;
    List<Marker> markers = []; // ใช้งาน Marker จาก flutter_map

    if (latNum != null && lngNum != null) {
      receiverLocation = LatLng(latNum, lngNum); // ใช้งาน LatLng จาก latlong2
      markers.add(
        Marker(
          point: receiverLocation,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, size: 45, color: Colors.red),
        ),
      );
    }
    // ▲▲▲▲▲▲ [ CODE ที่แก้ไข ] ▲▲▲▲▲▲

    return Card(
      margin: const EdgeInsets.only(top: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias, // <-- เพิ่มเพื่อให้ขอบแผนที่โค้งมนตาม Card
      child: Column(
        // <-- เปลี่ยนจาก Padding เป็น Column
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // <-- เพิ่ม Padding หุ้มส่วนข้อมูลเดิม
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูลผู้รับ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          (receiverData['profile_image_url'] != null &&
                              receiverData['profile_image_url'].isNotEmpty)
                          ? NetworkImage(receiverData['profile_image_url'])
                          : null,
                      child:
                          (receiverData['profile_image_url'] == null ||
                              receiverData['profile_image_url'].isEmpty)
                          ? const Icon(
                              Icons.person_pin_circle,
                              color: primaryGreen,
                            )
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ชื่อ : ${receiverData['customer_name'] ?? '...'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'เบอร์โทร : ${receiverData['customer_phone'] ?? '...'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ที่อยู่ : ${receiverData['customer_address'] ?? '...'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'พิกัด: $lat, $lng', // <-- แสดงเป็น Text เหมือนเดิม
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 📍 ส่วนที่เพิ่มเข้ามาสำหรับแผนที่ (flutter_map) 📍 ---
          if (receiverLocation != null)
            SizedBox(
              height: 200, // กำหนดความสูงของแผนที่
              width: double.infinity,
              child: FlutterMap(
                // <-- ใช้ FlutterMap
                options: MapOptions(
                  initialCenter: receiverLocation,
                  initialZoom: 16.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag
                        .none, // ทำให้แผนที่เลื่อนไม่ได้ (แสดงผลอย่างเดียว)
                  ),
                ),
                children: [
                  TileLayer(
                    // <-- ใช้ TileLayer ของ OpenStreetMap
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.example.deliver_tracksure', // ใส่ package name ของคุณ
                  ),
                  MarkerLayer(
                    // <-- แสดง Marker
                    markers: markers,
                  ),
                ],
              ),
            )
          else
            const Padding(
              // <-- แสดงข้อความถ้าไม่มีพิกัด
              padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Text(
                'ไม่พบข้อมูลพิกัดสำหรับแสดงบนแผนที่',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
  // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool isSubmitting = false,
  }) {
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
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _productImage != null
                ? Image.file(_productImage!, fit: BoxFit.cover)
                : const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Color(0xFFD3A867),
                    ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
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
              color: Color(0xFF333333),
            ),
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
            ),
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
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 15),
                  _buildSenderInfoCard(_userData, _selectedSenderAddress),
                  const SizedBox(height: 20),
                  _buildReceiverSearch(), // <-- แก้ไข widget นี้แล้ว
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
                  _buildAddedItemsList(),

                  const SizedBox(height: 30),
                  // --- ปุ่มยืนยันสุดท้าย ---
                  if (_addedItems.isNotEmpty)
                    _buildActionButton(
                      text: 'ยืนยันการส่งชิ้นค้า (${_addedItems.length})',
                      color: primaryGreen,
                      onPressed: _submitAllOrders,
                      isSubmitting: _isSubmitting,
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}


