// The Vocabulary widget displays a list of vocab words.
// You feed it a map of vocab words e.g. {'word': {'definition': 'meaning'}}.
import 'package:flutter/material.dart';

import 'package:moshi/types.dart';

class Vocabulary extends StatefulWidget {
  final Map<String, Vocab>? vocab;
  Vocabulary(this.vocab);
  @override
  _VocabularyState createState() => _VocabularyState();
}

class _VocabularyState extends State<Vocabulary> {
  @override
  Widget build(BuildContext context) {
    // print("vocab: ${widget.vocab}");
    if (widget.vocab == null) {
      return SizedBox();
    }
    List<String> vocKeys = widget.vocab!.keys.toList();
    final Widget vocab = ListView.builder(
      padding: EdgeInsets.only(bottom: 4),
      itemCount: vocKeys.length,
      itemBuilder: (BuildContext context, int index) {
        String key = vocKeys[index];
        return VocTile(widget.vocab![key]!);
      },
    );
    return vocab;
  }
}

/// A tile for a vocab word.
/// The tile is one horizontal row with 2 elements.
/// 1. The term, on top of a colored rectangle.
/// 2. The definition.
class VocTile extends StatefulWidget {
  final Vocab voc;
  VocTile(this.voc);
  @override
  _VocTile createState() => _VocTile();
}

class _VocTile extends State<VocTile> {
  bool _showTranslation = false;

  Color _partOfSpeechColor(String? partOfSpeech) {
    switch (partOfSpeech) {
      case 'verb':
        return Colors.green;
      case 'noun':
        return Colors.blue;
      case 'adjective':
        return Colors.purple;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // print("voc: $voc");
    final Widget term = Text(
      widget.voc.term,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
      ),
    );
    String defStr = widget.voc.definitionTranslation ?? "failed to extract 🫣";
    String defTrans = widget.voc.definition ?? "failed to extract 🫣";
    final Widget definition = Text(
      _showTranslation ? defTrans : defStr,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
    final Widget tile = Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _partOfSpeechColor(widget.voc.partOfSpeech),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: term,
              ),
              onTap: () => setState(() {
                _showTranslation = !_showTranslation;
              }),
            ),
          ),
          Flexible(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: definition,
            ),
          ),
        ],
      ),
      SizedBox(height: 8),
    ]);
    return tile;
  }
}
