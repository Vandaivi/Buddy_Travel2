import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:buddy_travel2/screens/ChatScreen.dart';
import 'package:buddy_travel2/screens/ViewProfileScreen.dart';

class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tripData;

  TripDetailScreen({required this.tripData});

  // Hàm mở màn hình nhắn tin
  void _sendMessageToUser(BuildContext context, String recipientId, String recipientName, String recipientEmail) {
    // Tạo ID cuộc trò chuyện duy nhất giữa người gửi và người nhận
    String chatId = _createChatId(FirebaseAuth.instance.currentUser!.uid, recipientId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          recipientId: recipientId,
          recipientName: recipientName,
          recipientEmail: recipientEmail,
        ),
      ),
    );
  }

  // Hàm tạo ID cuộc trò chuyện duy nhất
  String _createChatId(String userId, String recipientId) {
    List<String> ids = [userId, recipientId];
    ids.sort();  // Sắp xếp để tạo ID duy nhất
    return '${ids[0]}_${ids[1]}';
  }

  // Hàm xóa chuyến đi
  Future<void> _deleteTrip(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.uid == tripData['userId']) {
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Xác Nhận Xóa Chuyến Đi'),
            content: Text('Bạn có chắc chắn muốn xóa chuyến đi này?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Người dùng chọn "Không"
                },
                child: Text('Không'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Người dùng chọn "Có"
                },
                child: Text('Có'),
              ),
            ],
          );
        },
      );

      if (confirmDelete == true) {
        try {
          // Xóa chuyến đi từ Firestore
          await FirebaseFirestore.instance.collection('trips').doc(tripData['id']).delete();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chuyến đi đã được xóa')));

          Navigator.pop(context, true); // Trả về thông báo xóa thành công
        } catch (e) {
          print("Lỗi khi xóa chuyến đi: $e");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể xóa chuyến đi')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bạn không có quyền xóa chuyến đi này')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Chuyến Đi'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailCard(Icons.location_on, 'Tên Chuyến Đi', tripData['tripName'] ?? 'Chưa có tên'),
            SizedBox(height: 8),
            _buildDetailCard(Icons.place, 'Địa Điểm', tripData['location'] ?? 'Chưa có địa điểm'),
            SizedBox(height: 8),
            _buildDetailCard(Icons.attach_money, 'Chi Phí Dự Kiến', tripData['estimatedCost'] ?? 'Chưa có chi phí'),
            SizedBox(height: 8),
            _buildDetailCard(Icons.people, 'Số Người Tham Gia', tripData['numPeople'] ?? 'Chưa có số người'),
            SizedBox(height: 8),
            _buildDetailCard(Icons.calendar_today, 'Ngày Bắt Đầu', tripData['startDate'] ?? 'Chưa có ngày bắt đầu'),
            SizedBox(height: 8),
            _buildDetailCard(Icons.calendar_today_outlined, 'Ngày Kết Thúc', tripData['endDate'] ?? 'Chưa có ngày kết thúc'),
            SizedBox(height: 8),
            _buildDetailCard(Icons.person, 'Người Tạo', tripData['userEmail'] ?? 'Không xác định'),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                String recipientId = tripData['userId'] ?? ''; // Kiểm tra nếu userId null thì gán là chuỗi rỗng
                String recipientName = tripData['userEmail'] ?? 'Người tạo chuyến đi'; // Kiểm tra nếu userEmail null thì gán tên mặc định
                String recipientEmail = tripData['userEmail'] ?? 'Người tạo chuyến đi'; // Kiểm tra nếu userEmail null thì gán email mặc định

                if (recipientId.isNotEmpty && recipientEmail.isNotEmpty) {
                  _sendMessageToUser(context, recipientId, recipientName, recipientEmail);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thông tin người tạo chuyến đi không hợp lệ')));
                }
              },
              child: Text('Nhắn Tin Cho Người Tạo Chuyến Đi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                String creatorId = tripData['userId'] ?? '';
                if (creatorId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewProfileScreen(userId: creatorId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể lấy thông tin người tạo chuyến đi')),
                  );
                }
              },
              child: Text('Xem Thông Tin Người Tạo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),

            if (tripData['userId'] == FirebaseAuth.instance.currentUser?.uid)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    _deleteTrip(context); // Gọi hàm xóa chuyến đi
                  },
                  child: Text('Xóa Chuyến Đi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
              ),

            if (tripData['participants'] != null)
              _buildParticipantsSection(tripData['participants'] as List<String>),
          ],
        ),
      ),
    );
  }

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

  Widget _buildParticipantsSection(List<String> participants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Người Tham Gia:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...participants.map((participant) => ListTile(
          leading: Icon(Icons.person, color: Colors.orange),
          title: Text(participant),
        )),
      ],
    );
  }
}
