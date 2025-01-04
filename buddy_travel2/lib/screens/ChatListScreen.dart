import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Để sử dụng DateFormat
import 'ChatScreen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Hàm lấy danh sách các cuộc trò chuyện
  Stream<QuerySnapshot> _getChatList() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser!.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Hàm lấy thông tin người tham gia (người nhận)
  Future<Map<String, String>> _getRecipientDetails(String chatId) async {
    try {
      final chatSnapshot = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      final participants = List<String>.from(chatSnapshot['participants']);

      // Lấy thông tin người tham gia không phải là currentUser
      final recipientId = participants.firstWhere((id) => id != currentUser!.uid);
      final recipientSnapshot = await FirebaseFirestore.instance.collection('users').doc(recipientId).get();

      return {
        'recipientId': recipientId,
        'recipientName': recipientSnapshot['name'] ?? 'Không tên',
        'recipientEmail': recipientSnapshot['email'] ?? 'Không có email',
      };
    } catch (e) {
      print("Error getting recipient details: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách trò chuyện'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getChatList(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return Center(child: Text('Chưa có cuộc trò chuyện nào.'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatId = chat.id;
              final lastMessage = chat['lastMessage'] ?? 'Chưa có tin nhắn';
              final lastMessageTime = (chat['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();

              return ListTile(
                title: Text('Cuộc trò chuyện với ${chat['lastMessageSender']}'),
                subtitle: Text(lastMessage),
                trailing: Text(DateFormat('dd/MM/yyyy').format(lastMessageTime)), // Sử dụng DateFormat ở đây
                onTap: () async {
                  // Lấy thông tin người nhận
                  final recipientDetails = await _getRecipientDetails(chatId);
                  if (recipientDetails.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chatId,  // Truyền chatId đúng
                          recipientId: recipientDetails['recipientId']!,
                          recipientName: recipientDetails['recipientName']!,
                          recipientEmail: recipientDetails['recipientEmail']!,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
