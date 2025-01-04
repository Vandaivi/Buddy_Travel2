import 'package:flutter/material.dart';

class TripSearchDelegate extends SearchDelegate {
  final List<Map<String, String>> trips;

  TripSearchDelegate({required this.trips});

  @override
  List<Widget> buildActions(BuildContext context) {
    // Thêm nút xóa tìm kiếm
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';  // Xóa thanh tìm kiếm khi bấm vào nút xóa
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // Thêm nút quay lại
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Hiển thị kết quả tìm kiếm
    final List<Map<String, String>> filteredTrips = trips.where((trip) {
      return trip['tripName']!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredTrips.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4.0,
          margin: EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Text(filteredTrips[index]['tripName'] ?? 'Không có tên chuyến đi'),
            subtitle: Text(filteredTrips[index]['location'] ?? 'Không có địa điểm'),
            onTap: () {
              // Thực hiện hành động khi người dùng chọn chuyến đi
              // Bạn có thể mở màn hình chi tiết chuyến đi ở đây
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Hiển thị gợi ý khi người dùng đang nhập
    final List<Map<String, String>> filteredTrips = trips.where((trip) {
      return trip['tripName']!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredTrips.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(filteredTrips[index]['tripName'] ?? 'Không có tên chuyến đi'),
          subtitle: Text(filteredTrips[index]['location'] ?? 'Không có địa điểm'),
        );
      },
    );
  }
}
