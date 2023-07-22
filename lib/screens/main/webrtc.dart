import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import 'package:moshi_client/types.dart';
import 'package:moshi_client/services/auth.dart';
import 'package:moshi_client/services/moshi.dart' as moshi;
import 'package:moshi_client/util.dart' as util;
import 'package:moshi_client/widgets/chat.dart';
import 'package:moshi_client/widgets/status.dart';

const iceServers = [
  {
    'urls': ['stun:stun.l.google.com:19302']
  }
];
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
  MicStatus micStatus = MicStatus.unknown;
  ServerStatus serverStatus = ServerStatus.unknown;
  CallStatus callStatus = CallStatus.idle;
  final List<Message> _messages = [
    Message(Role.ast, "Not much my excellent bro, you?"),
    Message(Role.usr, "Hey Moshi, what's up?"),
    Message(Role.ast, "Moshi moshi."),
  ];
  String _iceGatheringState = '';
  String _iceConnectionState = '';
  String _signalingState = '';
  String _dcState = '';

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
    String? err;
    print("startPressed [START]");
    setState(() {
      _messages.clear();
    });
    // Backend server check
    bool healthy = await moshi.healthCheck();
    setState(() {
      serverStatus = (healthy) ? ServerStatus.ready : ServerStatus.error;
    });
    if (!healthy) {
      return "Moshi servers unhealthy, please try again.";
    }
    // Microphone check
    err = await startMicrophoneStream();
    setState(() {
      micStatus = (err == null) ? MicStatus.off : MicStatus.noPermission;
    });
    if (err != null) {
      return err;
      // return "Moshi requires microphone permissions. Please enable in your system settings.";
    }
    setState(() {
      callStatus = CallStatus.ringing;
    });
    err = await callMoshi();
    if (err != null) {
      return err;
    }
    setState(() {
      micStatus = MicStatus.on;
      callStatus = CallStatus.inCall;
    });
    print("startPressed [END]");
    return null;
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
      RTCDataChannel dc = await pc.createDataChannel('data', dataChannelDict);
      dc.onDataChannelState = (dcs) {
        print("dc: onDataChannelState: $dcs");
        setState(() {
          _dcState = _dcState + '\n\t-> $dcs';
        });
      };
      dc.onMessage = (dcm) {
        if (!dcm.isBinary) {
          _handleStringMessage(dcm.text);
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
    print("callMoshi [END]");
    return null;
  }

  /// Terminate the WebRTC session.
  Future<String?> stopPressed() async {
    print("stopPressed [START]");
    // TODO return erros returned by hangUpMoshi or by stopMicrophoneStream
    await hangUpMoshi();
    await stopMicrophoneStream();
    print("stopPressed [END]");
    return null;
  }

  /// Acquire audio permissions and add audio stream to state `_localStream`.
  Future<String?> startMicrophoneStream() async {
    print("startMicrophoneStream [START]");
    try {
      final mediaConstraints = <String, dynamic>{'audio': true, 'video': false};
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
      print("_mediaDevicesList.length: ${_mediaDevicesList?.length}");
      for (var md in (_mediaDevicesList ?? [])) {
        print("media device: ${md.label}");
      }
      setState(() {
        micStatus = MicStatus.on;
        _localStream = stream;
      });
    } catch (error) {
      print("Error: $error");
      return "We couldn't get a hold of your microphone, try enabling it in your system settings.";
    }
    print("startMicrophoneStream [END]");
    return null;
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
    setState(() {
      _iceGatheringState = "${pc?.iceGatheringState}";
    });
    pc?.onIceConnectionState = (cs) async {
      print("pc: onIceConnectionState: $cs");
      setState(() {
        _iceConnectionState = _iceConnectionState + '\n\t-> $cs';
      });
    };
    setState(() {
      _iceConnectionState = "${pc?.iceConnectionState}";
    });
    pc?.onSignalingState = (ss) async {
      print("pc: onIceSignalingState: $ss");
      setState(() {
        _signalingState = _signalingState + '\n\t-> $ss';
      });
    };
    setState(() {
      _signalingState = "${pc?.signalingState}";
    });
    // pc?.onIceCandidate = (candidate) async {
    //   print("pc: onIceCandidate: ${candidate.candidate}");  // NOTE webrtc implementation handles resolving ice candidates
    // };
    // Handle what to do when tracks are added
    pc?.onTrack = (evt) {
      print("pc: onTrack: $evt");
      if (evt.track.kind == 'audio') {
        print("audio track added");
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
      micStatus = MicStatus.off;
    });
    print("stopMicrophoneStream [END]");
  }

  /// Destroy the webrtc peer connection and set the state to not connected.
  Future<void> hangUpMoshi() async {
    print("hangUpMoshi [START]");
    await tearDownWebRTC();
    setState(() {
      _iceGatheringState = '';
      _iceConnectionState = '';
      _signalingState = '';
      _dcState = '';
      if (micStatus == MicStatus.muted || micStatus == MicStatus.on) {
        micStatus = MicStatus.off;
      }
      serverStatus = ServerStatus.unknown;
      callStatus = CallStatus.idle;
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

  /// Route the data channel message to the appropriate handler
  void _handleStringMessage(String dcm) {
    final List<String> words = dcm.split(" ");
    final String msgtp = words[0];
    final String? body = (words.length > 1) ? words.sublist(1).join(' ') : null;
    print("msgtp: $msgtp");
    switch (msgtp) {
      case "transcript":
        _handleTranscript(body!);
        break;
      case "status":
        _handleStatus(body!);
        break;
      case "ping":
        print("TODO send pong");
        break;
    }
  }

  /// Parse the status and modify screen state accordingly.
  void _handleStatus(String body) {
    final String statusType = body.split(" ")[0];
    print("statusType: $statusType");
    switch (statusType) {
      case "hello":
        break;
      default:
        print("TODO unhandled status type: $statusType");
    }
  }

  /// Parse the Message from a datachannel (non-binary) serialization and add it to the screen
  void _handleTranscript(String body) {
    final Role role = (body.split(" ")[0] == "ast") ? Role.ast : Role.usr;
    print('role: $role');
    final String content = body.split(" ").sublist(1).join(' ');
    print('content: $content');
    _add_msg(Message(role, content));
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Container(
      child: Stack(
        // TODO instead of stack put everything in the column
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, 96, 0, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ICE gathering state: $_iceGatheringState"),
                  Text("ICE connection state: $_iceConnectionState"),
                  Text("Signaling state: $_signalingState"),
                  Text("Datachannel state: $_dcState"),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                  // START status widgets
                  height: 64,
                  child: Row(children: [
                    Expanded(
                      flex: 3,
                      child: ConnectionStatus(
                        micStatus: micStatus,
                        serverStatus: serverStatus,
                        callStatus: callStatus,
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Placeholder(),
                    )
                  ])),
              Expanded(
                // START chat box
                child: Chat(messages: _messages),
              ), // END chat box
              Container(
                // START controls
                height: 128,
                child: Row(children: [
                  Expanded(
                      // START call button
                      flex: 2,
                      child: FractionallySizedBox(
                        widthFactor: 0.65,
                        heightFactor: 0.65,
                        child: FloatingActionButton(
                          // Call button
                          onPressed: () async {
                            final String? err =
                                (callStatus == CallStatus.idle) ? await startPressed() : await stopPressed();
                            if (err != null) {
                              util.showError(context, err);
                            }
                          },
                          backgroundColor: (callStatus == CallStatus.idle)
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          child: Icon(
                            (callStatus == CallStatus.idle) ? Icons.add_call : Icons.call_end,
                          ),
                        ),
                      )), // END call button
                  Expanded(
                    // START hold to talk button
                    flex: 3,
                    child: Placeholder(),
                  ) // END hold to talk button
                ]),
              ), // END controls
            ],
          ),
        ],
      ),
    );
  }
}
