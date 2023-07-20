import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

const serverProtocol = "http";
const serverName = "localhost";
const serverPort = "8080";
const serverEndpoint = "$serverProtocol://$serverName:$serverPort";
final healthzEndpoint = Uri.parse("$serverEndpoint/healthz");
final offerEndpoint = Uri.parse("$serverEndpoint/offer");

/// Run a health check on the Moshi server
Future<bool> healthCheck() async {
  print("healthCheck [START]");
  try {
    final response = await http.get(healthzEndpoint);
    print("/healthz: ${response.statusCode}");
    print("healthCheck [END]");
    return (response.statusCode == 200);
  } catch (e) {
    print("\thealthCheck error: $e");
    return false;
  }
}

/// Send WebRTC SDP offer to Moshi server
Future<RTCSessionDescription?> sendOfferGetAnswer(RTCSessionDescription offer) async {
  print("sendOfferGetAnswer [START]");
  try {
    final response = await http.post(
      offerEndpoint,
      body: jsonEncode(offer.toMap())
    );
    print("/offer: ${response.statusCode}");
    print("\t${response.body}");
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      print("sendOfferGetAnswer [END]");
      return RTCSessionDescription(data['sdp'], data['type']);
    } else {
      print("sendOfferGetAnswer: Error: /offer ${response.body}");
      return null;
    }
  } catch (e) {
    print("sendOfferGetAnswer: Error: /offer $e");
    return null;
  }
}
