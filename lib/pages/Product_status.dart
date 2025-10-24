import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' as latLng;
import 'package:latlong2/latlong.dart' as latLng;

// --- Import หน้าอื่นๆ ---
import 'package:ez_deliver_tracksure/pages/all.dart'; // HomeScreen
import 'package:ez_deliver_tracksure/pages/EditPro.dart'; // EditPro
import 'package:ez_deliver_tracksure/pages/order_list_page.dart'; // OrderListPage
// -----------------------

import 'package:ez_deliver_tracksure/pages/bottom_bar.dart'; // BottomBar

class ProductStatus extends StatefulWidget {
  final String orderId;

  const ProductStatus({super.key, required this.orderId});

  @override
  State<ProductStatus> createState() => _ProductStatusState();
}

class _ProductStatusState extends State<ProductStatus> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  String? _errorMessage;
  DocumentSnapshot? _orderData;
  DocumentSnapshot? _riderData; // Still used for rider name/phone

  final MapController _mapController = MapController();
  StreamSubscription? _orderSub;
  // Removed: StreamSubscription? _riderSub;
  latLng.LatLng? _currentRiderLocation; // Updated from order stream

  String? _pickupImageUrl;
  String? _deliveryImageUrl;

  static const Color primaryGreen = Color(0xFF00A859);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _listenToOrder();
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    // Removed: _riderSub?.cancel();
    _mapController.dispose(); // Dispose map controller
    super.dispose();
  }

  Future<void> _listenToOrder() async {
    setState(() => _isLoading = true);

    // Cancel any previous subscription just in case
    await _orderSub?.cancel();

    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen(
          (orderDoc) async {
            // Added async
            if (!orderDoc.exists) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'ไม่พบข้อมูลออเดอร์';
                  _orderData = null; // Clear old data
                  _riderData = null;
                  _currentRiderLocation = null;
                });
              }
              return;
            }

            final orderData = orderDoc.data() as Map<String, dynamic>;

            // --- Extract Image URLs (Same as before) ---
            final String? fetchedPickupImageUrl =
                orderData['pickupImageUrl'] as String?;
            final String? fetchedDeliveryImageUrl =
                orderData['deliveryImageUrl'] as String?;
            // ------------------------------------------

            // --- [NEW] Extract Rider Location from Order ---
            final double? riderLat = (orderData['rider_lat'] as num?)
                ?.toDouble();
            final double? riderLng = (orderData['rider_long'] as num?)
                ?.toDouble();
            latLng.LatLng? newRiderPos = null;
            if (riderLat != null && riderLng != null) {
              newRiderPos = latLng.LatLng(riderLat, riderLng);
            }
            // ---------------------------------------------

            // --- Extract Rider ID (Same as before) ---
            final String? riderId = orderData['riderId'] as String?;
            // -----------------------------------------

            // --- [MODIFIED] Update State ---
            if (mounted) {
              setState(() {
                _orderData = orderDoc; // Store the latest order snapshot
                _isLoading = false; // Stop loading now that we have data
                _errorMessage = null; // Clear error if data is fetched

                // Update Image URLs
                _pickupImageUrl =
                    (fetchedPickupImageUrl != null &&
                        fetchedPickupImageUrl.isNotEmpty)
                    ? fetchedPickupImageUrl
                    : null;
                _deliveryImageUrl =
                    (fetchedDeliveryImageUrl != null &&
                        fetchedDeliveryImageUrl.isNotEmpty)
                    ? fetchedDeliveryImageUrl
                    : null;

                // Update Rider Location
                _currentRiderLocation = newRiderPos;
              });

              // --- [NEW] Move map AFTER setState ---
              if (newRiderPos != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Ensure map is ready
                  if (mounted) {
                    try {
                      // Attempt to move map
                      _mapController.move(
                        newRiderPos!,
                        _mapController.camera.zoom,
                      );
                    } catch (e) {
                      print("MapController not ready or error moving map: $e");
                      // Optional: Fit bounds if map move fails (e.g., first update)
                      _fitMapToBounds(orderData);
                    }
                  }
                });
              } else {
                // If rider location becomes null, maybe fit bounds to pickup/dest
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _fitMapToBounds(orderData);
                });
              }
              // ------------------------------------
            }
            // --------------------------------------

            // --- [MODIFIED] Fetch Rider Details Separately (Only if needed) ---
            if (riderId != null &&
                riderId.isNotEmpty &&
                (_riderData?.id != riderId || _riderData == null)) {
              try {
                final riderDoc = await FirebaseFirestore.instance
                    .collection('riders')
                    .doc(riderId)
                    .get();
                if (riderDoc.exists && mounted) {
                  setState(() {
                    _riderData = riderDoc; // Store rider details
                  });
                } else if (mounted) {
                  setState(() {
                    _riderData = null;
                  }); // Clear if rider not found
                }
              } catch (e) {
                print("Error fetching rider data: $e");
                if (mounted)
                  setState(() {
                    _riderData = null;
                  });
              }
            } else if (riderId == null || riderId.isEmpty) {
              // Clear rider data if order has no riderId
              if (mounted && _riderData != null) {
                setState(() {
                  _riderData = null;
                });
              }
            }
            // ---------------------------------------------------------------
          },
          onError: (e) {
            print("Error listening to order: $e");
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}';
                _orderData = null;
                _riderData = null;
                _currentRiderLocation = null;
              });
            }
          },
        );
  }

  // Removed: _listenToRiderLocation function

  // [NEW] Function to fit map bounds
  void _fitMapToBounds(Map<String, dynamic> order) {
    List<latLng.LatLng> points = [];

    // Pickup Location
    final pLat = (order['pickup_latitude'] as num?)?.toDouble();
    final pLng = (order['pickup_longitude'] as num?)?.toDouble();
    if (pLat != null && pLng != null) {
      points.add(latLng.LatLng(pLat, pLng));
    }

    // Destination Location
    final dLat = (order['destination_latitude'] as num?)?.toDouble();
    final dLng = (order['destination_longitude'] as num?)?.toDouble();
    if (dLat != null && dLng != null) {
      points.add(latLng.LatLng(dLat, dLng));
    }

    // Current Rider Location (if available)
    if (_currentRiderLocation != null) {
      points.add(_currentRiderLocation!);
    }

    // Need at least 2 points to create bounds that make sense
    // If only 1 point, center on that point instead? Or default zoom?
    // For now, only fit if 2+ points exist.
    if (points.length < 2) {
      print("Not enough points (${points.length}) to fit map bounds.");
      // Optionally center on the single point or rider location
      if (points.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              _mapController.move(points.first, 15.0);
            } catch (e) {
              print("Error moving map to single point: $e");
            }
          }
        });
      } else if (_currentRiderLocation != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              _mapController.move(_currentRiderLocation!, 15.0);
            } catch (e) {
              print("Error moving map to rider location: $e");
            }
          }
        });
      }
      return;
    }

    final latLng.LatLngBounds bounds = latLng.LatLngBounds.fromPoints(points);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50.0), // Add padding around markers
            ),
          );
        } catch (e) {
          print("Error fitting map bounds: $e");
        }
      }
    });
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EditPro()),
          );
          break;
        // Case 1 is the current page, no action needed if different index
      }
    } else {
      // If tapping the current index (Status), navigate back or to OrderList
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Go back if possible
      } else {
        // Fallback if cannot pop (e.g., deep linked here)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderListPage()),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'สถานะรอไรเดอร์รับงาน';
      case 'accepted':
      case 'en_route': // Assuming en_route means going to pickup
        return 'ไรเดอร์รับออเดอร์แล้ว';
      case 'picked_up':
      case 'intransit': // Assuming intransit means going to destination
        return 'ไรเดอร์กำลังไปส่งของ';
      case 'completed':
      case 'delivered':
        return 'จัดส่งสินค้าสำเร็จ';
      default:
        return 'กำลังดำเนินการ (สถานะ: $status)';
    }
  }

  List<Marker> _buildMapMarkers(Map<String, dynamic> order) {
    final List<Marker> markers = [];

    // Pickup Marker (Green Store)
    final pickLat = (order['pickup_latitude'] as num?)?.toDouble();
    final pickLng = (order['pickup_longitude'] as num?)?.toDouble();
    if (pickLat != null && pickLng != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: latLng.LatLng(pickLat, pickLng),
          child: const Column(
            // Added Column for text label
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.store, color: Colors.green, size: 40),
              Text(
                "จุดรับ",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Destination Marker (Red Pin)
    final destLat = (order['destination_latitude'] as num?)?.toDouble();
    final destLng = (order['destination_longitude'] as num?)?.toDouble();
    if (destLat != null && destLng != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: latLng.LatLng(destLat, destLng),
          child: const Column(
            // Added Column for text label
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 40),
              Text(
                "จุดส่ง",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Rider Marker (Blue Motorcycle) - Uses state variable _currentRiderLocation
    if (_currentRiderLocation != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: _currentRiderLocation!,
          child: const Icon(
            Icons.motorcycle,
            color: Colors.blueAccent,
            size: 35,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ), // Added shadow
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    // --- Loading State ---
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'กำลังโหลด...',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryGreen,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
        bottomNavigationBar: BottomBar(
          currentIndex: _selectedIndex,
          onItemSelected: (_) {}, // Disable bottom bar during loading
        ),
      );
    }

    // --- Error State ---
    if (_errorMessage != null || _orderData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _errorMessage != null ? 'เกิดข้อผิดพลาด' : 'ไม่พบข้อมูล',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            _errorMessage ?? 'ไม่พบข้อมูลออเดอร์นี้',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
        bottomNavigationBar: BottomBar(
          currentIndex: _selectedIndex,
          onItemSelected: _onItemTapped, // Allow navigation from error page
        ),
      );
    }

    // --- Data Loaded State ---
    final order = _orderData!.data() as Map<String, dynamic>;
    final rider =
        _riderData?.data()
            as Map<String, dynamic>?; // Rider data might be null initially
    final String status =
        (order['status'] as String?)?.toLowerCase() ?? 'pending';

    // Status booleans for tracking steps
    final bool isCompleted = status == 'completed' || status == 'delivered';
    final bool isPickedUpOrLater =
        isCompleted || status == 'picked_up' || status == 'intransit';
    final bool isAcceptedOrLater =
        isPickedUpOrLater || status == 'accepted' || status == 'en_route';
    // final bool isPendingOrLater = isAcceptedOrLater || status == 'pending'; // Step 1 is always active if we have data

    final bool step1Active = true; // Always active if order exists
    final bool step2Active = isAcceptedOrLater;
    final bool step3Active = isPickedUpOrLater;
    final bool step4Active = isCompleted;

    // Determine initial map center
    double initialLat = 16.25; // Default fallback
    double initialLng = 103.23;
    final pLat = (order['pickup_latitude'] as num?)?.toDouble();
    final pLng = (order['pickup_longitude'] as num?)?.toDouble();
    if (pLat != null && pLng != null) {
      initialLat = pLat;
      initialLng = pLng;
    } else {
      final dLat = (order['destination_latitude'] as num?)?.toDouble();
      final dLng = (order['destination_longitude'] as num?)?.toDouble();
      if (dLat != null && dLng != null) {
        initialLat = dLat;
        initialLng = dLng;
      }
    }
    final latLng.LatLng initialCameraPos = latLng.LatLng(
      initialLat,
      initialLng,
    );

    // --- Build Image Section ---
    List<Widget> imageItems = [];

    // Pickup Image Card
    if (_pickupImageUrl != null) {
      imageItems.add(
        _buildImageCard(
          imageUrl: _pickupImageUrl!,
          title: 'รูปตอนรับสินค้า',
          isActive: step3Active, // Show active state when picked up or later
          color: primaryGreen,
        ),
      );
    } else if (step3Active) {
      // Show placeholder only if it SHOULD exist
      imageItems.add(
        _buildImageCard(
          icon: Icons.image_not_supported, // Different icon for missing image
          title: 'ไม่มีรูปตอนรับ',
          isActive: true,
          color: Colors.orange, // Indicate missing with color
        ),
      );
    }

    // Add spacing if both images/placeholders will be shown
    if (imageItems.isNotEmpty && (_deliveryImageUrl != null || step4Active)) {
      imageItems.add(const SizedBox(width: 16)); // Spacing between cards
    }

    // Delivery Image Card
    if (_deliveryImageUrl != null) {
      imageItems.add(
        _buildImageCard(
          imageUrl: _deliveryImageUrl!,
          title: 'รูปส่งสำเร็จ',
          isActive: step4Active, // Show active state only when completed
          color: primaryGreen,
        ),
      );
    } else if (step4Active) {
      // Show placeholder only if it SHOULD exist
      imageItems.add(
        _buildImageCard(
          icon: Icons.image_not_supported,
          title: 'ไม่มีรูปส่งสำเร็จ',
          isActive: true,
          color: Colors.orange,
        ),
      );
    }

    // Conditionally display the Row if there's anything to show
    Widget imageSection = imageItems.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center items
              crossAxisAlignment: CrossAxisAlignment.start,
              children: imageItems,
            ),
          )
        : const SizedBox.shrink(); // Show nothing if no images/placeholders yet
    // -------------------------

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        // Nicer AppBar
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          backgroundColor: primaryGreen,
          elevation: 0,
          automaticallyImplyLeading: false, // Use custom leading
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: Container(
            // Center title nicely
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 16.0),
            child: const Text(
              'สถานะการส่งสินค้า',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Tracking Steps ---
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0, // Increased vertical padding
                horizontal: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  TrackingStepWithLine(
                    icon: Icons.receipt_long, // Changed Icon
                    label: 'สร้างออเดอร์',
                    isActive: step1Active,
                    color: primaryGreen,
                    hasLine: true,
                    lineCompleted: step2Active,
                  ),
                  TrackingStepWithLine(
                    icon: Icons.person_search, // Changed Icon
                    label: 'ไรเดอร์รับงาน',
                    isActive: step2Active,
                    color: primaryGreen,
                    hasLine: true,
                    lineCompleted: step3Active,
                  ),
                  TrackingStepWithLine(
                    icon: Icons.motorcycle,
                    label: 'กำลังไปส่ง',
                    isActive: step3Active,
                    color: primaryGreen,
                    hasLine: true,
                    lineCompleted: step4Active,
                  ),
                  TrackingStep(
                    // Last step, no line needed from TrackingStepWithLine
                    icon: Icons.check_circle,
                    label: 'จัดส่งสำเร็จ',
                    isActive: step4Active,
                    color: primaryGreen,
                  ),
                ],
              ),
            ),

            // --- FlutterMap ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                ),
                child: ClipRRect(
                  // Clip map to rounded corners
                  borderRadius: BorderRadius.circular(12.0),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCameraPos,
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags:
                            InteractiveFlag.all &
                            ~InteractiveFlag.rotate, // Allow all except rotate
                      ),
                      // Center map on rider updates (optional)
                      // onTap: (_, __) => _fitMapToBounds(order),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.ez_deliver_tracksure',
                      ),
                      MarkerLayer(markers: _buildMapMarkers(order)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16), // Spacing after map
            // --- Status Text ---
            Center(
              child: Text(
                _getStatusText(status),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            // --- Image Section ---
            imageSection, // Display the built image section
            // --- Rider Info Header ---
            if (rider != null ||
                status !=
                    'pending') // Show header if rider assigned or past pending
              const Padding(
                padding: EdgeInsets.only(top: 10.0), // Add some top margin
                child: Center(
                  child: Text(
                    'ข้อมูลไรเดอร์', // Simplified header
                    style: TextStyle(
                      fontSize: 18, // Slightly smaller header
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),

            // --- Rider Info Card ---
            if (rider != null || status != 'pending') // Show card conditionally
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  8.0,
                  16.0,
                  16.0,
                ), // Adjusted padding
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ), // Lighter border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15), // Softer shadow
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: rider != null
                      ? Row(
                          // Use Row for better alignment
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Left column for labels
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'ชื่อ:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'เบอร์โทร:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'ทะเบียน:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Right column for data
                            Expanded(
                              // Allow data text to wrap if needed
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    rider['rider_name'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ), // Slightly less bold
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rider['rider_phone'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rider['license_plate'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          // Show searching text if rider is null but status is past pending
                          child: Text(
                            status == 'pending'
                                ? 'กำลังค้นหาไรเดอร์...'
                                : 'ไม่พบข้อมูลไรเดอร์',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }

  // --- Helper Widget for Image Card ---
  Widget _buildImageCard({
    String? imageUrl,
    IconData? icon,
    required String title,
    required bool isActive,
    required Color color,
  }) {
    // Wrap with Flexible instead of Expanded if using spaceEvenly/Around
    return Flexible(
      // Use Flexible to allow natural sizing within Row constraints
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum vertical space
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13, // Smaller font size for title
              fontWeight: FontWeight.w600, // Semi-bold
              color: isActive ? textColor : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow title to wrap
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6), // Reduced space
          Container(
            width: 110, // Slightly smaller card
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0), // Less rounded
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2), // Lighter shadow
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isActive
                    ? color.withOpacity(0.5)
                    : Colors.grey.shade200, // Softer border
                width: 1.0,
              ),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryGreen,
                            ),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2.0, // Thinner indicator
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading image ($title): $error");
                        return Center(
                          child: Icon(
                            Icons.error_outline, // Use error icon
                            color: Colors.red.shade300,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    // Placeholder Icon
                    child: Icon(
                      icon ??
                          Icons
                              .image, // Default icon if specific one isn't provided
                      size: 45, // Slightly smaller icon
                      color: isActive
                          ? color.withOpacity(0.8)
                          : Colors.grey.shade300, // Muted placeholder color
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- TrackingStep Widget (No changes needed) ---
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
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.white,
            border: Border.all(
              color: isActive
                  ? color
                  : Colors.grey.shade300, // Lighter inactive border
              width: 2.0,
            ),
            boxShadow: isActive
                ? [
                    // Add subtle shadow when active
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isActive
                ? Colors.white
                : Colors.grey.shade400, // Lighter inactive icon
            size: 22.0, // Slightly smaller icon
          ),
        ),
        const SizedBox(height: 6.0), // More space
        SizedBox(
          width: 70, // Allow slightly more width for text
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2, // Allow label to wrap
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10, // Keep font size small
              color: isActive
                  ? Colors.black87
                  : Colors.grey.shade600, // Darker active text
              fontWeight: isActive
                  ? FontWeight.w600
                  : FontWeight.normal, // Semi-bold active text
            ),
          ),
        ),
      ],
    );
  }
}

// --- TrackingStepWithLine Widget (No changes needed) ---
class TrackingStepWithLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final bool hasLine;
  final bool lineCompleted;

  const TrackingStepWithLine({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    this.hasLine = false,
    this.lineCompleted = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Use Expanded to take available space
      child: Row(
        children: [
          // 1. Tracking Step Icon and Label
          TrackingStep(
            icon: icon,
            label: label,
            isActive: isActive,
            color: color,
          ),
          // 2. Connecting Line (if applicable)
          if (hasLine)
            Expanded(
              // Line fills remaining space in the Row
              child: Padding(
                // Adjust padding to align line with the center of the icons vertically
                padding: const EdgeInsets.only(
                  bottom: 28.0,
                ), // Trial and error to align
                child: Container(
                  // Use Container for better control over thickness/color
                  height: 3.0, // Line thickness
                  color: lineCompleted
                      ? color
                      : Colors.grey.shade300, // Lighter inactive line
                ),
              ),
            ),
        ],
      ),
    );
  }
}
