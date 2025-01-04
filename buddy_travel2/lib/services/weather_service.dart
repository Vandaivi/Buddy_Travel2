import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '745f4f2c8eb4987a2d30aec89dc6b444';  // Thay bằng API Key của bạn
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // Hàm lấy thông tin thời tiết cho một thành phố
  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final response = await http.get(Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric&lang=vi'));

    if (response.statusCode == 200) {
      // Nếu yêu cầu thành công, trả về dữ liệu JSON
      return json.decode(response.body);
    } else {
      throw Exception('Không thể tải dữ liệu thời tiết');
    }
  }
}
