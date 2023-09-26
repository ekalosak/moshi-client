// The Vocabulary widget displays a list of vocab words.
// You feed it a map of vocab words e.g. {'word': {'definition': 'meaning'}}.
import 'package:flutter/material.dart';

class Vocab {
  final String term;
  final String? termTranslation;
  final String? definition;
  final String? definitionTranslation;
  final String? partOfSpeech;
  Vocab(this.term, {this.termTranslation, this.definition, this.definitionTranslation, this.partOfSpeech});
  // to string method
  @override
  String toString() {
    return "Vocab(term: $term, termTranslation: $termTranslation, definition: $definition, definitionTranslation: $definitionTranslation, partOfSpeech: $partOfSpeech)";
  }

  // from map<str, str>; all but term are optional
  factory Vocab.fromMap(Map<String, dynamic> map) {
    return Vocab(
      map['term'],
      termTranslation: map['term_translation']?.toString(),
      definition: map['definition']?.toString(),
      definitionTranslation: map['definition_translation']?.toString(),
      partOfSpeech: map['part_of_speech']?.toString(),
    );
  }
}

class Vocabulary extends StatefulWidget {
  final Map<String, dynamic>? vocab;
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
        Vocab voc = Vocab.fromMap(widget.vocab![key]);
        return VocTile(voc);
      },
    );
    return Container(
      height: 200,
      width: 200,
      child: Center(child: vocab),
    );
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
          GestureDetector(
            child: Flexible(
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _partOfSpeechColor(widget.voc.partOfSpeech),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: term,
              ),
            ),
            onTap: () => setState(() {
              _showTranslation = !_showTranslation;
            }),
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
