import 'package:flutter/material.dart';

class StatusBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onItemSelected;

  const StatusBottomBar({
    super.key,
    required this.currentIndex,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07AA7C), Color(0xFF11598D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.motorcycle),
            label: 'ข้อมูลการส่งของ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'ออกจากระบบ',
          ),
        ],
        currentIndex: currentIndex, // ✅ ใช้ค่าจากภายนอก
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (onItemSelected != null) {
            onItemSelected!(index); // ✅ ส่ง index กลับไปให้หน้า parent
          }
        },
      ),
    );
  }
}


