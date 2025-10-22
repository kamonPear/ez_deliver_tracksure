import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import หน้าอื่นๆ ที่จำเป็นจากไฟล์ placeholder
import 'Registration.dart';
import 'all.dart';

import 'package:ez_deliver_tracksure/pagerider/rider_home.dart'; //6165156>>>>>>> e1e2b5a18a18ff38ea888c113f50cb032a552e9a

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

  Future<void> _signIn() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --- ส่วนสำคัญ: ตรวจสอบและแปลงข้อมูลการล็อกอิน ---
      final loginInput = _loginController.text.trim();
      String emailForAuth;

      if (loginInput.contains('@')) {
        // ถ้ามี @, ให้ถือว่าเป็นอีเมล (สำหรับ Rider)
        emailForAuth = loginInput;
      } else {
        // ถ้าไม่มี @, ให้ถือว่าเป็นเบอร์โทร (สำหรับ Customer)
        // และแปลงให้เป็นรูปแบบอีเมลที่ใช้สมัคร
        emailForAuth = '$loginInput@tracksure.app';
      }

      // 1. ตรวจสอบกับ Firebase Authentication
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailForAuth,
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // 2. ค้นหาข้อมูลใน Firestore เพื่อแยกประเภทผู้ใช้
        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();

        if (customerDoc.exists) {
          // ถ้าเจอใน 'customers' -> ไปยังหน้า Home ของผู้ใช้
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // ถ้าไม่เจอ ให้ไปค้นหาใน 'riders'
          DocumentSnapshot riderDoc = await FirebaseFirestore.instance
              .collection('riders')
              .doc(user.uid)
              .get();

          if (riderDoc.exists) {
            // ถ้าเจอใน 'riders' -> ไปยังหน้าสถานะของไรเดอร์
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => const StatusScreen()),
            // );
          } else {
            // ไม่พบข้อมูลในทั้ง 2 collections
            _showErrorDialog('ไม่พบข้อมูลผู้ใช้งานในระบบ');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'เบอร์โทรศัพท์ หรือ รหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'invalid-email') {
        message = 'รูปแบบเบอร์โทรศัพท์หรืออีเมลไม่ถูกต้อง';
      } else {
        message = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
      }
      _showErrorDialog(message);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                      TextField(
                        controller: _loginController,
                        style: GoogleFonts.prompt(),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          // --- ส่วนที่ปรับปรุง ---
                          labelText: 'เบอร์โทรศัพท์',
                          labelStyle: GoogleFonts.prompt(color: Colors.green[800]),
                          prefixIcon: Icon(Icons.person, color: Colors.green[800]),
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
                      TextField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        style: GoogleFonts.prompt(),
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          labelStyle: GoogleFonts.prompt(color: Colors.green[800]),
                          prefixIcon: Icon(Icons.lock, color: Colors.green[800]),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password logic
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
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('เข้าสู่ระบบ'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ถ้าคุณยังไม่ได้เป็นสมาชิก?',
                            style: GoogleFonts.prompt(),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegistrationPage(),
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

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
