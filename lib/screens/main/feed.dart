// Stateful widget for the home feed screen, it shows the user a feed of news and updates along with the privacy policy etc.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:moshi/types.dart';

class Item {
  final String title;
  final String subtitle;
  final String body;
  final String type;
  final DateTime timestamp;
  bool read;
  final String id;

  Item({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.read,
    required this.id,
  });

  factory Item.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Item(
      title: data.containsKey('title') ? data['title'] : '',
      subtitle: data.containsKey('subtitle') ? data['subtitle'] : '',
      body: data.containsKey('body') ? data['body'] : '',
      type: data.containsKey('type') ? data['type'] : '',
      timestamp: data.containsKey('timestamp') ? data['timestamp'].toDate() : '',
      read: data.containsKey('read') ? data['read'] : true,
      id: doc.id,
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, Item> _userFeed = {}; // feed for this user
  Map<String, Item> _globalFeed = {}; // global feed records
  Map<String, bool> _globalRead = {}; // whether the user has read the global feed item

  @override
  void initState() {
    super.initState();
    _initListeners();
    _auth.authStateChanges().listen((User? usr) {
      if (usr == null) {
        _cancelListeners();
      }
    });
  }

  @override
  void dispose() {
    _cancelListeners();
    _userFeed.clear();
    _globalFeed.clear();
    _globalRead.clear();
    super.dispose();
  }

  /// Setup the global feed and user feed listeners
  void _initListeners() {
    _globalFeedListener = FirebaseFirestore.instance.collection('feed').snapshots().listen((event) {
      final Map<String, Item> globalFeed = {};
      for (var doc in event.docs) {
        globalFeed[doc.id] = Item.fromDocumentSnapshot(doc);
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
      final Map<String, Item> userFeed = {};
      final Map<String, bool> globalRead = {};
      for (var doc in event.docs) {
        Map<String, dynamic> data = doc.data();
        if (data.containsKey('global')) {
          globalRead[doc.id] = data['read'];
        } else {
          final Item item = Item.fromDocumentSnapshot(doc);
          userFeed[item.id] = item;
        }
      }
      if (userFeed.isNotEmpty) {
        _addToUserFeed(userFeed, globalRead);
      }
    });
  }

  void _cancelListeners() {
    _globalFeedListener.cancel();
    _feedListener.cancel();
  }

  void _addToUserFeed(Map<String, Item> userFeed, Map<String, bool> globalRead) {
    // print("feed: _addToUserFeed: ${userFeed.length} user feed items");
    // print("feed: _addToUserFeed: ${globalRead.length} global read items");
    Map<String, Item> feed = _userFeed;
    Map<String, bool> read = _globalRead;
    for (var item in userFeed.entries) {
      // print("feed: _addToUserFeed: user: ${item.key} ${item.value.read}");
      feed[item.key] = item.value;
    }
    for (var item in globalRead.entries) {
      // print("feed: _addToUserFeed: global: ${item.key} ${item.value}");
      read[item.key] = item.value;
    }
    setState(() {
      _userFeed = feed;
      _globalRead = read;
    });
  }

  void _addToGlobalFeed(Map<String, Item> globalFeed) {
    // print("feed: _addToGlobalFeed: ${globalFeed.length} global feed items");
    Map<String, Item> feed = _globalFeed;
    // print("Adding to global feed: $globalFeed");
    for (var item in globalFeed.entries) {
      feed[item.key] = item.value;
    }
    setState(() {
      _globalFeed = feed;
    });
  }

  Widget _buildFeedList() {
    // print("feed: _buildFeedList");
    Map<String, Item> feedMap = _userFeed;
    for (var item in _globalFeed.entries) {
      if (_globalRead.containsKey(item.key)) {
        item.value.read = _globalRead[item.key] ?? true;
      }
      feedMap[item.key] = item.value;
      // print("Added item ${item.key} ${item.value.read}");
    }
    List<Item> feed = feedMap.values.toList();
    // print("feed: _buildFeedList: ${feed.length} items");
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
              child: Card(
                  elevation: 8,
                  margin: EdgeInsets.all(0),
                  color: Theme.of(context).colorScheme.background,
                  shadowColor: i.read ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
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
                              child: Text(
                                i.body,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  // print("feed: _buildFeedList: onTap: ${i.id}");
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.profile.uid)
                                        .collection('feed')
                                        .doc(i.id)
                                        .update({'read': true});
                                  } on FirebaseException {
                                    // print("feed: _buildFeedList: onTap: error updating read status");
                                  }
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text("x",
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.tertiary,
                                        )),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )),
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
