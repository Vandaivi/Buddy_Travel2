import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // Kiểm tra người dùng đã đăng nhập chưa
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để xem lịch sử chuyến đi!'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch Sử Chuyến Đi'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: user.uid) // Lọc theo userId
                    .orderBy('time', descending: true) // Sắp xếp theo thời gian thông báo
                    .snapshots(),
                builder: (context, snapshot) {
                  // Hiển thị trạng thái chờ
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Kiểm tra lỗi khi tải dữ liệu
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Lỗi khi tải dữ liệu!'),
                    );
                  }

                  // Kiểm tra dữ liệu trống
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Chưa có thông báo nào!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  // Lấy danh sách thông báo từ Firestore
                  final notifications = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final notificationTime = (notification['time'] as Timestamp).toDate();
                      final message = notification['message'] ?? 'Không có thông báo';
                      final tripName = notification['tripName'] ?? 'Không có tên chuyến đi';

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.notifications,
                            color: Colors.orange,
                          ),
                          title: Text(
                            tripName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thông báo: $message',
                                style: TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'Thời gian: ${notificationTime.toLocal()}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () {
                            // Mở chi tiết thông báo nếu cần
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
