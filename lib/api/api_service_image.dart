import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageUploadService {
  // --- ตั้งค่าสำหรับ Cloudinary ---
  // ชื่อนามแฝง Cloudinary ของคุณ
  final String _cloudName = 'di5rnsb7e';
  // ชื่อ Upload Preset ที่คุณสร้างไว้ใน Cloudinary
  final String _preset = 'delivery';

  /// อัปโหลดไฟล์รูปภาพไปยัง Cloudinary และคืนค่าเป็น URL ของรูปภาพ
  ///
  /// [imageFile] คือ File object ของรูปภาพที่ต้องการอัปโหลด
  /// คืนค่า [Future<String>] ซึ่งเป็น secure_url ของรูปภาพที่อัปโหลดสำเร็จ
  Future<String> uploadImageToCloudinary(File imageFile) async {
    // 1. สร้าง URL สำหรับ Cloudinary API endpoint
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    // 2. สร้าง MultipartRequest สำหรับการส่งข้อมูลแบบฟอร์มที่มีไฟล์
    var request = http.MultipartRequest('POST', uri);

    // 3. เพิ่มค่า upload_preset และพารามิเตอร์อื่นๆ ที่จำเป็น
    request.fields['upload_preset'] = _preset;

    // 4. เพิ่มไฟล์รูปภาพลงใน request
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Key ที่ Cloudinary ต้องการสำหรับไฟล์
        imageFile.path,
      ),
    );

    try {
      // 5. ส่ง request และรอการตอบกลับ
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 6. ตรวจสอบสถานะการตอบกลับ
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // 7. ดึงค่า secure_url ออกมาและคืนค่ากลับไป
        if (responseBody['secure_url'] != null) {
          return responseBody['secure_url'];
        } else {
          // กรณีที่สำเร็จแต่ไม่พบ URL ในการตอบกลับ
          throw Exception(
            'Cloudinary API Error: "secure_url" not found in response.',
          );
        }
      } else {
        // กรณีที่ API ตอบกลับด้วยสถานะอื่นที่ไม่ใช่ 200 (สำเร็จ)
        print('Error from Cloudinary: ${response.body}');
        throw Exception(
          'Failed to upload image. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // จัดการกับข้อผิดพลาดที่อาจเกิดขึ้นระหว่างการเชื่อมต่อ
      print('An error occurred during image upload: $e');
      throw Exception('An error occurred while uploading the image.');
    }
  }
}
