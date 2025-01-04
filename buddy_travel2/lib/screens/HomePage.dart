import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'TripDetailScreen.dart'; // Màn hình chi tiết chuyến đi

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> trips;

  HomePage({required this.trips});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _filteredTrips = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadTrips();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    });

    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('trips').get();
      List<Map<String, dynamic>> trips = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          trips.add({
            'id': doc.id,
            'tripName': data['tripName'] ?? 'Không có tên chuyến đi',
            'location': data['location'] ?? 'Không có địa điểm',
            'estimatedCost': data['estimatedCost']?.toString() ?? '0',
            'numPeople': data['numPeople']?.toString() ?? '0',
            'startDate': data['startDate'] ?? 'Không có ngày bắt đầu',
            'endDate': data['endDate'] ?? 'Không có ngày kết thúc',
            'userEmail': data['userEmail'] ?? 'Không xác định',
            'userId': data['userId'] ?? 'Không xác định',
            'participants': List<String>.from(data['participants'] ?? []),
            'comments': List<Map<String, String>>.from(data['comments'] ?? []),
          });
        }
      }

      setState(() {
        _trips = trips;
        _filteredTrips = trips;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading trips: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể tải chuyến đi.')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTrips(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTrips = _trips;
      });
    } else {
      setState(() {
        _filteredTrips = _trips.where((trip) {
          return trip['tripName']!.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _joinTrip(String tripId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? userEmail = user?.email;

    if (userEmail != null) {
      bool? confirmJoin = await showDialog<bool>(context: context, builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận tham gia'),
          content: Text('Bạn có chắc chắn muốn tham gia chuyến đi này không?'),
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
      });

      if (confirmJoin == true) {
        try {
          DocumentReference tripRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
          await tripRef.update({
            'participants': FieldValue.arrayUnion([userEmail]),
          });

          // Thêm thông báo cho người tạo chuyến đi
          final tripData = await tripRef.get();
          final tripName = tripData['tripName'] ?? 'Không có tên chuyến đi';
          final userId = tripData['userId'] ?? '';

          // Thêm thông báo vào bộ sưu tập notifications
          FirebaseFirestore.instance.collection('notifications').add({
            'userId': userId, // Người tạo chuyến đi
            'message': 'Có người đã tham gia chuyến đi của bạn!',
            'tripName': tripName,
            'time': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bạn đã tham gia chuyến đi!')));
          _loadTrips(); // Tải lại chuyến đi để cập nhật danh sách người tham gia
        } catch (e) {
          print("Lỗi khi tham gia chuyến đi: $e");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể tham gia chuyến đi.')));
        }
      }
    }
  }

  Future<void> _deleteTrip(String tripId) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final tripData = await FirebaseFirestore.instance.collection('trips').doc(tripId).get();
      final tripOwnerId = tripData['userId'];

      if (user.uid == tripOwnerId) {
        bool? confirmDelete = await showDialog<bool>(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Xác nhận xóa chuyến đi'),
            content: Text('Bạn có chắc chắn muốn xóa chuyến đi này không?'),
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
        });

        if (confirmDelete == true) {
          try {
            // Xóa chuyến đi từ Firestore
            await FirebaseFirestore.instance.collection('trips').doc(tripId).delete();

            // Cập nhật danh sách chuyến đi
            _loadTrips();

            // Hiển thị thông báo
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chuyến đi đã được xóa')));
          } catch (e) {
            print("Lỗi khi xóa chuyến đi: $e");
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể xóa chuyến đi')));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bạn không có quyền xóa chuyến đi này')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh Sách Chuyến Đi'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TextField for search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm chuyến đi...',
                prefixIcon: Icon(Icons.search, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterTrips,
            ),
            SizedBox(height: 16),

            // Expanded widget to ensure the list of trips does not overflow
            Expanded(
              child: _isLoading
                  ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Đang tải chuyến đi...", style: TextStyle(fontSize: 16)),
                ],
              ))
                  : _filteredTrips.isEmpty
                  ? Center(child: Text('Không tìm thấy chuyến đi nào!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)))
                  : ListView.builder(
                itemCount: _filteredTrips.length,
                itemBuilder: (context, index) {
                  final trip = _filteredTrips[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.location_on, size: 30, color: Colors.white),
                        ),
                        title: Text(
                          trip['tripName'] ?? 'Không có tên chuyến đi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('Địa điểm: ${trip['location'] ?? 'Không có địa điểm'}', style: TextStyle(color: Colors.black54)),
                            SizedBox(height: 4),
                            Text('Người tạo: ${trip['userEmail']}', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        trailing: Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                _joinTrip(trip['id']);
                              },
                            ),
                            if (trip['userId'] == FirebaseAuth.instance.currentUser?.uid)
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteTrip(trip['id']);
                                },
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripDetailScreen(tripData: trip),
                            ),
                          );
                        },
                      ),
                    ),
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
