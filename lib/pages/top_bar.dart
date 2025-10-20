import 'package:flutter/material.dart';

// The class structure remains the same
class TopBar extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final String userAddress;

  const TopBar({
    super.key,
    required this.userName,
    this.profileImageUrl,
    required this.userAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07AA7C), Color(0xFF11598D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // User profile section (unchanged)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // We wrap the Text with Flexible here too, just in case of very long names
              Flexible(
                child: Text(
                  'สวัสดี, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle long names
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                    ? NetworkImage(profileImageUrl!)
                    : const AssetImage('assets/image/default_profile.png') as ImageProvider,
                child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar (unchanged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey),
                hintText: 'ค้นหาผู้รับสินค้า',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- 📍 START OF THE FIX ---
          // ที่อยู่ (Address Section)
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 106, 185, 181),
                borderRadius: BorderRadius.circular(20),
              ),
              // The Row itself can still shrink-to-fit its content
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),

                  // **THE FIX:** Wrap the Text widget with Flexible.
                  // This tells the Text to take up available space but not to
                  // push the boundaries, preventing an overflow.
                  Flexible(
                    child: Text(
                      userAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                      // Handles text that is too long by showing '...'
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- END OF THE FIX ---
        ],
      ),
    );
  }
}
