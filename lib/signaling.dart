import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/random_string.dart';
import '../utils/device_info.dart'
    if (dart.library.js) '../utils/device_info_web.dart';

// State of the WebRTC connection
//    source: https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/connectionState
enum ConnectionState {
  New,
  Connecting,
  Connected,
  Disconnected,
  Failed,
  Closed,
}

class Session {
  Session({required this.sid, required this.pid});
  String pid;
  String sid;
  RTCPeerConnection? pc;
  RTCDataChannel? dc;  // NOTE just use the 'status' datachannel to start
  List<RTCIceCandidate> remoteCandidates = [];
}

class Signaling {
  Signaling(this._host, this._port, this._context);

  String const sdpSemantics = 'unified-plan';
  JsonEncoder _encoder = JsonEncoder();
  JsonDecoder _decoder = JsonDecoder();
  String _selfId = randomNumeric(6);
  BuildContext? _context;
  var _host;
  var _port;
  Session? _session;
  MediaStream? _localStream;
  List<MediaStream> _remoteStreams = <MediaStream>[];
  List<RTCRtpSender> _senders = <RTCRtpSender>[];

  Function(Session session, CallState state)? onConnectionStateChange;
  Function(MediaStream stream)? onLocalStream;
  Function(Session session, MediaStream stream)? onAddRemoteStream;
  Function(Session session, MediaStream stream)? onRemoveRemoteStream;
  Function(Session session, RTCDataChannel dc, RTCDataChannelMessage data)? onDataChannelMessage;
  Function(Session session, RTCDataChannel dc)? onDataChannel;

  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  final Map<String, dynamic> _dcConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  Future<void> connect() async {
    print('connect');
    var url = 'https://$_host:$_port/offer';
    print('\tconnecting to $url');
    // TODO create PC
    // TODO create datachannel "pingpong" (POC datachannel) from PC
    // TODO constraints <- mediaConstraints
    // TODO stream <- getUserMedia
    // TODO tracks <- for each track in stream.tracks if track is audio
    // TODO negotiate
    // TODO POST to /offer
  }

  close() async {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((element) async {
        await element.stop();
      });
      await _localStream!.dispose();
      _localStream = null;
    }
    await _session.pc?.close();
    await _session.dc?.close();
    _session = null;
    _senders.clear();
  }

  void onMessage(message) async {
    print("message: $message");
    Map<String, dynamic> mapData = message;
    var data = mapData['data'];

    print("mapData: $mapData");
    switch (mapData['type']) {
      case 'offer':
        {
          var peerId = data['from'];
          var description = data['description'];
          var media = data['media'];
          var sessionId = data['session_id'];
          var session = _sessions[sessionId];
          var newSession = await _createSession(session,
              peerId: peerId,
              sessionId: sessionId,
              media: media);
          _sessions[sessionId] = newSession;
          await newSession.pc?.setRemoteDescription(
              RTCSessionDescription(description['sdp'], description['type']));
          await _createAnswer(newSession, media);

          if (newSession.remoteCandidates.length > 0) {
            newSession.remoteCandidates.forEach((candidate) async {
              await newSession.pc?.addCandidate(candidate);
            });
            newSession.remoteCandidates.clear();
          }
          onCallStateChange?.call(newSession, CallState.New);
          onCallStateChange?.call(newSession, CallState.Connecting);
        }
        break;
      case 'answer':
        {
          var description = data['description'];
          var sessionId = data['session_id'];
          var session = _sessions[sessionId];
          session?.pc?.setRemoteDescription(
              RTCSessionDescription(description['sdp'], description['type']));
          onCallStateChange?.call(session!, CallState.Connected);
        }
        break;
      case 'candidate':
        {
          var peerId = data['from'];
          var candidateMap = data['candidate'];
          var sessionId = data['session_id'];
          var session = _sessions[sessionId];
          RTCIceCandidate candidate = RTCIceCandidate(candidateMap['candidate'],
              candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);

          if (session != null) {
            if (session.pc != null) {
              await session.pc?.addCandidate(candidate);
            } else {
              session.remoteCandidates.add(candidate);
            }
          } else {
            _sessions[sessionId] = Session(pid: peerId, sid: sessionId)
              ..remoteCandidates.add(candidate);
          }
        }
        break;
      case 'leave':
        {
          var peerId = data as String;
          _closeSessionByPeerId(peerId);
        }
        break;
      case 'bye':
        {
          var sessionId = data['session_id'];
          print('bye: ' + sessionId);
          var session = _sessions.remove(sessionId);
          if (session != null) {
            onCallStateChange?.call(session, CallState.Bye);
            _closeSession(session);
          }
        }
        break;
      case 'keepalive':
        {
          print('keepalive response!');
        }
        break;
      default:
        break;
    }
  }

  Future<MediaStream> createStream(String media, {BuildContext? context}) async {
    print("createStream");
    final Map<String, bool> mediaConstraints = {
      'audio': true,
      'video': false,
    };
    late MediaStream stream;
    stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    onLocalStream?.call(stream);
    return stream;
  }

  Future<Session> _createSession(
    Session? session, {
    required String media,
  }) async {
    var newSession = session ?? Session(sid: sessionId, pid: peerId);
    if (media != 'data')
      _localStream =
          await createStream(media, context: _context);
    print(_iceServers);
    RTCPeerConnection pc = await createPeerConnection({
      ..._iceServers,
      ...{'sdpSemantics': 'unified-plan'}
    }, _config);
    if (media != 'data') {
        pc.onTrack = (event) {
          if (event.track.kind == 'audio') {
            onAddRemoteStream?.call(newSession, event.streams[0]);
          }
        };
        _localStream!.getTracks().forEach((track) async {
          _senders.add(await pc.addTrack(track, _localStream!));
        });
        break;
      }
    }
    pc.onIceCandidate = (candidate) async {
      if (candidate == null) {
        print('onIceCandidate: complete!');
        return;
      }
      // This delay is needed to allow enough time to try an ICE candidate
      // before skipping to the next one. 1 second is just an heuristic value
      // and should be thoroughly tested in your own environment.
      await Future.delayed(
          const Duration(seconds: 1),
          () => _send('candidate', {
                'to': peerId,
                'from': _selfId,
                'candidate': {
                  'sdpMLineIndex': candidate.sdpMLineIndex,
                  'sdpMid': candidate.sdpMid,
                  'candidate': candidate.candidate,
                },
                'session_id': sessionId,
              }));
    };

    pc.onIceConnectionState = (state) {};

    pc.onRemoveStream = (stream) {
      onRemoveRemoteStream?.call(newSession, stream);
      _remoteStreams.removeWhere((it) {
        return (it.id == stream.id);
      });
    };

    pc.onDataChannel = (channel) {
      _addDataChannel(newSession, channel);
    };

    newSession.pc = pc;
    return newSession;
  }

  void _addDataChannel(Session session, RTCDataChannel channel) {
    channel.onDataChannelState = (e) {};
    channel.onMessage = (RTCDataChannelMessage data) {
      onDataChannelMessage?.call(session, channel, data);
    };
    session.dc = channel;
    onDataChannel?.call(session, channel);
  }

  Future<void> _createDataChannel(Session session,
      {label: 'fileTransfer'}) async {
    RTCDataChannelInit dataChannelDict = RTCDataChannelInit()
      ..maxRetransmits = 30;
    RTCDataChannel channel =
        await session.pc!.createDataChannel(label, dataChannelDict);
    _addDataChannel(session, channel);
  }

  Future<void> _createOffer(Session session, String media) async {
    try {
      RTCSessionDescription s =
          await session.pc!.createOffer(media == 'data' ? _dcConstraints : {});
      await session.pc!.setLocalDescription(_fixSdp(s));
      _send('offer', {
        'to': session.pid,
        'from': _selfId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'session_id': session.sid,
        'media': media,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _createAnswer(Session session, String media) async {
    try {
      RTCSessionDescription s =
          await session.pc!.createAnswer(media == 'data' ? _dcConstraints : {});
      await session.pc!.setLocalDescription(_fixSdp(s));
      _send('answer', {
        'to': session.pid,
        'from': _selfId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'session_id': session.sid,
      });
    } catch (e) {
      print(e.toString());
    }
  }

}
