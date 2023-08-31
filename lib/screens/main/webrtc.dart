// TODO change state variables using listeners instead of setState
// TODO refactor the calling into services/webrtc.dart
// TODO add session management into services/webrtc.dart
//  - create a session object that holds the peer connection, data channel, and local stream
//  - create a session manager that holds the session and handles the signaling
//  - keep connection alive by sending pings every 10 seconds
//  - keep connection alive between calls instead of tearing down and re-establishing
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:moshi/types.dart';
import 'package:moshi/services/moshi.dart' as moshi;
import 'package:moshi/util.dart' as util;
import 'package:moshi/widgets/chat.dart';
import 'package:moshi/widgets/status.dart';

const iceServers = [
  {
    'urls': ['stun:stun.l.google.com:19302']
  }
];
const pcConfig = {
  'sdpSemantics': 'unified-plan',
  'iceServers': iceServers,
};
const pcConstraints = {'audio': true, 'video': false};

class WebRTCScreen extends StatefulWidget {
  final Profile profile;
  WebRTCScreen({required this.profile});
  @override
  _WebRTCScreenState createState() => _WebRTCScreenState();
}

class _WebRTCScreenState extends State<WebRTCScreen> {
  MediaStream? _localStream;
  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  MicStatus micStatus = MicStatus.off;
  ServerStatus serverStatus = ServerStatus.unknown;
  CallStatus callStatus = CallStatus.idle;
  bool _justStarted = true;
  String? _transcriptId;
  late List<Message> _messages;

  /// Initialize the messages list with some example messages.
  List<Message> _initMessages() {
    return [
      Message(Role.ast, "Exactly."),
      Message(Role.usr, "Like a walkie-talkie?"),
      Message(Role.ast, "Hold the chat button that appears to talk."),
      Message(Role.usr, "Then what?"),
      Message(Role.ast, "It's the round one below on the left."),
      Message(Role.usr, "Where is that?"),
      Message(Role.ast, "Click the call button to start a call."),
      Message(Role.usr, "Cool - how?"),
      Message(Role.ast, "I'm here to help you speak a second language!"),
      Message(Role.usr, "Hey Moshi, what's up?"),
      Message(Role.ast, "Moshi moshi, ${widget.profile.name}"),
    ];
  }

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
      _justStarted = false;
      callStatus = CallStatus.ringing;
      serverStatus = ServerStatus.pending;
    });
    // Backend server check
    bool healthy = await moshi.healthCheck();
    setState(() {
      serverStatus = (healthy) ? ServerStatus.ready : ServerStatus.error;
      callStatus = (healthy) ? callStatus : CallStatus.idle;
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
      print("creating peer connection");
      print("with config: $pcConfig");
      print("with constraints: $pcConstraints");
      RTCPeerConnection pc = await setupPeerConnection(pcConfig, pcConstraints);
      pc.onConnectionState = (pcs) {
        print("pc: onConnectionState: $pcs");
        if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          print("pc: connected");
        } else if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          print("pc: disconnected");
          setState(() {
            callStatus = CallStatus.idle;
          });
        } else if (pcs == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          print("pc: failed");
          setState(() {
            callStatus = CallStatus.error;
          });
        } else {
          print("TODO pc: connection state change unhandled: $pcs");
        }
      };
      print("created pc: $pc");
      // Create data channel
      RTCDataChannelInit dataChannelDict = RTCDataChannelInit()..maxRetransmits = 30;
      RTCDataChannel dc = await pc.createDataChannel('data', dataChannelDict);
      dc.onDataChannelState = (dcs) {
        if (dcs == RTCDataChannelState.RTCDataChannelOpen) {
          print("dc: data channel open");
        } else if (dcs == RTCDataChannelState.RTCDataChannelClosed) {
          print("dc: data channel closed");
          setState(() {
            callStatus = CallStatus.idle;
          });
        } else {
          print("Unhanlded data channel state: $dcs");
        }
      };
      dc.onMessage = (dcm) {
        if (!dcm.isBinary) {
          _handleStringMessage(dcm.text);
        } else {
          print("TODO handle binary data channel messages");
        }
      };
      print("created dc: $dc");
      setState(() {
        _pc = pc;
        _dc = dc;
      });
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

  Future<void> _sendFeedback(String body) async {
    print("Sending feedback: $body");
    DocumentReference feedbackRef = FirebaseFirestore.instance.collection('feedback').doc();
    FeedbackMsg fbk = FeedbackMsg(
      uid: widget.profile.uid,
      body: body,
      type: "call",
      tid: _transcriptId ?? "",
    );
    await feedbackRef.set(fbk.toMap());
  }

  void _afterFeedbackMessage() {
    // Thank the user via snackbox, then nav.pop if mounted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🙇 Thank you very much for helping us improve."),
        duration: Duration(seconds: 2),
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Pop up a dialog to ask for feedback.
  Future<void> feedbackAfterCall() async {
    print("feedbackPressed [START]");
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Feedback",
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
              fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          content: Text(
            "How was your call?",
          ),
          actions: [
            TextButton(
              child: Text(
                "👍",
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
                  fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              onPressed: () async {
                await _sendFeedback("good");
                _afterFeedbackMessage();
              },
            ),
            TextButton(
              child: Text(
                "👎",
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
                  fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              onPressed: () async {
                await _sendFeedback("bad");
                _afterFeedbackMessage();
              },
            ),
          ],
        );
      },
    );
    print("feedbackPressed [END]");
  }

  /// Terminate the WebRTC session.
  Future<String?> stopPressed() async {
    print("stopPressed [START]");
    await _dc?.send(RTCDataChannelMessage("status bye"));
    await hangUpMoshi();
    await stopMicrophoneStream();
    await feedbackAfterCall();
    print("stopPressed [END]");
    return null;
  }

  /// Acquire audio permissions and add audio stream to state `_localStream`.
  Future<String?> startMicrophoneStream() async {
    print("startMicrophoneStream [START]");
    try {
      final mediaConstraints = <String, dynamic>{'audio': true, 'video': false};
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      setState(() {
        micStatus = MicStatus.muted;
        _localStream = stream;
      });
      MediaStreamTrack audio = _localStream!.getAudioTracks()[0];
      audio.onMute = () => micStatus = MicStatus.muted;
      audio.onUnMute = () => micStatus = MicStatus.on;
    } catch (error) {
      print("Error: $error");
      return "I couldn't get access to your microphone, try enabling it in your phone's settings.";
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
    print("negotiate: created offer");
    print("offer:\n\ttype: ${offer.type}\n\tsdp:\n${offer.sdp}");
    await pc.setLocalDescription(offer);
    final RTCSessionDescription? answer;
    try {
      answer = await moshi.sendOfferGetAnswer(offer);
    } on moshi.AuthError {
      return "🥸 Please log in.";
    } on moshi.RateLimitError catch (e) {
      return "🙅 ${e.message}";
    } catch (e) {
      print("negotiate: error: $e");
      return "😭 Moshi servers are having trouble.\nWe're working on it! 🏗";
    }
    print("answer:\n\ttype: ${answer.type}\n\tsdp:\n${answer.sdp}");
    await pc.setRemoteDescription(answer);
    print("negotiate [END]");
    return null;
  }

  /// Create the peer connection and set up event handlers.
  Future<RTCPeerConnection> setupPeerConnection(Map<String, dynamic> config, Map<String, dynamic> constraints) async {
    _pc = await createPeerConnection(config, constraints);
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
      if (micStatus == MicStatus.on) {
        micStatus = MicStatus.muted;
      }
    });
    print("stopMicrophoneStream [END]");
  }

  /// Destroy the webrtc peer connection and set the state to not connected.
  Future<void> hangUpMoshi() async {
    print("hangUpMoshi [START]");
    await tearDownWebRTC();
    setState(() {
      callStatus = CallStatus.idle;
    });
    print("hangUpMoshi [END]");
  }

  /// Destroy the peer connections
  Future<void> tearDownWebRTC() async {
    print("tearDownWebRTC [START]");
    await _pc?.dispose();
    await _dc?.close();
    if (!mounted) {
      print("tearDownWebRTC [END]");
      return;
    }
    setState(() {
      _pc = null;
      _dc = null;
    });
    print("tearDownWebRTC [END]");
  }

  /// Insert a new message into the Chat widget
  void _addMsg(Message msg) {
    setState(() {
      _messages.insert(0, msg);
    });
  }

  /// Route the data channel message to the appropriate handler
  void _handleStringMessage(String dcm) {
    final List<String> words = dcm.split(" ");
    final String msgtp = words[0];
    final String? body = (words.length > 1) ? words.sublist(1).join(' ') : null;
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
      case "info":
        String varName = words[1];
        String varValue = words[2];
        _handleInfo(varName, varValue);
        break;
      default:
        print("unhandled message type: $msgtp");
    }
  }

  void _handleError(String? errtype) async {
    print("_handleError");
    switch (errtype) {
      case "usrNotSpeaking":
        util.showError(context,
            "😪 Moshi hung up after waiting for you to speak.\nPlease feel free to start another conversation.");
        break;
      default:
        print("unhandled error type: $errtype");
        util.showError(context, "🙇 Moshi servers are having trouble.\nWe're working on it! 🏗");
        break;
    }
    await stopPressed();
  }

  /// Update the call state to inCall
  void _handleHello() {
    setState(() {
      callStatus = CallStatus.inCall;
    });
  }

  /// Parse the status and modify screen state accordingly.
  void _handleStatus(String body) {
    final String statusType = body.split(" ")[0];
    switch (statusType) {
      case "hello":
        _handleHello();
        break;
      default:
        print("unhandled status type: $statusType");
    }
  }

  void _handleInfo(String varName, String varValue) {
    switch (varName) {
      case "tid":
        print("Got transcript id: $varValue");
        setState(() {
          _transcriptId = varValue;
        });
        break;
      default:
        print("unhandled info type: $varName");
    }
  }

  /// Parse the Message from a datachannel (non-binary) serialization and add it to the screen
  void _handleTranscript(String body) {
    final Role role = (body.split(" ")[0] == "ast") ? Role.ast : Role.usr;
    final String content = body.split(" ").sublist(1).join(' ');
    _addMsg(Message(role, content));
  }

  /// While hold-to-chat pressed, enable the mic and send audio to the server.
  void _enableMic() {
    for (var audioTrack in _localStream!.getAudioTracks()) {
      audioTrack.enabled = true;
      // print("audioTrack.enabled = true; $audioTrack");
    }
    setState(() {
      micStatus = MicStatus.on;
    });
  }

  /// Whenever the user's finger leaves the button, mute the track and update the status.
  void _disableMic() {
    for (var audioTrack in _localStream!.getAudioTracks()) {
      audioTrack.enabled = false;
      // print("audioTrack.enabled = false; $audioTrack");
    }
    setState(() {
      micStatus = MicStatus.muted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_justStarted) {
      _messages = _initMessages();
    }
    final Row topStatusBar = _topStatusBar(context);
    final Chat middleChatBox = Chat(messages: _messages);
    final Row bottomButtons = _bottomButtons(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 64,
          child: topStatusBar,
        ),
        Expanded(
          child: middleChatBox,
        ),
        SizedBox(height: 128, child: bottomButtons),
        SizedBox(height: 16),
      ],
    );
  }

  /// The bottom row of buttons.
  Row _bottomButtons(BuildContext context) {
    final GestureDetector holdToChatButton = _holdToChatButton(context);
    return Row(children: [
      Flexible(
          flex: 2,
          child: Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.65,
                heightFactor: 0.65,
                child: FloatingActionButton(
                  // New call
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
                      case CallStatus.error:
                        err = await startPressed();
                        break;
                      case CallStatus.ringing:
                        err = null;
                        break;
                    }
                    if (err != null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err)),
                        );
                      }
                    }
                  },
                  backgroundColor: {
                    CallStatus.idle: Theme.of(context).colorScheme.tertiary,
                    CallStatus.ringing: Theme.of(context).colorScheme.onSurface,
                    CallStatus.inCall: Theme.of(context).colorScheme.primary,
                    CallStatus.error: Theme.of(context).colorScheme.tertiary,
                  }[callStatus],
                  child: Icon(
                      {
                        CallStatus.idle: Icons.call,
                        CallStatus.ringing: Icons.call_made,
                        CallStatus.inCall: Icons.call_end,
                        CallStatus.error: Icons.wifi_calling_3,
                      }[callStatus],
                      size: Theme.of(context).textTheme.headlineLarge?.fontSize,
                      color: {
                        CallStatus.idle: Theme.of(context).colorScheme.onTertiary,
                        CallStatus.ringing: Theme.of(context).colorScheme.surface,
                        CallStatus.inCall: Theme.of(context).colorScheme.onTertiary,
                        CallStatus.error: Theme.of(context).colorScheme.onTertiary,
                      }[callStatus]),
                ),
              ))),
      Flexible(
        flex: 3,
        child: Align(
          alignment: Alignment.center,
          child: (callStatus == CallStatus.inCall)
              ? FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.65,
                  child: holdToChatButton,
                )
              : SizedBox(),
        ),
      ),
    ]);
  }

  Row _topStatusBar(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: 2,
        // while call is ringing, show a spinner aligned topleft, otherwise nothing
        child: (callStatus == CallStatus.ringing || serverStatus == ServerStatus.pending)
            ? Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
    ]);
  }

  GestureDetector _holdToChatButton(BuildContext context) {
    return GestureDetector(
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
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        label: Text("Hold to\nspeak",
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
              fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
              color: Theme.of(context).colorScheme.onSurface,
            )),
        icon: Icon(
          Icons.mic,
          size: Theme.of(context).textTheme.headlineLarge?.fontSize,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
