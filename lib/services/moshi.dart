import 'package:http/http.dart' as http;

final String host = "http://localhost:8080";
final String healthz = "http://localhost:8080/healthz";

/// Run a health check on the Moshi server
Future<bool> healthCheck() async {
  print("healthCheck [START]");
  try {
    final response = await http.get(Uri.parse(healthz));
    print("healthz: ${response.statusCode}");
    print("healthCheck [END]");
    return (response.statusCode == 200);
  } catch (e) {
    print("\thealthCheck error: $e");
    return false;
  }
}
