import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

// struct Activity has id and title and type

class ActivitySelector extends StatefulWidget {
  final String selectedValue;
  final Function(String) onChanged;
  List<String> activities = [];  // titles
  late StreamSubscription<DocumentSnapshot> _activityListener;  // TODO populate activities with the titles of the ac

  ActivitySelector({this.selectedValue, this.onChanged});

  @override
  _ActivitySelectorState createState() => _ActivitySelectorState();
}

class _ActivitySelectorState extends State<ActivitySelector> {
  String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
    _activityListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        print("wrapper: User profile exists and is not empty.");
        setState(() {
          profile = Profile(
            uid: snapshot.id,
            lang: snapshot['language'],
            name: snapshot['name'],
            primaryLang: snapshot['native_language'],
          );
        });
      } else {
        print("wrapper: User profile doesn't exist or is empty.");
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => MakeProfileScreen(user: widget.user)), (route) => false);
      }
    });
    _supportedLangsListener = FirebaseFirestore.instance
        .collection('config')
        .doc('languages')
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        print("wrapper: config/languages exists and isn't empty.");
        setState(() {
          languages = snapshot.data() as Map<String, dynamic>;
        });
      } else {
        print("wrapper: config/languages doesn't exist or is empty: ${snapshot.exists} ${snapshot.data()}");
      }
    });
  }


  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedValue,
      icon: Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      style: TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String newValue) {
        setState(() {
          _selectedValue = newValue;
          widget.onChanged(newValue);
        });
      },
      items: <String>['Running', 'Cycling', 'Swimming', 'Walking'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
