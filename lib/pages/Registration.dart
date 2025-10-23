import 'dart:io';
import 'package:ez_deliver_tracksure/gps/mapgps.dart';
import 'login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart'; // <--- ต้อง import latlong2
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Import Service ที่สร้างไว้
import '../api/api_service_image.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
<<<<<<< HEAD
=======
  // final _emailController = TextEditingController(); // ลบ Controller ของอีเมลออก
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gpsController = TextEditingController();
  final _licensePlateController = TextEditingController();

  String _userType = 'ผู้ใช้';
  File? _profileImage;
  File? _vehicleImage;
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  LatLng? _selectedLocation; // <--- (แก้ไขจุดที่ 1) เพิ่มตัวแปรนี้

  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();

  Future<void> _pickImage(ImageSource source, {required bool isProfile}) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(pickedFile.path);
          } else {
            _vehicleImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูป: $e')),
      );
    }
  }

  // ✅ ปรับให้สมัครได้ทั้งผู้ใช้และไรเดอร์จากเบอร์เดียวกัน
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userType == 'ไรเดอร์' && _vehicleImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอัปโหลดรูปยานพาหนะ')),
      );
      return;
    }
    
    // <--- เพิ่มการตรวจสอบสำหรับผู้ใช้
    if (_userType == 'ผู้ใช้' && _selectedLocation == null) {
       ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกพิกัด GPS')));
      return;
    }

    setState(() => _isLoading = true);

    try {
<<<<<<< HEAD
      final phoneTrimmed = _phoneController.text.trim();

      // ✅ สร้าง email จำลองแยกตามประเภท
     final emailForAuth = (_userType ?? '') == 'ผู้ใช้'
    ? '${phoneTrimmed}_customer@tracksure.app'
    : '${phoneTrimmed}_rider@tracksure.app';

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailForAuth,
        password: _passwordController.text.trim(),
      );
=======
      // แก้ไข: ให้ทั้งผู้ใช้และไรเดอร์ใช้อีเมลจากเบอร์โทรศัพท์
      String emailForAuth = '${_phoneController.text.trim()}@tracksure.app';

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailForAuth,
              password: _passwordController.text.trim(),
          );
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af

      User? user = userCredential.user;

      if (user != null) {
        String? profileImageUrl;
        String? vehicleImageUrl;

        // อัปโหลดรูปโปรไฟล์
        if (_profileImage != null) {
          profileImageUrl =
              await _imageUploadService.uploadImageToCloudinary(_profileImage!);
        }

        if (_userType == 'ผู้ใช้') {
          // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
          //           <--- (แก้ไขจุดที่ 3)
          // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
          Map<String, dynamic> customerData = {
            'customer_name': _usernameController.text.trim(),
            'customer_phone': _phoneController.text.trim(),
            'customer_address': _addressController.text.trim(),
            'profile_image_url': profileImageUrl,
            'latitude': _selectedLocation?.latitude,   // <-- บันทึก latitude
            'longitude': _selectedLocation?.longitude, // <-- บันทึก longitude
            'createdAt': FieldValue.serverTimestamp(),
          };
          // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

          await FirebaseFirestore.instance
              .collection('customers')
              .doc(user.uid)
              .set(customerData);
        } else if (_userType == 'ไรเดอร์') {
          if (_vehicleImage != null) {
            vehicleImageUrl =
                await _imageUploadService.uploadImageToCloudinary(_vehicleImage!);
          }

          Map<String, dynamic> riderData = {
            'rider_name': _usernameController.text.trim(),
            'rider_phone': _phoneController.text.trim(),
            'profile_image_url': profileImageUrl,
            'license_plate': _licensePlateController.text.trim(),
            'vehicle_image_url': vehicleImageUrl,
            'status': 'pending_approval',
            'createdAt': FieldValue.serverTimestamp(),
            // ไรเดอร์ไม่จำเป็นต้องมี lat/long ตอนสมัคร (เพราะจะใช้ตำแหน่งปัจจุบันตอนทำงาน)
          };

          await FirebaseFirestore.instance
              .collection('riders')
              .doc(user.uid)
              .set(riderData);
        }

        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาด';
      if (e.code == 'weak-password') {
        message = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      } else if (e.code == 'email-already-in-use') {
<<<<<<< HEAD
        message = 'เบอร์นี้มีบัญชีประเภทนี้อยู่แล้ว';
      } else if (e.code == 'invalid-email') {
        message = 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง';
=======
        message = 'อีเมลนี้มีผู้ใช้แล้ว หรือเบอร์โทรนี้เคยลงทะเบียนแล้ว';
      } else if (e.code == 'invalid-email') {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(
              'สมัครสมาชิกเรียบร้อย',
              style: GoogleFonts.prompt(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'ตกลง',
                style: GoogleFonts.prompt(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 30, 182, 112),
                  Color.fromARGB(255, 27, 155, 120),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      'TRACK-SURE',
                      style: GoogleFonts.alumniSansInlineOne(
                        fontSize: 65,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                'สมัครสมาชิก',
                                style: GoogleFonts.prompt(
                                  fontSize: 32,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildUserTypeToggle(),
                              const SizedBox(height: 20),
                              _buildImagePicker(isProfile: true),
                              const SizedBox(height: 20),
<<<<<<< HEAD
                              _buildTextField(_usernameController, 'ชื่อ-สกุล', Icons.person),
                              _buildTextField(_phoneController, 'เบอร์โทรศัพท์', Icons.phone,
                                  keyboardType: TextInputType.phone),
=======
                              _buildTextField(
                                _usernameController,
                                'ชื่อ-สกุล',
                                Icons.person,
                              ),
                              // ลบช่องกรอกอีเมลสำหรับไรเดอร์ออกจาก UI
                              _buildTextField(
                                _phoneController,
                                'เบอร์โทรศัพท์',
                                Icons.phone,
                                keyboardType: TextInputType.phone,
                              ),
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
                              _buildPasswordField(),
                              if (_userType == 'ผู้ใช้') ...[
                                _buildGpsPickerField(),
                                _buildAddressField(),
                              ],
                              if (_userType == 'ไรเดอร์') ...[
                                const SizedBox(height: 15),
                                Divider(color: Colors.grey[300]),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    "ข้อมูลเพิ่มเติมสำหรับไรเดอร์",
                                    style: GoogleFonts.prompt(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                _buildTextField(_licensePlateController, 'หมายเลขทะเบียนรถ',
                                    Icons.motorcycle),
                                const SizedBox(height: 20),
                                _buildImagePicker(isProfile: false),
                                Divider(color: Colors.grey[300]),
                              ],
                              const SizedBox(height: 30),
                              _buildRegisterButton(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserTypeButton('ผู้ใช้'),
          _buildUserTypeButton('ไรเดอร์'),
        ],
      ),
    );
  }

  Widget _buildUserTypeButton(String type) {
    bool isSelected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          type,
          style: GoogleFonts.prompt(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker({required bool isProfile}) {
    File? image = isProfile ? _profileImage : _vehicleImage;
    String title = isProfile ? 'รูปโปรไฟล์' : 'รูปยานพาหนะ/ทะเบียน';

    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery, isProfile: isProfile),
          child: CircleAvatar(
            radius: isProfile ? 50 : 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: image != null ? FileImage(image) : null,
            child: image == null
                ? Icon(
                    isProfile ? Icons.person_add_alt_1 : Icons.camera_alt,
                    color: Colors.grey[800],
                    size: isProfile ? 40 : 50,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.prompt()),
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
=======
  Widget _buildTextField(
  TextEditingController controller,
  String label,
  IconData icon, {
  TextInputType? keyboardType,
}) {
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: (value) {
<<<<<<< HEAD
          if (value == null || value.isEmpty) return 'กรุณากรอก$label';
=======
          if (value == null || value.isEmpty) {
            return 'กรุณากรอก$label';
          }
          if (label == 'อีเมล' &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'กรุณากรอกอีเมลให้ถูกต้อง';
          }
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
          return null;
        },
      ),
    );
  }

  Widget _buildGpsPickerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _gpsController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'พิกัด GPS (แตะเพื่อเลือกบนแผนที่)',
          prefixIcon: const Icon(Icons.map),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'กรุณาเลือกพิกัด GPS';
          return null;
        },
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Mapgps()),
          );

          if (result != null && result is Map) {
            final LatLng? position = result['latlng'] as LatLng?;
            final String? address = result['address'] as String?;

            if (position != null && address != null) {
              // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
              //           <--- (แก้ไขจุดที่ 2)
              // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
              setState(() {
                _selectedLocation = position; // <-- เก็บค่า LatLng object
                _gpsController.text =
                    '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                _addressController.text = address;
              });
              // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
            }
          }
        },
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _addressController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'ที่อยู่ (พิมพ์เพื่อค้นหา หรือเลือกจากแผนที่)',
          prefixIcon: const Icon(Icons.location_on),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'กรุณากรอกที่อยู่ หรือเลือกจากแผนที่';
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _isPasswordObscured,
        decoration: InputDecoration(
          labelText: 'รหัสผ่าน',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () =>
                setState(() => _isPasswordObscured = !_isPasswordObscured),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
          if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
          return null;
        },
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'สมัครสมาชิก',
                style: GoogleFonts.prompt(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
<<<<<<< HEAD
=======
    // _emailController.dispose(); // ลบการ dispose ของ email controller
>>>>>>> 6036dca444102d2983ebf98924c9fac32328a1af
    _addressController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _gpsController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }
}