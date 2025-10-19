import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  // 1. Declare variables to receive the current index and the function to call on tap.
  final int currentIndex;
  final Function(int) onItemSelected;

  // 2. Update the constructor to accept these values.
  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
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
            icon: Icon(Icons.history),
            label: 'ประวัติการส่งสินค้า',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'อื่นๆ',
          ),
        ],
        // 3. (Crucial) Use the values passed from the parent widget.
        currentIndex: currentIndex,
        onTap: onItemSelected, // When an item is tapped, call the provided function.
        // --- Styling ---
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        backgroundColor: Colors.transparent, // Make it transparent to show the gradient
        elevation: 0, // Remove shadow
        type: BottomNavigationBarType.fixed, // Prevent icons from shifting
      ),
    );
  }
}
