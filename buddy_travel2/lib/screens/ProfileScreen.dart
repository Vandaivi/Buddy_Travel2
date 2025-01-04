import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'UpdateProfileScreen.dart';
import 'LoginScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _dob = '';
  String _gender = 'Nam';
  String _address = '';
  String _hobbies = '';
  String _travelPlaces = '';
  String _maritalStatus = 'Chưa kết hôn';
  String _phone = '';
  String _profilePictureUrl = '';
  bool _isLoading = true;

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            _name = snapshot['name'] ?? '';
            _dob = snapshot['dob'] ?? '';
            _gender = snapshot['gender'] ?? 'Nam';
            _address = snapshot['address'] ?? '';
            _hobbies = snapshot['hobbies'] ?? '';
            _travelPlaces = snapshot['travelPlaces'] ?? '';
            _maritalStatus = snapshot['maritalStatus'] ?? 'Chưa kết hôn';
            _phone = snapshot['phone'] ?? '';
            _profilePictureUrl = snapshot['avatarUrl'] ?? '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu. Vui lòng thử lại!')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất không thành công. Vui lòng thử lại!')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trang Hồ Sơ'),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profilePictureUrl.isNotEmpty
                    ? NetworkImage(_profilePictureUrl)
                    : AssetImage('assets/images/chud.jpg') as ImageProvider,
                backgroundColor: Colors.orangeAccent,
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Email: ${_auth.currentUser?.email ?? ''}',
                      style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                    ),
                    SizedBox(height: 20),
                    _buildProfileDetail('Họ tên', _name),
                    _buildProfileDetail('Ngày sinh', _dob),
                    _buildProfileDetail('Giới tính', _gender),
                    _buildProfileDetail('Địa chỉ', _address),
                    _buildProfileDetail('Sở thích', _hobbies),
                    _buildProfileDetail('Nơi đã đi du lịch', _travelPlaces),
                    _buildProfileDetail('Tình trạng hôn nhân', _maritalStatus),
                    _buildProfileDetail('Số điện thoại', _phone),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UpdateProfileScreen()),
                  ).then((_) => _loadProfile()); // Làm mới dữ liệu sau khi cập nhật
                },
                child: Text('Cập nhật thông tin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Chưa có thông tin',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
