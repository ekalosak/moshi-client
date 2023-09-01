// Stateful widget for the home feed screen, it shows the user a feed of news and updates along with the privacy policy etc.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/types.dart';

class Item {
  final String title;
  final String subtitle;
  final String body;
  final String type;
  final DateTime timestamp;
  bool read;

  Item({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.read,
  });

  factory Item.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print("feed: Item.fromDocumentSnapshot: data: ${data.entries.toList()}");
    return Item(
      title: data.containsKey('title') ? data['title'] : '',
      subtitle: data.containsKey('subtitle') ? data['subtitle'] : '',
      body: data.containsKey('body') ? data['body'] : '',
      type: data.containsKey('type') ? data['type'] : '',
      timestamp: data.containsKey('timestamp') ? data['timestamp'].toDate() : '',
      read: data.containsKey('read') ? (data['read'] == 'true') : true,
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
  late StreamSubscription _globalFeedListener;
  late StreamSubscription _feedListener;
  Map<String, Item> _userFeed = {}; // feed for this user
  Map<String, Item> _globalFeed = {}; // global feed records
  Map<String, bool> _globalRead = {}; // whether the user has read the global feed item

  @override
  void initState() {
    super.initState();
    _globalFeedListener = FirebaseFirestore.instance.collection('feed').snapshots().listen((event) {
      print("feed: _globalFeedListener: ${event.docs.length} docs");
      final Map<String, Item> globalFeed = {};
      for (var doc in event.docs) {
        globalFeed[doc.id] = Item.fromDocumentSnapshot(doc);
        print('HELLO doc: ${doc.data()}');
      }
      if (globalFeed.isNotEmpty) {
        _addToGlobalFeed(globalFeed);
      }
    });
    _feedListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('feed')
        .snapshots()
        .listen((event) {
      print("feed: feedListener: ${event.docs.length} docs");
      final Map<String, Item> userFeed = {};
      final Map<String, bool> globalRead = {};
      for (var doc in event.docs) {
        Map<String, dynamic> data = doc.data();
        if (data.containsKey('global')) {
          // stub for global feed item, holds read status
          globalRead[doc.id] = (data['read'] == 'true');
        } else {
          // actual item
          final Item item = Item.fromDocumentSnapshot(doc);
          userFeed[doc.id] = item;
        }
      }
      if (userFeed.isNotEmpty) {
        _addToUserFeed(userFeed, globalRead);
      }
    });
  }

  @override
  void dispose() {
    _globalFeedListener.cancel();
    _feedListener.cancel();
    _userFeed.clear();
    super.dispose();
  }

  void _addToUserFeed(Map<String, Item> userFeed, Map<String, bool> globalRead) {
    print("feed: _addToUserFeed: ${userFeed.length} user feed items");
    print("feed: _addToUserFeed: ${globalRead.length} global read items");
    Map<String, Item> feed = _userFeed;
    Map<String, bool> read = _globalRead;
    for (var item in userFeed.entries) {
      feed[item.key] = item.value;
    }
    for (var item in globalRead.entries) {
      read[item.key] = item.value;
    }
    setState(() {
      _userFeed = feed;
      _globalRead = read;
    });
  }

  void _addToGlobalFeed(Map<String, Item> globalFeed) {
    print("feed: _addToGlobalFeed: ${globalFeed.length} global feed items");
    Map<String, Item> feed = _globalFeed;
    for (var item in globalFeed.entries) {
      feed[item.key] = item.value;
    }
    setState(() {
      _globalFeed = feed;
    });
  }

  Widget _buildFeedList() {
    print("feed: _buildFeedList");
    Map<String, Item> feedMap = _userFeed;
    for (var item in _globalFeed.entries) {
      if (_globalRead.containsKey(item.key)) {
        item.value.read = _globalRead[item.key] ?? true;
      }
      feedMap[item.key] = item.value;
    }
    List<Item> feed = feedMap.values.toList();
    feed.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
                title: Text(
                  i.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                subtitle: Text(
                  i.subtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          i.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
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
