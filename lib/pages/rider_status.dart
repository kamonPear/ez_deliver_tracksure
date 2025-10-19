import 'package:flutter/material.dart';
import 'rider_bottom_bar.dart'; // อ้างอิงถึง RiderBottomBar จากไฟล์อื่น

// --- Main Delivery Status Page Widget ---
class DeliveryStatusPage extends StatelessWidget {
  const DeliveryStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Makes the AppBar transparent and allows the background to show through
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Optionally remove the app bar height
      ),
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF22BF9E), // Lighter Teal/Green
                  Color(0xFF00A859), // Darker Green
                ],
                stops: [0.0, 0.4], // Define where the gradient ends
              ),
            ),
          ),
          // 2. Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Status Header Card
                  const StatusHeaderCard(),
                  const SizedBox(height: 16),

                  // Status Indicator Row
                  const StatusIndicatorRow(),
                  const SizedBox(height: 16),

                  // Map Image Placeholder
                  const MapPlaceholder(),
                  const SizedBox(height: 16),

                  // Photo Buttons Row
                  const PhotoButtonsRow(),
                  const SizedBox(height: 24),

                  // Confirm Delivery Button
                  ConfirmDeliveryButton(),
                  const SizedBox(height: 24),

                  // Delivery Details Card
                  const DeliveryDetailsCard(),
                  const SizedBox(height: 24),

                  // View Product Details Button
                  ViewProductDetailsButton(),
                  const SizedBox(height: 50), // Extra space for the bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      // 3. Bottom Navigation Bar (เรียกใช้ RiderBottomBar ที่ถูก import มา)
      bottomNavigationBar: const StatusBottomBar(),
    );
  }
}

// --- Status Header Card Widget ---
class StatusHeaderCard extends StatelessWidget {
  const StatusHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Text(
        'สถานะการจัดส่งสินค้า',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00796B), // Darker green text
        ),
      ),
    );
  }
}

// --- Status Indicator Row Widget ---
class StatusIndicatorRow extends StatelessWidget {
  const StatusIndicatorRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        StatusStep(
          icon: Icons.access_time,
          label: 'รอไรเดอร์รับสินค้า',
          isActive: false,
        ),
        StatusStep(
          icon: Icons.check_circle_outline,
          label: 'ไรเดอร์รับแล้ว',
          isActive: true,
        ),
        StatusStep(
          icon: Icons.map,
          label: 'ไรเดอร์กำลังขนส่ง',
          isActive: true,
        ),
        StatusStep(
          icon: Icons.check_circle,
          label: 'จัดส่งสินค้าสำเร็จ',
          isActive: true, // This is the final step, marked as active
          isFinal: true,
        ),
      ],
    );
  }
}

// --- Status Step Widget (Helper for Status Indicator Row) ---
class StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isFinal;

  const StatusStep({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isFinal = false,
  });

  @override
  Widget build(BuildContext context) {
    // The active color seems to be a light teal/green
    final Color activeColor = isFinal ? const Color(0xFF00A859) : const Color(0xFF22BF9E);
    final Color color = isActive ? activeColor : Colors.white70;

    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: Icon(
            icon,
            color: isActive ? activeColor : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60, // Fixed width for alignment
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

// --- Map Placeholder Widget ---
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder container for the map image
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        // You would replace the image with an actual map widget (e.g., Google Maps)
        // or a network image in a real application.
        // For demonstration, we just use a white background and the route painter
      ),
      // Adding a placeholder for the map details based on the image's appearance
      child: Stack(
        children: [
          // A semi-transparent overlay to make the map look 'embedded'
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black.withOpacity(0.05),
            ),
          ),
          // Placeholder for the route line (visual cue)
          Center(
            child: CustomPaint(
              size: const Size(200, 180),
              painter: RoutePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- RoutePainter (For the map line effect) ---
class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B59FF) // Blue line color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.9)
      ..cubicTo(
        size.width * 0.7, size.height * 0.7,
        size.width * 0.3, size.height * 0.4,
        size.width * 0.5, size.height * 0.1,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Photo Buttons Row Widget ---
class PhotoButtonsRow extends StatelessWidget {
  const PhotoButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        PhotoButton(
          label: 'สถานะะกำลังจัดส่ง',
          color: Color(0xFFFFFFFF),
        ),
        PhotoButton(
          label: 'สถานะะจัดส่งสำเร็จ',
          color: Color(0xFFFFFFFF),
        ),
      ],
    );
  }
}

// --- Photo Button Widget (Helper) ---
class PhotoButton extends StatelessWidget {
  final String label;
  final Color color;

  const PhotoButton({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.camera_alt,
                color: Color(0xFF00A859), // Icon color
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Confirm Delivery Button Widget ---
class ConfirmDeliveryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Action for confirming delivery
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF90C239), // Yellowish Green
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        child: const Text(
          'ยืนยันการส่งสินค้า',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// --- Delivery Details Card Widget ---
class DeliveryDetailsCard extends StatelessWidget {
  const DeliveryDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Sender Details
          DeliveryDetailRow(
            icon: Icons.location_on,
            iconColor: Colors.red,
            title: 'ผู้ส่ง:',
            name: 'คุณวิมลมาลย์สารสนเทศ',
            phone: '123 4567 7890',
            showIconImage: true,
          ),
          const Divider(height: 20, thickness: 1, indent: 40, endIndent: 10),
          // Row 2: Receiver Details
          DeliveryDetailRow(
            icon: Icons.location_on,
            iconColor: Colors.green,
            title: 'ผู้รับ:',
            name: 'หอพักแสงจันทร์ซอย 3',
            phone: '123 4567 7890',
            showIconImage: false,
          ),
        ],
      ),
    );
  }
}

// --- Delivery Detail Row Widget (Helper) ---
class DeliveryDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String name;
  final String phone;
  final bool showIconImage;

  const DeliveryDetailRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.name,
    required this.phone,
    required this.showIconImage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional Image/Icon Section (for the motorcycle graphic)
        if (showIconImage)
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.delivery_dining, size: 50, color: Color(0xFF00796B)),
            // In a real app, replace with an image asset
            // Image.asset('assets/delivery_icon.png', height: 50),
          )
        else
          const SizedBox(width: 58), // Space placeholder
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Detail 1: Title/Address
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        // Detail 2: Phone
                        Text(
                          'เบอร์โทร: $phone', // รวมเบอร์โทร
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// --- View Product Details Button Widget ---
class ViewProductDetailsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Action to view product details
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A859), // Primary Green
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        child: const Text(
          'ข้อมูลสินค้า',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
