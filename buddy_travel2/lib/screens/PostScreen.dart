import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ChatScreen.dart';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Create a post
  void _createPost() async {
    if (currentUser == null || _postController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'content': _postController.text.trim(),
        'userId': currentUser!.uid,
        'userName': currentUser!.displayName ?? 'Anonymous',
        'email': currentUser!.email ?? 'No email',
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
      });

      _postController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Bài viết đã được đăng')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // Send a comment
  void _sendComment(String postId) async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'content': _commentController.text.trim(),
        'userId': currentUser!.uid,
        'userName': currentUser!.displayName ?? 'Anonymous',
        'email': currentUser!.email ?? 'No email',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // Get the details of the post owner (recipient)
  Future<Map<String, String>> _getRecipientDetails(String postId) async {
    try {
      final postSnapshot = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      final userId = postSnapshot['userId'];

      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      return {
        'recipientId': userId,
        'recipientName': userSnapshot['name'] ?? 'Không tên',
        'recipientEmail': userSnapshot['email'] ?? 'Không có email',
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
        title: Text('Bài Viết'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.view_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewPostsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input field for new post
            TextField(
              controller: _postController,
              decoration: InputDecoration(
                  labelText: 'Chia sẻ bài viết của bạn',
                  border: OutlineInputBorder()),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createPost,
              child: Text('Đăng Bài Viết'),
            ),
            SizedBox(height: 16),
            // Display the list of posts
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!.docs;
                  if (posts.isEmpty) {
                    return Center(child: Text('Chưa có bài viết nào.'));
                  }

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final postId = post.id;
                      final content = post['content'] ?? 'Nội dung không khả dụng';
                      final userName = post['userName'] ?? 'Anonymous';
                      final postTime = (post['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final userEmail = post['email'] ?? 'Không có email';

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_circle, size: 30),
                                  SizedBox(width: 8),
                                  Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                                  Spacer(),
                                  Text(userEmail, style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(content, style: TextStyle(fontSize: 16)),
                              SizedBox(height: 8),
                              Text('Được đăng vào: ${DateFormat('dd/MM/yyyy HH:mm').format(postTime)}'),
                              SizedBox(height: 16),
                              // Display comments for the post
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(postId)
                                    .collection('comments')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, commentSnapshot) {
                                  if (!commentSnapshot.hasData) {
                                    return Center(child: CircularProgressIndicator());
                                  }

                                  final comments = commentSnapshot.data!.docs;
                                  if (comments.isEmpty) {
                                    return Text('Chưa có bình luận.');
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: comments.length,
                                    itemBuilder: (context, commentIndex) {
                                      final comment = comments[commentIndex];
                                      final commentContent =
                                          comment['content'] ?? 'Nội dung không khả dụng';
                                      final commentUserName =
                                          comment['userName'] ?? 'Anonymous';
                                      final commentUserEmail =
                                          comment['email'] ?? 'No email';
                                      return ListTile(
                                        leading: Icon(Icons.account_circle),
                                        title: Text(commentUserName),
                                        subtitle: Text(commentUserEmail, style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        trailing: Text(commentContent),
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  labelText: 'Bình luận...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _sendComment(postId),
                                child: Text('Gửi Bình luận'),
                              ),
                            ],
                          ),
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

class ViewPostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh Sách Bài Viết'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;
          if (posts.isEmpty) {
            return Center(child: Text('Chưa có bài viết nào.'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post.id;
              final content = post['content'] ?? 'Nội dung không khả dụng';
              final userName = post['userName'] ?? 'Anonymous';
              final postTime = (post['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hiển thị thông tin bài viết
                      Row(
                        children: [
                          Icon(Icons.account_circle, size: 30),
                          SizedBox(width: 8),
                          Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(content, style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Được đăng vào: ${DateFormat('dd/MM/yyyy HH:mm').format(postTime)}'),
                      Divider(),
                      // Hiển thị danh sách bình luận
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .collection('comments')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, commentSnapshot) {
                          if (!commentSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final comments = commentSnapshot.data!.docs;
                          if (comments.isEmpty) {
                            return Text('Chưa có bình luận nào.', style: TextStyle(color: Colors.grey));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, commentIndex) {
                              final comment = comments[commentIndex];
                              final commentContent = comment['content'] ?? 'Nội dung không khả dụng';
                              final commentUserName = comment['userName'] ?? 'Anonymous';
                              final commentTime = (comment['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.comment, size: 24, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$commentUserName',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(commentContent),
                                          SizedBox(height: 4),
                                          Text(
                                            'Bình luận vào: ${DateFormat('dd/MM/yyyy HH:mm').format(commentTime)}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
