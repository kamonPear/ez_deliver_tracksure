import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RiderLiveLocation extends StatefulWidget {
  final String riderId;   // = FirebaseAuth.instance.currentUser!.uid
  final String orderId;   // id ออเดอร์ที่รับอยู่
  const RiderLiveLocation({super.key, required this.riderId, required this.orderId});

  @override
  State<RiderLiveLocation> createState() => _RiderLiveLocationState();
}

class _RiderLiveLocationState extends State<RiderLiveLocation> {
  StreamSubscription<Position>? _sub;

  @override
  void initState() {
    super.initState();
    _ensurePermissionThenStart();
  }

  Future<void> _ensurePermissionThenStart() async {
    final service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเปิด GPS ก่อนนะ')),
      );
      return;
    }
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่ได้รับสิทธิ์ตำแหน่ง')),
      );
      return;
    }

    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // อัปเดตเมื่อขยับ ≥10m
      ),
    ).listen(_writeToFirestore, onError: (e) {
      debugPrint('location error: $e');
    });

    // เขียนตำแหน่งเริ่มต้นทันที
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    await _writeToFirestore(pos);
  }

  Future<void> _writeToFirestore(Position position) async {
    final lat = position.latitude;
    final lng = position.longitude;

    // 1) เขียนที่ riders/{riderId}
    await FirebaseFirestore.instance.collection('riders').doc(widget.riderId).set({
      'current_latitude': lat,
      'current_longitude': lng,
      'last_updated': FieldValue.serverTimestamp(),
      'is_online': true,
    }, SetOptions(merge: true));

    // 2) มิเรอร์ไปที่ orders/{orderId} ด้วย (ให้ฝั่งลูกค้าอ่านได้ง่าย)
    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).set({
      'rider_last_location': GeoPoint(lat, lng),
      'rider_last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('กำลังส่งพิกัด…')));
  }
}
