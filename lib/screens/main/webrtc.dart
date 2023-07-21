import 'dart:async';
import 'dart:convert';  // jsonDecode
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';

import '../../services/auth.dart';
import '../../services/moshi.dart' as moshi;
import '../../util.dart' as util;
import '../../widgets/chat.dart';

const connectButtonColor = Colors.tealAccent;
const iceServers = [{'urls': ['stun:stun.l.google.com:19302']}];
const pcConfig = {
  'sdpSemantics': 'unified-plan',
  'iceServers': iceServers,
};

class WebRTCScreen extends StatefulWidget {
  @override
  _WebRTCScreenState createState() => _WebRTCScreenState();
}

class _WebRTCScreenState extends State<WebRTCScreen> {
  MediaStream? _localStream;
  List<MediaDeviceInfo>? _mediaDevicesList;
  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  bool _moshiHealthy = false;
  bool _isRecording = false;
  bool _isConnected = false;
  final List<Message> _messages = [
    Message(Role.ast, "Moshi moshi."),
    Message(Role.usr, "Hey Moshi, what's up?"),
    Message(Role.ast, "Not much my excellent bro, you?"),
  ];
  // final List<Message> _messages = [];  // TODO
  String _iceGatheringState = '';
  String _iceConnectionState = '';
  String _signalingState = '';
  String _dcState = '';

  /// TODO updates the audiogram widget,
  /// TODO sends across the WebRTC channel to Moshi servers.

  @override
  void initState() {
    super.initState();
  }

  /// Clean up the mic stream when the widget is disposed
  @override
  void dispose() async {
    super.dispose();
    await _localStream?.dispose();
    await tearDownWebRTC();
  }

  /// Get mic permissions, check server health, and perform WebRTC connection establishment.
  /// Returns error string if any.
  Future<String?> startPressed() async {
    print("startPressed [START]");
    // Backend server check
    bool healthy = await moshi.healthCheck();
    setState(() {
      _moshiHealthy = healthy;
    });
    if (!healthy) {
      return "Moshi servers unhealthy, please try again.";
    }
    // Microphone check
    final String? err = await startMicrophoneStream();
    if (err != null) {
      return err;
      // return "Moshi requires microphone permissions. Please enable in your system settings.";
    }
    await callMoshi();
    print("startPressed [END]");
  }

  /// Set up the WebRTC session.
  Future<String?> callMoshi() async {
    print("callMoshi [START]");
    if (_pc != null) {
      print("peer connection already exists.");
      return null;
    }
    try {
      // Create peer connection
      print("creating peer connection with config: $pcConfig");
      RTCPeerConnection pc = await setupPeerConnection(pcConfig);
      print("created pc: $pc");
      setState(() {
        _pc = pc;
      });
      // Create data channels
      RTCDataChannelInit dataChannelDict = RTCDataChannelInit()..maxRetransmits = 30;
      RTCDataChannel dc = await pc.createDataChannel('status', dataChannelDict);
      dc.onDataChannelState = (dcs) {
        print("dc: onDataChannelState: $dcs");
        setState(() {
          _dcState = _dcState + '\n\t-> $dcs';
        });
      };
      dc.onMessage = (dcm) {
        if (!dcm.isBinary) {
          print("dc: message: $dcm");
        } else {
          print("dc: got binary msg");
        }
      };
      String? err = await negotiate();
      if (err != null) {
        print("callMoshi: Error: $err");
        return err;
      }
    } catch (error) {
      print("Error: $error");
      return "Failed to connect to Moshi servers. Please try again.";
    }
    setState(() {  // TODO set _isConnected when an ice candidate is good
      _isConnected = true;
    });
    print("callMoshi [END]");
  }

  /// Terminate the WebRTC session.
  Future<String?> stopPressed() async {
    print("stopPressed [START]");
    await hangUpMoshi();
    await stopMicrophoneStream();
    print("stopPressed [END]");
  }

  /// Acquire audio permissions and add audio stream to state `_localStream`.
  Future<String?> startMicrophoneStream() async {
    print("startMicrophoneStream [START]");
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': false
      };
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
      print("_mediaDevicesList.length: ${_mediaDevicesList?.length}");
      for (var md in (_mediaDevicesList ?? [])) {
        print("media device: ${md.label}");
      }
      setState(() {
        _isRecording = true;
        _localStream = stream;
      });
    } catch (error) {
      print("Error: $error");
      return "We couldn't get a hold of your microphone, try enabling it in your system settings.";
    }
    print("startMicrophoneStream [END]");
  }

  /// After setting up stream and signaling, create an SDP offer and handle the answer.
  Future<String?> negotiate() async {
      print("negotiate [START]");
      RTCPeerConnection pc = _pc!;
      // NOTE createOffer collects the available codecs from the audio tracks added to the stream
      RTCSessionDescription offer = await pc.createOffer();
      print("offer:\n\ttype: ${offer.type}\n\tsdp:\n${offer.sdp}");
      await pc.setLocalDescription(offer);
      RTCSessionDescription? _answer = await moshi.sendOfferGetAnswer(offer);
      if (_answer == null) {
        print("negotiate: Error: failed to get sdp answer");
        return "Failed to get SDP from Moshi server.";
      }
      RTCSessionDescription answer = _answer!;
      print("answer:\n\ttype: ${answer.type}\n\tsdp:\n${answer.sdp}");
      await pc.setRemoteDescription(answer);
      print("negotiate [END]");
      return null;
  }

  /// Create the peer connection and set up event handlers.
  Future<RTCPeerConnection> setupPeerConnection(Map<String, dynamic> config) async {
    _pc = await createPeerConnection(config);
    if (_pc == null) {
      throw 'Failed to create peer connection';
    }
    RTCPeerConnection pc = _pc!;
    // Add listeners for ICE state change
    pc?.onIceGatheringState = (gs) async {
      print("pc: onIceGatheringState: $gs");
      setState(() {
        _iceGatheringState = _iceGatheringState + '\n\t-> $gs';
      });
    };
    setState(() {_iceGatheringState = "${pc?.iceGatheringState}";});
    pc?.onIceConnectionState = (cs) async {
      print("pc: onIceConnectionState: $cs");
      setState(() {
        _iceConnectionState = _iceConnectionState + '\n\t-> $cs';
      });
    };
    setState(() {_iceConnectionState = "${pc?.iceConnectionState}";});
    pc?.onSignalingState = (ss) async {
      print("pc: onIceSignalingState: $ss");
      setState(() {
        _signalingState = _signalingState + '\n\t-> $ss';
      });
    };
    setState(() {_signalingState = "${pc?.signalingState}";});
    pc?.onIceCandidate = (candidate) async {
      // print("pc: onIceCandidate: ${candidate.candidate}");
      // TODO try an ice candidate:
      // https://github.com/flutter-webrtc/flutter-webrtc-demo/blob/master/lib/src/call_sample/signaling.dart#L466
      print("pc: onIceCandidate: ${candidate.candidate}");
      print("TODO");
    };
    // Handle what to do when tracks are added
    pc?.onTrack = (evt) {
      print("pc: onTrack: $evt");
      if (evt.track.kind == 'audio') {
        print("audio track added");
        print("\tonTrack: TODO");
        // TODO route received audio track to user device speaker
      }
    };
    // Connect local stream to peer connection
    _localStream!.getTracks().forEach((track) {
      print("pc: getTracks: adding to pc $track");
      pc.addTrack(track, _localStream!);
    });
    return pc;
  }

  /// Destroy the stream object and set the state to not recording.
  Future<void> stopMicrophoneStream() async {
    print("stopMicrophoneStream [START]");
    await _localStream?.dispose();
    setState(() {
      _isRecording = false;
    });
    print("stopMicrophoneStream [END]");
  }

  /// Destroy the webrtc peer connection and set the state to not connected.
  Future<void> hangUpMoshi() async {
    print("hangUpMoshi [START]");
    await tearDownWebRTC();
    setState(() {
      _isConnected = false;
      _iceGatheringState = '';
      _iceConnectionState = '';
      _signalingState = '';
      _dcState = '';
    });
    print("hangUpMoshi [END]");
  }

  /// Destroy the peer connections
  Future<void> tearDownWebRTC() async {
    await _pc?.dispose();
    await _dc?.close();
    if (!mounted) return;
    setState(() {
      _pc = null;
      _dc = null;
    });
  }

  /// Insert a new message into the Chat widget
  void _add_msg(Message msg) {
    print("_add_msg: $msg");
    setState(() {
      _messages.insert(0, msg);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Container(
      child: Stack(  // TODO instead of stack put everything in the column
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(  // START status widgets
                height: 64,
                child: Row(
                  children: [
                    Expanded(  // TODO connection status widget
                      flex: 3,
                      child: Placeholder(),
                    ),
                    Expanded(  // TODO audio recording status widget
                      flex: 2,
                      child: Placeholder(),
                    )
                  ]
                )
              ),  // END status widgets
              Expanded(  // START chat box
                child: Chat(messages: _messages),
              ),  // END chat box
              Container(  // START call controls
                height: 128,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Placeholder(),
                    ),
                    Expanded(
                      flex: 3,
                      child: Placeholder(),
                    )
                  ]
                ),
              ),  // END call controls
            ],
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Servers healthy: $_moshiHealthy"),
                  Text("Microphone acquired: $_isRecording"),
                  Text("Connection established: $_isConnected"),
                  Text("ICE gathering state: $_iceGatheringState"),
                  Text("ICE connection state: $_iceConnectionState"),
                  Text("Signaling state: $_signalingState"),
                  Text("Datachannel state: $_dcState"),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16.0,
            right: 16.0,
            child: FloatingActionButton.extended(  // Start convo
              onPressed: () async {
                final String? err = (_isRecording)
                  ? await stopPressed()
                  : await startPressed();
                if (err != null) {
                  util.showError(context, err);
                }
              },
              label: Text(
                (_isConnected)
                  ? 'Hang up'
                  : 'Call Moshi',
              ),
              icon: Icon(
                (_isConnected)
                  ? Icons.call_end
                  : Icons.add_call,
              ),
              backgroundColor: Colors.purple[800],
            ),
          ),
        ],
      ),
    );
  }
}
