import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PlanScreen extends StatefulWidget {
  final Function(Map<String, String>) addTrip;

  PlanScreen({required this.addTrip});

  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _estimatedCostController = TextEditingController();
  final TextEditingController _numPeopleController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Hàm để hiển thị DatePicker và cập nhật giá trị cho trường ngày
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      String formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      controller.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lập Kế Hoạch Chuyến Đi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                controller: _tripNameController,
                label: 'Tên chuyến đi',
                icon: Icons.travel_explore,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: _locationController,
                label: 'Địa điểm',
                icon: Icons.location_on,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: _estimatedCostController,
                label: 'Chi phí ước tính',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: _numPeopleController,
                label: 'Số người tham gia',
                icon: Icons.people,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: _startDateController,
                label: 'Ngày bắt đầu (yyyy-MM-dd)',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.datetime,
                onTap: () => _selectDate(context, _startDateController), // Mở lịch khi nhấn vào trường này
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: _endDateController,
                label: 'Ngày kết thúc (yyyy-MM-dd)',
                icon: Icons.calendar_month,
                keyboardType: TextInputType.datetime,
                onTap: () => _selectDate(context, _endDateController), // Mở lịch khi nhấn vào trường này
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  onPressed: _saveTrip,
                  child: Text(
                    'Lưu Chuyến Đi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm tạo ô nhập liệu cho các trường
  Widget _buildInputField({required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    Function()? onTap}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onTap: onTap,  // Mở lịch khi nhấn vào trường này
      readOnly: onTap != null,  // Làm cho trường này chỉ đọc khi có onTap
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(),
      ),
    );
  }

  // Hàm lưu chuyến đi vào Firestore
  Future<void> _saveTrip() async {
    final tripName = _tripNameController.text;
    final location = _locationController.text;
    final estimatedCost = _estimatedCostController.text;
    final numPeople = _numPeopleController.text;
    final startDate = _startDateController.text;
    final endDate = _endDateController.text;

    // Kiểm tra xem tất cả các trường có được điền đầy đủ không
    if (tripName.isEmpty ||
        location.isEmpty ||
        estimatedCost.isEmpty ||
        numPeople.isEmpty ||
        startDate.isEmpty ||
        endDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng điền đầy đủ thông tin!')),
      );
      return;
    }

    // Kiểm tra xem estimatedCost và numPeople có phải là số hợp lệ không
    if (double.tryParse(estimatedCost) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chi phí ước tính phải là một số hợp lệ!')),
      );
      return;
    }

    if (int.tryParse(numPeople) == null || int.parse(numPeople) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số người tham gia phải là một số nguyên dương!')),
      );
      return;
    }

    // Kiểm tra định dạng ngày tháng cho startDate và endDate
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(startDate) || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ngày phải có định dạng yyyy-MM-dd!')),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đăng nhập trước khi tạo chuyến đi!')),
      );
      return;
    }

    try {
      // Lưu chuyến đi vào Firestore
      await FirebaseFirestore.instance.collection('trips').add({
        'tripName': tripName,
        'location': location,
        'estimatedCost': estimatedCost,
        'numPeople': numPeople,
        'startDate': startDate,
        'endDate': endDate,
        'userEmail': user.email,
        'userId': user.uid,
        'createdAt': Timestamp.now(),
      });

      // Lưu lịch sử chuyến đi vào 'trip_history'
      await FirebaseFirestore.instance.collection('trip_history').add({
        'message': 'Chuyến đi mới: $tripName',
        'tripTime': Timestamp.now(),
        'userId': user.uid,
      });

      // Gọi callback addTrip để cập nhật màn hình chính
      widget.addTrip({
        'tripName': tripName,
        'location': location,
        'estimatedCost': estimatedCost,
        'numPeople': numPeople,
        'startDate': startDate,
        'endDate': endDate,
        'userEmail': user.email!,
        'userId': user.uid,
      });

      // Hiển thị thông báo thành công mà không quay lại trang chính
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chuyến đi đã được tạo thành công!')),
      );
    } catch (e) {
      // Hiển thị thông báo lỗi chi tiết khi có vấn đề
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: ${e.toString()}')),
      );
    }
  }
}
