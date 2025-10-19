import 'package:flutter/material.dart';

class EditRider extends StatefulWidget {
  const EditRider({super.key});

  @override
  State<EditRider> createState() => _EditRiderState();
}

class _EditRiderState extends State<EditRider> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ใช้ BoxDecoration เพื่อสร้างพื้นหลังเป็นภาพ
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image/main1.png'), // ใส่ภาพที่คุณต้องการ
            fit: BoxFit.cover, // กำหนดให้ภาพครอบคลุมทั้งหน้าจอ
          ),
        ),
      ),
    );
  }
}
