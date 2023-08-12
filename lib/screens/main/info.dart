// Stateful widget for the home feed screen, it shows the user a feed of news and updates along with the privacy policy etc.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/types.dart';

class Item {
  final String id;
  final String title;
  final String subtitle;
  final String body;
  final String type;
  final DateTime timestamp;

  Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.type,
    required this.timestamp,
  });

  factory Item.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // print("data: ${data.entries.toList()}");
    return Item(
      id: doc.id,
      title: data.containsKey('title') ? data['title'] : '',
      subtitle: data.containsKey('subtitle') ? data['subtitle'] : '',
      body: data.containsKey('body') ? data['body'] : '',
      type: data.containsKey('type') ? data['type'] : '',
      timestamp: data['timestamp'].toDate(),
    );
  }
}

class FeedScreen extends StatefulWidget {
  final Profile profile;
  FeedScreen({required this.profile});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late StreamSubscription _infoListener;
  late StreamSubscription _feedListener;
  List<Item>? _feed; // feed for this user

  @override
  void initState() {
    super.initState();
    _infoListener = FirebaseFirestore.instance.collection('info').snapshots().listen((event) {
      print("infoListener: ${event.docs.length} docs");
      final List<Item> info = [];
      for (var doc in event.docs) {
        info.add(Item.fromDocumentSnapshot(doc));
      }
      if (info.isNotEmpty) {
        if (mounted) {
          _addToFeed(info);
        }
      }
    });
    _feedListener = FirebaseFirestore.instance
        .collection('feed')
        .where('uid', isEqualTo: widget.profile.uid)
        .snapshots()
        .listen((event) {
      print("feedListener: ${event.docs.length} docs");
      final List<Item> feed = [];
      for (var doc in event.docs) {
        feed.add(Item.fromDocumentSnapshot(doc));
      }
      if (feed.isNotEmpty) {
        if (mounted) {
          _addToFeed(feed);
        }
      }
    });
  }

  @override
  void dispose() {
    _infoListener.cancel();
    _feedListener.cancel();
    _feed?.clear();
    super.dispose();
  }

  void _addToFeed(List<Item> items) {
    print("_addToFeed: ${items.length} items");
    List<Item> feed = _feed ?? [];
    for (var i in items) {
      int index = feed.indexWhere((element) => element.id == i.id);
      if (index == -1) {
        feed.add(i);
      } else {
        feed[index] = i;
      }
    }
    feed.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _feed = feed;
    });
  }

  Color _getBkgdColor(String type) {
    switch (type) {
      case 'news':
        return Theme.of(context).colorScheme.secondary;
      case 'update':
        return Theme.of(context).colorScheme.tertiary;
      case 'policy':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.background;
    }
  }

  Color _getTextColor(String type) {
    switch (type) {
      case 'news':
        return Theme.of(context).colorScheme.onSecondary;
      case 'update':
        return Theme.of(context).colorScheme.onTertiary;
      case 'policy':
        return Theme.of(context).colorScheme.onPrimary;
      default:
        return Theme.of(context).colorScheme.onBackground;
    }
  }

  Widget _buildFeedList() {
    print("_buildFeedList");
    List<Item> feed = _feed!;
    itemBuilder(BuildContext context, int index) {
      Item i = feed[index];
      Color bkgdColor = _getBkgdColor(i.type);
      Color textColor = _getTextColor(i.type);
      return Padding(
        padding: EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: bkgdColor,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ListTile(
                title: Text(i.title),
                subtitle: Text(i.subtitle),
                textColor: textColor,
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
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: feed.length,
      itemBuilder: itemBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _feed == null ? Center(child: CircularProgressIndicator()) : _buildFeedList();
    return Padding(
      padding: EdgeInsets.all(16),
      child: body,
    );
  }
}
