// Stateful widget for the info screen, it shows the user a feed of news and updates along with the privacy policy etc.
// It will get a list of news docs from the Firestore collection 'info'
// Filter by 'type' doc attribute and only get the latest 3 docs for each type.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi_client/types.dart';

class Info {
  final String title;
  final String subtitle;
  final String body;
  final String type;
  final DateTime timestamp;
  Info({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.type,
    required this.timestamp,
  });

  factory Info.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Info(
      title: data['title'],
      subtitle: data['subtitle'],
      body: data['body'],
      type: data['type'],
      timestamp: data['timestamp'].toDate(),
    );
  }
}

class InfoScreen extends StatefulWidget {
  final Profile profile;
  InfoScreen({required this.profile});
  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  late StreamSubscription _infoListener;
  List<Info>? _info; // info for this user

  @override
  void initState() {
    super.initState();
    // listen for info documents with this user's uid in the uid field.
    // the info documents have their own unique document id.
    _infoListener = FirebaseFirestore.instance
        .collection('info')
        .where('uid', isEqualTo: widget.profile.uid)
        .snapshots()
        .listen((event) {
      final List<Info> info = [];
      for (var doc in event.docs) {
        info.add(Info.fromDocumentSnapshot(doc));
      }
      if (info.isNotEmpty) {
        if (mounted) {
          _addInfo(info);
        }
      }
    });
  }

  @override
  void dispose() {
    _infoListener.cancel();
    _info?.clear();
    super.dispose();
  }

  void _addInfo(List<Info> info) {
    setState(() {
      _info ??= [];
      for (var i in info) {
        if (!_info!.contains(i)) {
          _info!.add(i);
        }
      }
      _info!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Color _getBkgdColor(String type) {
    switch (type) {
      case 'news':
        return Colors.blue[50]!;
      case 'update':
        return Colors.green[50]!;
      case 'privacy':
        return Colors.purple[50]!;
      default:
        return Colors.white;
    }
  }

  Widget _buildInfoList() {
    print("_buildInfoList");
    List<Info> info = _info!;
    itemBuilder(BuildContext context, int index) {
      Info i = info[index];
      Color bkgdColor = _getBkgdColor(i.type);
      return ListTile(
        tileColor: bkgdColor,
        title: Text(i.title),
        subtitle: Text(i.subtitle),
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(i.title),
                content: SingleChildScrollView(
                  child: Text(i.body),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Close"),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return ListView.builder(
      itemCount: info.length,
      itemBuilder: itemBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _buildInfoList();
    return Padding(
      padding: EdgeInsets.all(16),
      child: body,
    );
  }
}
