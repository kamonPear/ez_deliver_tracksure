import 'package:flutter/material.dart';

class StatusStepper extends StatelessWidget {
  final int currentStep;

  const StatusStepper({super.key, this.currentStep = 4});

  Widget _buildStep(String label, IconData iconData, bool isActive) {
    final color = isActive ? const Color(0xFF07AA7C) : Colors.grey[400];
    return Column(
      children: [
        Icon(iconData, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07AA7C), Color(0xFF11598D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStep('รอไรเดอร์รับสินค้า', Icons.hourglass_empty, currentStep >= 1),
          _buildStep('ได้ไรเดอร์แล้ว', Icons.check_circle_outline, currentStep >= 2),
          _buildStep('ไรเดอร์กำลังไปหาคุณ', Icons.motorcycle, currentStep >= 3),
          _buildStep('จัดส่งสินค้าสำเร็จ', Icons.check_circle, currentStep >= 4),
        ],
      ),
    );
  }
}
