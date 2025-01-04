// chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createChat(String recipientId) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    final chatId = FirebaseFirestore.instance.collection('chats').doc().id; // Tạo ID cho cuộc trò chuyện mới

    // Tạo cuộc trò chuyện mới trong Firestore
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser.uid, recipientId], // Thêm ID của người tham gia
      'lastMessage': 'Chưa có tin nhắn nào', // Tin nhắn mặc định
      'lastMessageTime': FieldValue.serverTimestamp(), // Thời gian hiện tại
      'createdAt': FieldValue.serverTimestamp(), // Thời gian tạo cuộc trò chuyện
    });

    print("Cuộc trò chuyện đã được tạo với ID: $chatId");
  } else {
    print("Người dùng chưa đăng nhập");
  }
}
