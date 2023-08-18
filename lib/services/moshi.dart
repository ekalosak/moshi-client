/// This module is responsible for communicating with the Moshi server.
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

// import 'package:flutter/foundation.dart';
// const serverProtocol = "http";
// final String serverName = (defaultTargetPlatform == TargetPlatform.iOS) ? 'localhost' : '10.0.2.2';
// const serverPort = "8080";
// final String serverEndpoint = "$serverProtocol://$serverName:$serverPort";
const serverProtocol = "https";
const serverName = "dev.chatmoshi.com";
const serverPort = "443";
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

class AuthError implements Exception {
  final String message;
  AuthError(this.message);
}

class RateLimitError implements Exception {
  final String message;
  RateLimitError(this.message);
}

class ServerError implements Exception {
  final String message;
  ServerError([this.message = ""]);
}

/// Send WebRTC SDP offer to Moshi server
Future<RTCSessionDescription> sendOfferGetAnswer(
  RTCSessionDescription offer,
) async {
  print("sendOfferGetAnswer [START]");
  String? token = await FirebaseAuth.instance.currentUser!.getIdToken();
  if (token == null) {
    print("sendOfferGetAnswer: Error: token is null");
    throw AuthError("Auth token is null");
  }
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
  } else if (response.statusCode == 401) {
    throw AuthError("Auth token invalid");
  } else if (response.statusCode == 429) {
    Map<String, dynamic> data = jsonDecode(response.body);
    throw RateLimitError(data['detail']);
  } else {
    throw ServerError("Server error: ${response.statusCode}");
  }
}
