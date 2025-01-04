import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewProfileScreen extends StatelessWidget {
  final String userId;

  ViewProfileScreen({required this.userId});

  // Hàm lấy thông tin người dùng từ collection 'users'
  Future<Map<String, dynamic>> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin người dùng: $e");
    }
    return {};
  }

  // Hàm lấy thông tin thêm từ collection 'travelPlaces'
  Future<Map<String, dynamic>> _fetchTravelPlaces() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('travelPlaces')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Lấy document đầu tiên (giả sử mỗi người dùng chỉ có 1 travelPlace)
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin từ travelPlaces: $e");
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông Tin Cá Nhân'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([_fetchUserProfile(), _fetchTravelPlaces()])
            .then((results) {
          // Gộp dữ liệu từ users và travelPlaces
          final userProfile = results[0];
          final travelPlaces = results[1];
          return {...userProfile, ...travelPlaces};
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi khi tải thông tin cá nhân.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Không tìm thấy thông tin người dùng.'));
          } else {
            Map<String, dynamic> userData = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildDetailCard(Icons.person, 'Tên', userData['name'] ?? 'Không có'),
                  SizedBox(height: 8),
                  _buildDetailCard(Icons.email, 'Email', userData['email'] ?? 'Không có'),
                  SizedBox(height: 8),
                  _buildDetailCard(Icons.phone, 'Số Điện Thoại', userData['phone'] ?? 'Không có'),
                  SizedBox(height: 8),
                  _buildDetailCard(Icons.location_on, 'Địa Chỉ', userData['address'] ?? 'Không có'),
                  SizedBox(height: 8),
                  _buildDetailCard(Icons.place, 'Địa Điểm Yêu Thích', userData['favoritePlace'] ?? 'Không có'),
                  SizedBox(height: 8),
                  _buildDetailCard(Icons.info, 'Thông Tin Thêm', userData['bio'] ?? 'Không có'),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Hàm hiển thị từng mục thông tin
  Widget _buildDetailCard(IconData icon, String title, String value) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.orange, size: 30),
            SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
