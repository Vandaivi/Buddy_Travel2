import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String chatId; // ID cuộc trò chuyện
  final String recipientId; // ID người nhận tin nhắn
  final String recipientName; // Tên người nhận tin nhắn
  final String recipientEmail; // Email người nhận tin nhắn

  ChatScreen({
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientEmail,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Hàm gửi tin nhắn
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)  // Sử dụng chatId đã truyền vào
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'senderEmail': currentUser!.email ?? 'No email',  // Thêm email người gửi
      'recipientId': widget.recipientId,
      'recipientEmail': widget.recipientEmail,  // Thêm email người nhận
      'content': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat với ${widget.recipientName}'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Hiển thị các tin nhắn
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)  // Dùng chatId đã nhận từ ChatListScreen
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,  // Đảo ngược danh sách để mới nhất ở dưới
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final messageContent = message['content'];
                    final messageSenderId = message['senderId'];
                    final messageSenderEmail = message['senderEmail'];

                    return ListTile(
                      title: Align(
                        alignment: messageSenderId == currentUser!.uid
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: messageSenderId == currentUser!.uid
                                ? Colors.orange
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(messageContent),
                        ),
                      ),
                      subtitle: Text(
                        messageSenderEmail,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Ô nhập tin nhắn
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage, // Gửi tin nhắn khi nhấn nút
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
