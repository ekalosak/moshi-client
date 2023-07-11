import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_call.dart';
import 'route_item.dart';

class WebRTCApp extends StatefulWidget {
  @override
  _WebRTCAppState createState() => _WebRTCAppState();
}

// enum DialogDemoAction {
//   cancel,
//   connect,
// }

class _WebRTCAppState extends State<WebRTCApp> {
  // This is half from ChatGPT and half from the futter-webrtc-demo on GitHub
  String _server = 'www.chatmoshi.com';
  // List<RouteItem> items = [];
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _dataChannelLabel1 = 'status';
  final _dataChannelLabel2 = 'transcript';
  RTCDataChannel? _dataChannel1;
  RTCDataChannel? _dataChannel2;

  @override
  void initState() {
    super.initState();
    print("initState");
  }

  // TODO create peer connection etc upon button push
  void _initWebRTC() async {
    print("_initWebRTC");
    await _createPeerConnection();
    await _getUserMedia();
    await _createDataChannels();
  }

  void showDemoDialog<T>(
      {required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          _prefs.setString('server', _server);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      CallSample(host: _server)));
        }
      }
    });
  }

  _showAddressDialog(context) {
    showDemoDialog<DialogDemoAction>(
        context: context,
        child: AlertDialog(
            title: const Text('Enter server address:'),
            content: TextField(
              onChanged: (String text) {
                setState(() {
                  _server = text;
                });
              },
              decoration: InputDecoration(
                hintText: _server,
              ),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.cancel);
                  }),
              TextButton(
                  child: const Text('CONNECT'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.connect);
                  })
            ]));
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'P2P Call Sample',
          subtitle: 'P2P Call Sample.',
          push: (BuildContext context) {
            _datachannel = false;
            _showAddressDialog(context);
          }),
      RouteItem(
          title: 'Data Channel Sample',
          subtitle: 'P2P Data Channel.',
          push: (BuildContext context) {
            _datachannel = true;
            _showAddressDialog(context);
          }),
    ];
  }

  _buildRow(context, item) {
    print("_buildRow");
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  Future<void> _createPeerConnection() async {
    print("_createPeerConnection");
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);
    print("\t_peerConnection: $_peerConnection");

    _peerConnection?.onIceCandidate = (candidate) {
      // Handle ICE candidates if needed
      print("\tICE candidate: $candidate");
    };

    _peerConnection?.onAddStream = (stream) {
      // Handle remote stream if needed
      print("\tstream: $stream");
    };
  }

  Future<void> _getUserMedia() async {
    print("_getUserMedia");
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    setState(() {
      _localStream = stream;
    });

    print("\tstream: $stream");
    _peerConnection?.addStream(stream);
  }

  Future<void> _createDataChannels() async {
    print("_createDataChannels");
    final dataChannel1Init = RTCDataChannelInit();
    _dataChannel1 = await _peerConnection?.createDataChannel(_dataChannelLabel1, dataChannel1Init);

    final dataChannel2Init = RTCDataChannelInit();
    _dataChannel2 = await _peerConnection?.createDataChannel(_dataChannelLabel2, dataChannel2Init);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Moshi'),
          ),
        body: Column(
          children: <Widget>[
            Text('is a spoken language tutor.'),
            ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0.0),
              itemCount: items.length,
              itemBuilder: (context, i) {
                return _buildRow(context, items[i]);
                }
              )
           ],
        ),
      ),
    );
  }
}
