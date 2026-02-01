import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  ApiService(this.baseUrl);

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<List<dynamic>> getList(String path) async {
    final res = await http.get(_u(path));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;
    throw Exception('GET $path expected List, got: ${decoded.runtimeType}');
    }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST $path failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('POST $path expected Map, got: ${decoded.runtimeType}');
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PUT $path failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('PUT $path expected Map, got: ${decoded.runtimeType}');
  }

  Future<void> delete(String path) async {
    final res = await http.delete(_u(path));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('DELETE $path failed: ${res.statusCode} ${res.body}');
    }
  }
}
