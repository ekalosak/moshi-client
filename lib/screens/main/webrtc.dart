import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:moshi_client/types.dart';
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
  MicStatus micStatus = MicStatus.off;
  ServerStatus serverStatus = ServerStatus.unknown;
  CallStatus callStatus = CallStatus.idle;
  final List<Message> _messages = [
    Message(Role.ast, "It's the big round one just below on the left."),
    Message(Role.usr, "Where is that?"),
    Message(Role.ast, "Click the call button and start a conversation."),
    Message(Role.usr, "Cool - how?"),
    Message(Role.ast, "I'm here to help you learn a second language!"),
    Message(Role.usr, "Hey Moshi, what's up?"),
    Message(Role.ast, "Moshi moshi."),
  ];

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
      micStatus = (err == null) ? MicStatus.muted : MicStatus.noPermission;
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
      setState(() {
        callStatus = CallStatus.idle;
        serverStatus = ServerStatus.error;
      });
      return err;
    }
    print("startPressed [END]");
    return null;
  }

  /// Set up the WebRTC session.
  Future<String?> callMoshi() async {
    String? err;
    print("callMoshi [START]");
    if (_pc != null || _dc != null) {
      print("peer connection already exists, ending previous call.");
      await tearDownWebRTC();
    }
    try {
      // Create peer connection
      print("creating peer connection with config: $pcConfig");
      RTCPeerConnection pc = await setupPeerConnection(pcConfig);
      pc.onConnectionState = (pcs) {
        print("pc: onConnectionState: $pcs");
        if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          print("pc: connected");
        } else if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          // TODO set an error message to be displayed in the snackbox on build
          print("pc: disconnected");
          setState(() {
            callStatus = CallStatus.idle;
          });
        } else if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          print("pc: failed");
          setState(() {
            callStatus = CallStatus.idle;
          });
        } else {
          print("TODO pc: connection state change unhandled: $pcs");
        }
      };
      print("created pc: $pc");
      setState(() {
        _pc = pc;
      });
      // Create data channel
      RTCDataChannelInit dataChannelDict = RTCDataChannelInit()..maxRetransmits = 30;
      RTCDataChannel dc = await pc.createDataChannel('data', dataChannelDict);
      dc.onDataChannelState = (dcs) {
        if (dcs == RTCDataChannelState.RTCDataChannelOpen) {
          print("dc: data channel open");
        } else if (dcs == RTCDataChannelState.RTCDataChannelClosed) {
          print("dc: data channel closed");
          setState(() {
            callStatus = CallStatus.idle; // TODO also handle channel closed for the peer connection
          });
        } else {
          print("TODO dc: data channel state change unhandled: $dcs");
        }
      };
      dc.onMessage = (dcm) {
        if (!dcm.isBinary) {
          _handleStringMessage(dcm.text);
        } else {
          print("dc: got binary msg");
        }
      };
      err = await negotiate();
      if (err != null) {
        await hangUpMoshi();
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
    await _dc?.send(RTCDataChannelMessage("status bye"));
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
        micStatus = MicStatus.muted;
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
    RTCSessionDescription? answer = await moshi.sendOfferGetAnswer(offer);
    if (answer == null) {
      return "Failed to get SDP from Moshi server.";
    }
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
    // Add listeners for ICE state change.
    // NOTE webrtc implementation handles resolving ice candidates.
    pc.onIceGatheringState = (gs) async {
      print("pc: onIceGatheringState: $gs");
    };
    pc.onIceConnectionState = (cs) async {
      print("pc: onIceConnectionState: $cs");
    };
    pc.onSignalingState = (ss) async {
      print("pc: onIceSignalingState: $ss");
    };
    pc.onIceCandidate = (candidate) async {
      print("pc: onIceCandidate: ${candidate.candidate}");
    };
    // Handle what to do when tracks are added
    pc.onTrack = (evt) {
      if (evt.track.kind == 'audio') {
        print("pc: audio track added");
      } else {
        print("pc: unexpected track added: ${evt.track.kind}");
      }
    };
    // Connect local stream to peer connection
    _localStream!.getTracks().forEach((track) {
      print("pc: adding track $track");
      track.enabled = false; // start muted
      pc.addTrack(track, _localStream!);
    });
    return pc;
  }

  /// Destroy the stream object and set the state to not recording.
  Future<void> stopMicrophoneStream() async {
    print("stopMicrophoneStream [START]");
    for (var audioTrack in _localStream!.getAudioTracks()) {
      await audioTrack.stop();
    }
    await _localStream?.dispose();
    setState(() {
      // TODO these state changes should be set by callbacks from the webrtc implementation.
      if (micStatus == MicStatus.muted || micStatus == MicStatus.on) {
        micStatus = MicStatus.off;
      }
    });
    print("stopMicrophoneStream [END]");
  }

  /// Destroy the webrtc peer connection and set the state to not connected.
  Future<void> hangUpMoshi() async {
    print("hangUpMoshi [START]");
    await tearDownWebRTC();
    setState(() {
      serverStatus = ServerStatus.unknown;
      callStatus = CallStatus.idle;
    });
    print("hangUpMoshi [END]");
  }

  /// Destroy the peer connections
  Future<void> tearDownWebRTC() async {
    print("tearDownWebRTC [START]");
    await _pc?.dispose();
    await _dc?.close();
    if (!mounted) return;
    setState(() {
      _pc = null;
      _dc = null;
    });
    print("tearDownWebRTC [END]");
  }

  /// Insert a new message into the Chat widget
  void _addMsg(Message msg) {
    print("_addMsg");
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
      case "error":
        _handleError(body);
        break;
      default:
        print("TODO unhandled message type: $msgtp");
    }
  }

  void _handleError(String? errtype) async {
    print("_handleError");
    switch (errtype) {
      case "usrNotSpeaking":
        util.showError(
            context, "Moshi hung up after waiting for you to speak. Please feel free to start another conversation.");
        break;
      default:
        print("TODO unhandled error type: $errtype");
    }
    await stopPressed();
  }

  /// Update the call state to inCall
  void _handleHello() {
    print("_handleHello");
    setState(() {
      callStatus = CallStatus.inCall;
    });
  }

  /// Parse the status and modify screen state accordingly.
  void _handleStatus(String body) {
    final String statusType = body.split(" ")[0];
    print("statusType: $statusType");
    switch (statusType) {
      case "hello":
        _handleHello();
        break;
      default:
        print("TODO unhandled status type: $statusType");
    }
  }

  /// Parse the Message from a datachannel (non-binary) serialization and add it to the screen
  void _handleTranscript(String body) {
    final Role role = (body.split(" ")[0] == "ast") ? Role.ast : Role.usr;
    print('\trole: $role');
    final String content = body.split(" ").sublist(1).join(' ');
    print('\tcontent: $content');
    _addMsg(Message(role, content));
  }

  /// While hold-to-chat pressed, enable the mic and send audio to the server.
  void _enableMic() {
    for (var audioTrack in _localStream!.getAudioTracks()) {
      print("_enableMic: enabling audioTrack: $audioTrack");
      audioTrack.enabled = true;
    }
    setState(() {
      micStatus = MicStatus.on;
    });
    print("Enabled audio track(s)");
  }

  /// Whenever the user's finger leaves the button, mute the track and update the status.
  void _disableMic() {
    for (var audioTrack in _localStream!.getAudioTracks()) {
      print("_disableMic: disabling audioTrack: $audioTrack");
      audioTrack.enabled = false;
    }
    setState(() {
      micStatus = MicStatus.muted;
    });
    print("Disabled audio track(s)");
  }

  @override
  Widget build(BuildContext context) {
    final FractionallySizedBox holdToChatButton = FractionallySizedBox(
        widthFactor: 0.65,
        heightFactor: 0.65,
        child: GestureDetector(
          onTapDown: (_) {
            _enableMic();
          },
          onTapUp: (_) {
            _disableMic();
          },
          onTapCancel: () {
            _disableMic();
          },
          child: FloatingActionButton.extended(
            onPressed: () async {},
            backgroundColor: Theme.of(context).colorScheme.primary,
            label: Text("Hold to speak"),
            icon: Icon(Icons.mic),
          ),
        ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
            height: 64,
            child: Row(children: [
              Expanded(
                flex: 2,
                // while call is ringing, show a spinner aligned topleft, otherwise nothing
                child: (callStatus == CallStatus.ringing)
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : SizedBox(),
              ),
              Expanded(
                flex: 3,
                child: ConnectionStatus(
                  micStatus: micStatus,
                  serverStatus: serverStatus,
                  callStatus: callStatus,
                  colorScheme: Theme.of(context).colorScheme,
                ),
              ),
            ])),
        Expanded(
          child: Chat(messages: _messages),
        ),
        SizedBox(
          height: 128,
          child: Row(children: [
            Flexible(
                flex: 2,
                child: Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.65,
                      heightFactor: 0.65,
                      child: FloatingActionButton(
                        autofocus: true,
                        onPressed: () async {
                          final String? err;
                          switch (callStatus) {
                            case CallStatus.inCall:
                              err = await stopPressed();
                              break;
                            case CallStatus.idle:
                              err = await startPressed();
                              break;
                            default:
                              err = null;
                              break;
                          }
                          if (err != null) {
                            print("ERROR: $err");
                            util.showError(context, "I'm sorry, Moshi didn't pick up the phone. Please call again.");
                          }
                        },
                        backgroundColor: {
                          CallStatus.idle: Theme.of(context).colorScheme.primary,
                          CallStatus.ringing: Colors.grey,
                          CallStatus.inCall: Theme.of(context).colorScheme.secondary,
                        }[callStatus],
                        child: Icon(
                          {
                            CallStatus.idle: Icons.wifi_calling_3,
                            CallStatus.ringing: Icons.call_made,
                            CallStatus.inCall: Icons.call_end,
                          }[callStatus],
                        ),
                      ),
                    ))),
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.center,
                child: (callStatus == CallStatus.inCall) ? holdToChatButton : SizedBox(),
              ), // NOTE DEBUG just to get placement right
            ),
          ]),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
