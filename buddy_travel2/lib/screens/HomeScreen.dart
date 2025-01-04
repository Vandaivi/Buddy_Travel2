import 'package:flutter/material.dart';
import 'package:buddy_travel2/screens/WeatherScreen.dart';  // Import WeatherScreen
import 'package:buddy_travel2/screens/ChatListScreen.dart';
import 'package:buddy_travel2/screens/ChatScreen.dart';
import 'package:buddy_travel2/screens/ProfileScreen.dart'; // Thêm màn hình cập nhật thông tin cá nhân
import 'HomePage.dart';
import 'PlanScreen.dart';
import 'HistoryScreen.dart';
import 'PostScreen.dart';
import 'ProfileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, String>> _trips = []; // Danh sách chuyến đi

  // Khai báo danh sách các màn hình
  late List<Widget> _screens;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Hàm thêm chuyến đi vào danh sách
  void _addTrip(Map<String, String> tripData) {
    setState(() {
      _trips.add(tripData);
    });
  }

  @override
  void initState() {
    super.initState();

    // Khởi tạo danh sách các màn hình
    _screens = [
      HomePage(trips: _trips),
      PlanScreen(addTrip: _addTrip),
      HistoryScreen(),
      PostScreen(),
      ChatListScreen(),
    ];

    // Kiểm tra thông tin cá nhân ngay sau khi HomeScreen được khởi tạo
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Truy vấn thông tin cá nhân từ Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists || doc['fullName'] == null || doc['fullName'].isEmpty) {
        // Nếu thông tin cá nhân chưa hoàn thiện, hiển thị thông báo và điều hướng
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Thông báo'),
              content: Text('Bạn cần cập nhật thông tin cá nhân trước khi sử dụng ứng dụng.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                  child: Text('Cập nhật'),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/chud.jpg',
              width: 100,
              height: 50,
            ),
            SizedBox(width: 8),
            Text(
              'Buddy Travel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ProfileScreen(),
              ));
            },
          ),
          IconButton(
            icon: Icon(Icons.cloud),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => WeatherScreen(),
              ));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lập Kế Hoạch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch Sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Bài Viết',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Tin Nhắn',
          ),
        ],
      ),
    );
  }
}
