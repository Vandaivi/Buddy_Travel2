import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Để định dạng ngày tháng

import 'package:buddy_travel2/screens/ProfileScreen.dart'; // Điều hướng trở lại trang ProfileScreen sau khi cập nhật

class UpdateProfileScreen extends StatefulWidget {
  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  String _name = '';
  String _dob = '';
  String _gender = 'Nam'; // Mặc định là Nam
  String _address = '';
  String _hobbies = '';
  String _travelPlaces = '';
  String _maritalStatus = 'Chưa kết hôn'; // Mặc định là chưa kết hôn
  String _phone = ''; // Thêm biến số điện thoại

  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Lấy thông tin khi khởi tạo
  }

  // Hàm tải thông tin người dùng từ Firestore
  Future<void> _loadProfile() async {
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
          _phone = snapshot['phone'] ?? ''; // Lấy số điện thoại từ Firestore
        });
      }
    }
  }

  // Hàm lưu thông tin vào Firestore
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final User? user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _name,
          'dob': _dob,
          'gender': _gender,
          'address': _address,
          'hobbies': _hobbies,
          'travelPlaces': _travelPlaces,
          'maritalStatus': _maritalStatus,
          'phone': _phone, // Lưu số điện thoại
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thông tin đã lưu thành công')),
        );

        // Sau khi lưu thông tin thành công, điều hướng lại trang ProfileScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      }
    }
  }

  // Hàm chọn ngày sinh
  Future<void> _selectDateOfBirth(BuildContext context) async {
    DateTime initialDate = _dob.isEmpty ? DateTime.now() : DateFormat('dd/MM/yyyy').parse(_dob);
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        _dob = DateFormat('dd/MM/yyyy').format(pickedDate); // Định dạng lại ngày sinh
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cập nhật Hồ Sơ'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              // Họ tên
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Họ tên'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập họ tên'
                    : null,
                onChanged: (value) {
                  setState(() {
                    _name = value;
                  });
                },
              ),
              SizedBox(height: 20),
              // Ngày sinh
              GestureDetector(
                onTap: () => _selectDateOfBirth(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(text: _dob),
                    decoration: InputDecoration(labelText: 'Ngày sinh'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Vui lòng chọn ngày sinh'
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Giới tính
              DropdownButtonFormField<String>(
                value: _gender,
                items: ['Nam', 'Nữ', 'Khác']
                    .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Giới tính'),
              ),
              SizedBox(height: 20),
              // Địa chỉ
              TextFormField(
                initialValue: _address,
                decoration: InputDecoration(labelText: 'Địa chỉ'),
                onChanged: (value) {
                  setState(() {
                    _address = value;
                  });
                },
              ),
              SizedBox(height: 20),
              // Sở thích
              TextFormField(
                initialValue: _hobbies,
                decoration: InputDecoration(labelText: 'Sở thích'),
                onChanged: (value) {
                  setState(() {
                    _hobbies = value;
                  });
                },
              ),
              SizedBox(height: 20),
              // Nơi đã đi du lịch
              TextFormField(
                initialValue: _travelPlaces,
                decoration: InputDecoration(labelText: 'Nơi đã đi du lịch'),
                onChanged: (value) {
                  setState(() {
                    _travelPlaces = value;
                  });
                },
              ),
              SizedBox(height: 20),
              // Tình trạng hôn nhân
              DropdownButtonFormField<String>(
                value: _maritalStatus,
                items: ['Chưa kết hôn', 'Đã kết hôn', 'Khác']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _maritalStatus = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Tình trạng hôn nhân'),
              ),
              SizedBox(height: 20),
              // Số điện thoại
              TextFormField(
                initialValue: _phone,
                decoration: InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  setState(() {
                    _phone = value;
                  });
                },
              ),
              SizedBox(height: 30),
              // Nút lưu thông tin
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text('Lưu thông tin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
