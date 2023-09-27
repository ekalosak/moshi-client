/// Stateful widget for the feedback screen.
/// The main widget has these components:
/// - a text field for the user to enter feedback
/// - a set of radio buttons for the user to select the feedback type
/// - a button to submit the feedback.
/// The feedback is stored in a Firestore collection called 'feedback'.
/// When the user clicks the submit button the feedback is stored in a document.
/// If the user has submitted more than 3 feedbacks in the last 24 hours, the submit button is disabled and a message is displayed.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/types.dart';

int MAX_FEEDBACKS_PER_DAY = 3;

class Feedback {
  final String uid;
  final String body;
  final String type;
  final DateTime timestamp;
  Feedback({
    required this.uid,
    required this.body,
    required this.type,
    required this.timestamp,
  });

  factory Feedback.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Feedback(
      uid: data['uid'],
      body: data['body'],
      type: data['type'],
      timestamp: data['timestamp'].toDate(),
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  final Profile profile;
  FeedbackScreen({required this.profile});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late StreamSubscription _feedbackListener;
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> _feedbackTypes = ["bug", "feature", "other"];
  String? _feedbackType;
  int? _numFeedbacks;

  @override
  void initState() {
    super.initState();

    /// Get the number of feedbacks the user has submitted in the last 24 hours.
    _feedbackListener = FirebaseFirestore.instance
        .collection('feedback')
        .where('uid', isEqualTo: widget.profile.uid)
        .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(days: 1)))
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      // print("snapshot.docs.length = ${snapshot.docs.length}");
      setState(() {
        _numFeedbacks = snapshot.docs.length;
      });
    });
  }

  @override
  void dispose() {
    _feedbackListener.cancel();
    super.dispose();
  }

  List<Widget> _buildFeedbackTypes() {
    List<Widget> feedbackTypes = [];
    for (String type in _feedbackTypes) {
      feedbackTypes.add(
        Row(
          children: [
            Radio(
              value: type,
              groupValue: _feedbackType,
              onChanged: (String? value) {
                setState(() {
                  _feedbackType = value;
                });
              },
            ),
            Text(type),
          ],
        ),
      );
    }
    return feedbackTypes;
  }

  Future<void> _submitFeedback(String fbk, String typ) async {
    // print("Submitting feedback...");
    // print("uid: ${widget.profile.uid}");
    // print("body: $fbk");
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'uid': widget.profile.uid,
        'body': fbk,
        'type': typ,
        'timestamp': DateTime.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Feedback submitted!"),
          ),
        );
        setState(() {
          _feedbackController.text = "";
          _feedbackType = null;
        });
      }
    } catch (e) {
      // print("Error submitting feedback: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error submitting feedback, please try again later."),
          ),
        );
      }
    }
  }

  ElevatedButton _buildFeedbackButton() {
    return _numFeedbacks != null && _numFeedbacks! >= MAX_FEEDBACKS_PER_DAY
        ? ElevatedButton(
            onPressed: null,
            child: Text("Submit"),
          )
        : ElevatedButton(
            onPressed: (_feedbackType != null && _feedbackController.text != "" && _feedbackType != null)
                ? () async {
                    await _submitFeedback(_feedbackController.text, _feedbackType!);
                    // print("Feedback submitted!");
                  }
                : null,
            child: Text("Submit"),
          );
  }

  Widget _buildFeedbackForm() {
    List<Widget> feedbackTypes = _buildFeedbackTypes();
    TextField feedbackField = TextField(
      decoration: InputDecoration(
        hintText: "Enter your feedback here",
      ),
      maxLines: 5,
      controller: _feedbackController,
    );
    ElevatedButton submitButton = _buildFeedbackButton();
    Column body = (_numFeedbacks! < MAX_FEEDBACKS_PER_DAY)
        ? Column(
            children: [
              feedbackField,
              SizedBox(height: 16),
              ...feedbackTypes,
              SizedBox(height: 16),
              submitButton,
            ],
          )
        : Column(
            children: [
              Text(
                  "You have submitted $MAX_FEEDBACKS_PER_DAY feedbacks in the last 24 hours, which is our daily limit. Thank you for making Moshi better!"),
            ],
          );
    return Padding(
      padding: EdgeInsets.all(16),
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _numFeedbacks == null ? Center(child: CircularProgressIndicator()) : _buildFeedbackForm();
    return Padding(
      padding: EdgeInsets.all(16),
      child: body,
    );
  }
}
