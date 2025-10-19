import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart'; // นำเข้าหน้า login.dart
import 'Registration.dart';


class Indexpage extends StatefulWidget {
  const Indexpage({super.key});

  @override
  State<Indexpage> createState() => _IndexpageState();
}



class _IndexpageState extends State<Indexpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ใช้ BoxDecoration เพื่อสร้างพื้นหลังเป็น gradient
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, // จุดเริ่มต้นของการไล่สี
            end: Alignment.bottomRight, // จุดสิ้นสุดของการไล่สี
            colors: [
              const Color.fromARGB(255, 16, 105, 56),
              const Color.fromARGB(255, 9, 75, 119),
            ], // สีที่ใช้ใน gradient
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้
              Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/image/logo.png', 
                    ), // อย่าลืมใส่โลโก้ใน assets
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 0.5),
              // ชื่อแอป
              Text(
                'TRACK-SURE',
                style: GoogleFonts.alumniSansInlineOne(
                  // ใช้ GoogleFonts.itim แบบถูกต้อง
                  fontSize: 60,
                  // fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),

              SizedBox(height: 50),
              // ปุ่ม
              Column(
                children: [
                  // ปุ่มเข้าสู่ระบบ
                  ElevatedButton(
                    onPressed: () {
                      // ใช้ Navigator.push() เพื่อไปยังหน้า login.dart
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ), // เปิดหน้า LoginPage
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 34, 172, 39),
                      padding: EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 10,
                      ), // ปรับขนาด padding
                      foregroundColor:
                          Colors.white, // ใช้ foregroundColor แทน textStyle
                      textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // เพิ่ม borderRadius เพื่อให้มุมโค้ง
                      ),
                    ),
                    child: Text('เข้าสู่ระบบ'),
                  ),
                  SizedBox(height: 50),
                  // ปุ่มสมัครสมาชิก
                  ElevatedButton(
                    onPressed: () {
                      // ใช้ Navigator.push() เพื่อไปยังหน้า Registration.dart
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RegistrationPage(), // เปิดหน้า RegistrationPage
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 34, 172, 39),
                      padding: EdgeInsets.symmetric(
                        horizontal: 90,
                        vertical: 10,
                      ),
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text('สมัครสมาชิก'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
