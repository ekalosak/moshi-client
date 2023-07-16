class AudioException implements Exception {
  final String message;

  AudioException(this.message);

  @override
  String toString() => '$message';
}

