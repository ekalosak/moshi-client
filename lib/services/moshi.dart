import 'package:http/http.dart' as http;

final String host = "http://localhost:8080";
final String healthz = "http://localhost:8080/healthz";

/// Run a health check on the Moshi server
Future<bool> healthCheck() async {
  print("healthCheck start");
  try {
    final response = await http.get(Uri.parse(healthz));
    print("\t/healthCheck healthz: ${response.statusCode}");
    print("healthCheck end");
    return (response.statusCode == 200);
  } catch (e) {
    print("\thealthCheck error: $e");
    return false;
  }
}

Future<void> connectWebRTC() async {
  print("connectWebRTC start");
  print("\tTODO");
  return;
}
