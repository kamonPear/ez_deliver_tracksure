import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Local Imports
import 'Registration.dart';
import 'all.dart'; // สมมติว่ามี HomeScreen อยู่ในนี้
import 'package:ez_deliver_tracksure/pagerider/rider_home.dart'; // สำหรับ DeliveryHomePage


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // MARK: - Login Logic
  // ----------------------------------------------------------------------

  // ✅ ฟังก์ชันสำหรับเข้าสู่ระบบ (รวมตรรกะที่ขัดแย้งกันแล้ว)
  Future<void> _signIn() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final rawPhone = _loginController.text.trim();
      // ลบอักขระที่ไม่ใช่ตัวเลขทั้งหมดออก เพื่อให้มั่นใจว่าเป็นเบอร์โทรศัพท์ที่ถูกต้อง
      final phone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
      final password = _passwordController.text.trim();

      // 1. กำหนดอีเมลที่เป็นไปได้ (รูปแบบ: [phone]_[role]@tracksure.app)
      final List<String> potentialEmails = [
        '${phone}_customer@tracksure.app', // ลองเป็นลูกค้าก่อน
        '${phone}_rider@tracksure.app', // ถ้าไม่ได้ ลองเป็นไรเดอร์
      ];

      UserCredential? userCredential;
      bool loginSuccess = false;

      // 2. วนลูปเพื่อลองล็อกอินด้วยอีเมลที่เป็นไปได้ทั้งหมด
      for (final email in potentialEmails) {
        try {
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          loginSuccess = true;
          break; // ล็อกอินสำเร็จแล้ว ออกจากลูป
        } on FirebaseAuthException catch (e) {
          // ถ้าเกิดข้อผิดพลาดที่ระบุว่าผู้ใช้/รหัสผ่านผิด ให้ลองอีเมลถัดไป
          if (e.code == 'user-not-found' ||
              e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            continue;
          } else {
            // หากเกิดข้อผิดพลาดอื่น ๆ ให้หยุดและแสดงข้อผิดพลาด
            _showErrorDialog('เกิดข้อผิดพลาดในการตรวจสอบสิทธิ์: ${e.message}');
            return;
          }
        }
      }

      if (!loginSuccess) {
        // หากวนลูปครบแล้วแต่ยังล็อกอินไม่สำเร็จ
        _showErrorDialog('เบอร์โทรศัพท์ หรือรหัสผ่านไม่ถูกต้อง');
        return;
      }

      final user = userCredential?.user;
      if (user == null) {
        _showErrorDialog('ไม่สามารถเข้าสู่ระบบได้ (User Object Missing)');
        return;
      }

      // 3. **ขั้นตอนที่ 2: ตรวจสอบ Firestore**
      // ตรวจสอบว่าเป็นลูกค้าหรือไรเดอร์ใน Firestore

      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        // ไปหน้า Home สำหรับผู้ใช้ (ลูกค้า)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        return;
      }

      final riderDoc = await FirebaseFirestore.instance
          .collection('riders')
          .doc(user.uid)
          .get();

      if (riderDoc.exists) {
        // ไปหน้า Home สำหรับไรเดอร์
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DeliveryHomePage()),
        );
        return;
      }

      // หากล็อกอิน Firebase ได้ แต่ไม่พบ UID ใน Firestore ทั้งสองคอลเลกชัน
      // Sign Out เพื่อไม่ให้ผู้ใช้ค้างอยู่ในสถานะล็อกอิน
      await FirebaseAuth.instance.signOut();
      _showErrorDialog('ไม่พบข้อมูลผู้ใช้งานในระบบ (กรุณาลงทะเบียน)');
    } on Exception catch (e) {
      // จับข้อผิดพลาดที่ไม่ใช่ FirebaseAuth (เช่น Firestore error, Network error)
      _showErrorDialog('เกิดข้อผิดพลาดที่ไม่รู้จัก: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('เกิดข้อผิดพลาด', style: GoogleFonts.prompt()),
        content: Text(message, style: GoogleFonts.prompt()),
        actions: <Widget>[
          TextButton(
            child: Text('ตกลง', style: GoogleFonts.prompt()),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // MARK: - UI Build Method
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ส่วนหัว (Banner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Color.fromARGB(255, 27, 155, 120)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                'TRACK-SURE',
                textAlign: TextAlign.center,
                style: GoogleFonts.alumniSansInlineOne(
                  fontSize: 65,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),
            // ส่วนเนื้อหาหลัก
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'เข้าสู่ระบบ',
                        style: GoogleFonts.prompt(
                          fontSize: 42,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // ช่องกรอกเบอร์โทรศัพท์
                      TextField(
                        controller: _loginController,
                        style: GoogleFonts.prompt(),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'เบอร์โทรศัพท์',
                          labelStyle:
                              GoogleFonts.prompt(color: Colors.green[800]),
                          prefixIcon:
                              Icon(Icons.phone, color: Colors.green[800]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ช่องกรอกรหัสผ่าน
                      TextField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        style: GoogleFonts.prompt(),
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          labelStyle:
                              GoogleFonts.prompt(color: Colors.green[800]),
                          prefixIcon:
                              Icon(Icons.lock, color: Colors.green[800]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ลืมรหัสผ่าน
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Add forgot password logic
                          },
                          child: Text(
                            'ลืมรหัสผ่าน?',
                            style: GoogleFonts.prompt(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ปุ่มเข้าสู่ระบบ
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: GoogleFonts.prompt(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('เข้าสู่ระบบ'),
                      ),
                      const SizedBox(height: 20),
                      // สมัครสมาชิก
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ถ้าคุณยังไม่ได้เป็นสมาชิก?',
                              style: GoogleFonts.prompt()),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegistrationPage(),
                                ),
                              );
                            },
                            child: Text(
                              'สมัครสมาชิก',
                              style: GoogleFonts.prompt(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}