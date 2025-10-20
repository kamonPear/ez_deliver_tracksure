import 'package:flutter/material.dart';
import 'bottom_bar.dart';

class OrderStatus extends StatelessWidget {
  const OrderStatus({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the colors used in the design
    const Color primaryGreen = Color(0xFF00A859);
    const Color darkGreen = Color(0xFF007A44);
    const Color lightTeal = Color(0xFFE0F7F0);
    const Color backgroundColor = Colors.white;
    const Color textColor = Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      // Custom AppBar/Header
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          backgroundColor: primaryGreen,
          elevation: 0,
          automaticallyImplyLeading: false, // No back button needed in this design
          flexibleSpace: Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF75C2A4), // A lighter shade for the header box
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text(
                'สถานะการส่งสินค้า',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 2.0,
                      color: Colors.black26,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Tracking Steps
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const <Widget>[
                  TrackingStep(
                    icon: Icons.access_time_filled, // Closest icon for the hourglass/timer
                    label: 'รอไรเดอร์รับสินค้า',
                    isActive: true, // Current step
                    color: primaryGreen,
                  ),
                  TrackingStep(
                    icon: Icons.description, // Closest icon for the clipboard/document
                    label: 'ได้รับออเดอร์แล้ว',
                    isActive: false,
                    color: primaryGreen,
                  ),
                  TrackingStep(
                    icon: Icons.motorcycle, // Closest icon for the motorcycle
                    label: 'ไรเดอร์กำลังมา',
                    isActive: false,
                    color: primaryGreen,
                  ),
                  TrackingStep(
                    icon: Icons.check_circle,
                    label: 'จัดส่งสินค้าสำเร็จ',
                    isActive: false,
                    color: primaryGreen,
                  ),
                ],
              ),
            ),

            // Map Placeholder
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    'assets/map_placeholder.png', // Replace with an actual map widget or network image
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: lightTeal, child: const Center(child: Text('Map Placeholder'))),
                  ),
                ),
              ),
            ),

            // Status Text
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  'สถานะรอไรเดอร์รับสินค้า',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),

            // Camera Icon/Prompt (The central camera icon block)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 20.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 60,
                  color: primaryGreen,
                ),
              ),
            ),

            // Rider Info Header
            const Center(
              child: Text(
                'ข้อมูลไรเดอร์ที่รับงาน',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            // Rider Info Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Left side for labels
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text('ชื่อ : ', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 4),
                        Text('เบอร์โทร : ', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 4),
                        Text('ทะเบียน : ', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Right side for values
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text('Patcharadanai Jantapo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('082661****', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('1 กธ 4120', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Extra space above bottom bar
          ],
        ),
      ),
      // Bottom Navigation Bar
       bottomNavigationBar: BottomBar(
        currentIndex: 0, 
        onItemSelected: (index) {
          debugPrint('BottomBar tapped at index $index');
        }, 
      ), // Use the imported BottomBar widget
    );
  }
}

// Custom Widget for the Tracking Steps
class TrackingStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;

  const TrackingStep({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Icon and Circle
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.white,
            border: Border.all(
              color: isActive ? color : Colors.grey.shade400,
              width: 2.0,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey.shade400,
            size: 24.0,
          ),
        ),
        const SizedBox(height: 4.0),
        // Label
        SizedBox(
          width: 60, // Limit width to fit four items
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.black : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

