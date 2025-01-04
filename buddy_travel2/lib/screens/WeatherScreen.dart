import 'package:flutter/material.dart';
import 'package:buddy_travel2/services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();
  String _city = '';
  bool _isLoading = false;
  Map<String, dynamic>? _weatherData;
  String _advice = '';  // Lời khuyên hoặc cảnh báo

  // Gọi hàm lấy thời tiết và xử lý các cảnh báo
  void _getWeather() async {
    if (_city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập tên thành phố')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _advice = '';  // Reset lời khuyên mỗi lần người dùng tìm kiếm
    });

    try {
      WeatherService weatherService = WeatherService();
      Map<String, dynamic> data = await weatherService.fetchWeather(_city);

      setState(() {
        _weatherData = data;
        _advice = _generateAdvice(data);  // Sinh lời khuyên dựa trên dữ liệu
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: Không thể lấy dữ liệu thời tiết')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm sinh lời khuyên dựa trên các chỉ số thời tiết
  String _generateAdvice(Map<String, dynamic> data) {
    double temperature = data['main']['temp'];
    double humidity = data['main']['humidity'];
    double windSpeed = data['wind']['speed'];

    if (temperature > 35) {
      return 'Cảnh báo: Nhiệt độ quá cao! Hãy tránh ra ngoài nếu không cần thiết và uống nhiều nước để tránh say nắng.';
    } else if (temperature < 10) {
      return 'Cảnh báo: Nhiệt độ quá thấp! Hãy mặc ấm và tránh ra ngoài lâu để tránh bị cảm lạnh.';
    } else if (humidity > 80) {
      return 'Cảnh báo: Độ ẩm cao! Cảm giác oi bức và có thể gây khó chịu. Hãy ở trong phòng mát mẻ và uống nước thường xuyên.';
    } else if (windSpeed > 20) {
      return 'Cảnh báo: Gió mạnh! Hãy cẩn thận khi ra ngoài, có thể có nguy cơ bão.';
    } else {
      return 'Thời tiết ổn định. Hãy ra ngoài và tận hưởng ngày mới!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin Thời tiết'),
        backgroundColor: Colors.orange,
        elevation: 10,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Phần nhập tên thành phố
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Nhập tên thành phố',
                  labelStyle: TextStyle(color: Colors.orange),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white70,
                  prefixIcon: Icon(Icons.location_city, color: Colors.orange),
                ),
                onChanged: (value) {
                  setState(() {
                    _city = value;
                  });
                },
              ),
              SizedBox(height: 20),
              // Nút Lấy Thời Tiết
              ElevatedButton(
                onPressed: _getWeather,
                child: Text('Lấy Thời Tiết', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Hiển thị trạng thái Loading hoặc kết quả thời tiết
              _isLoading
                  ? CircularProgressIndicator()
                  : _weatherData != null
                  ? Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Biểu tượng thời tiết
                        Image.network(
                          'http://openweathermap.org/img/wn/${_weatherData!['weather'][0]['icon']}@2x.png',
                          height: 50,
                          width: 50,
                        ),
                        SizedBox(width: 10),
                        Text(
                          '${_weatherData!['weather'][0]['description']}',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Nhiệt độ: ${_weatherData!['main']['temp']}°C',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Độ ẩm: ${_weatherData!['main']['humidity']}%',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Gió: ${_weatherData!['wind']['speed']} m/s',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    // Hiển thị lời khuyên hoặc cảnh báo
                    Text(
                      _advice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
