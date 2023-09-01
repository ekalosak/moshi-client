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
    print("feed: Item.fromDocumentSnapshot: data: ${data.entries.toList()}");
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
  List<Item> _feed = []; // feed for this user

  @override
  void initState() {
    super.initState();
    _infoListener = FirebaseFirestore.instance.collection('info').snapshots().listen((event) {
      print("info: infoListener: ${event.docs.length} docs");
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
        .collection('users')
        .doc(widget.profile.uid)
        .collection('feed')
        .snapshots()
        .listen((event) {
      print("info: feedListener: ${event.docs.length} docs");
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

  Widget _buildFeedList() {
    print("feed: _buildFeedList");
    List<Item> feed = _feed!;
    itemBuilder(BuildContext context, int index) {
      Item i = feed[index];
      Color bkgdColor = Theme.of(context).colorScheme.surface;
      return Padding(
        padding: EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: bkgdColor,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ListTile(
                title: Text(i.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
                      fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                    )),
                subtitle: Text(i.subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                      fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                    )),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(i.title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            )),
                        content: SingleChildScrollView(
                          child: Text(i.body,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
                                fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                              )),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "x",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
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
    Widget body = _buildFeedList();
    return Padding(
      padding: EdgeInsets.all(16),
      child: body,
    );
  }
}
