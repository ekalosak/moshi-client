/// This module is responsible for communicating with the Moshi server.
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

const serverProtocol = "http";
const serverName = "localhost";
const serverPort = "8080";
const serverEndpoint = "$serverProtocol://$serverName:$serverPort";
final healthzEndpoint = Uri.parse("$serverEndpoint/healthz");
final offerEndpoint = Uri.parse("$serverEndpoint/call/unstructured");

/// Run a health check on the Moshi server
Future<bool> healthCheck() async {
  print("healthCheck [START]");
  try {
    print("health endpoint: ${healthzEndpoint.toString()}");
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
Future<RTCSessionDescription?> sendOfferGetAnswer(
  RTCSessionDescription offer,
) async {
  print("sendOfferGetAnswer [START]");
  String token = await FirebaseAuth.instance.currentUser!.getIdToken();
  try {
    print("offer endpoint: ${offerEndpoint.toString()}");
    final response = await http.post(
      offerEndpoint,
      body: jsonEncode(offer.toMap()),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("offer response code: ${response.statusCode}");
    print("offer response body: ${response.body}");
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      print("sendOfferGetAnswer [END]");
      return RTCSessionDescription(data['sdp'], data['type']);
    } else {
      print("sendOfferGetAnswer: Error: failed to get answer from server");
      return null;
    }
  } catch (e) {
    print("sendOfferGetAnswer: Error: $e");
    return null;
  }
}
