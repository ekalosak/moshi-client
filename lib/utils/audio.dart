import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'package:moshi/types.dart';

// AUDIO CACHE DIRECTORY UTILITIES

/// Where audio files will be stored on the device.
Future<Directory> audioCacheDir() async {
  Directory cacheDir = await getApplicationCacheDirectory();
  return Directory('${cacheDir.path}/audio/');
}

/// Creates the audio cache directory if it doesn't exist.
Future<Directory> ensureAudioCacheExists() async {
  final Directory acd = await audioCacheDir();
  if (!await acd.exists()) {
    await acd.create(recursive: true);
  }
  return acd;
}

/// Deletes audio in the directory (.wav, .flac, .m4a)
/// until the directory contains less than [maxAudioCacheSize] bytes.
/// Returns the number of bytes deleted.
/// If [maxAudioCacheSize] is null or 0, then it will delete all audio.
Future<int> trimAudioCache({int maxAudioCacheSize = 0}) async {
  final Directory acd = await audioCacheDir();
  if (!await acd.exists()) {
    return 0;
  }
  final List<FileSystemEntity> files = acd.listSync(recursive: true, followLinks: false);
  int totalSize = 0;
  for (FileSystemEntity file in files) {
    if (file is File) {
      totalSize += await file.length();
    }
  }
  if (maxAudioCacheSize == 0 || totalSize < maxAudioCacheSize) {
    return 0;
  }
  files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
  int deletedSize = 0;
  for (FileSystemEntity file in files) {
    if (file is File) {
      deletedSize += await file.length();
      await file.delete();
      if (totalSize - deletedSize < maxAudioCacheSize) {
        break;
      }
    }
  }
  return deletedSize;
}

/// Deletes the audio cache directory if it exists.
Future<void> clearCachedAudio() async {
  final Directory acd = await audioCacheDir();
  if (!await acd.exists()) {
    return;
  }
  await acd.delete(recursive: true);
}

/// Get the next available audio file path for the user.
Future<File> nextUsrAudio(String transcriptId, String extension) async {
  final Directory acd = await audioCacheDir();
  final Directory tcd = Directory('${acd.path}/$transcriptId');
  if (!await tcd.exists()) {
    await tcd.create(recursive: true);
  }
  final List<FileSystemEntity> files = tcd.listSync(recursive: false, followLinks: false);
  final int nextIndex = files.length;
  final String nextPath = '${tcd.path}/$nextIndex-USR.$extension';
  return File(nextPath);
}

// AUDIO PLAYBACK UTILITIES

/// Download the audio from GCS, if it doesn't exist locally, and play it.
Future<void> playAudioFromMessage(
    Message msg, String transcriptId, AudioPlayer audioPlayer, FirebaseStorage storage) async {
  File astAudio = await downloadAudio(msg.audio, transcriptId, storage);
  try {
    await audioPlayer.play(DeviceFileSource(astAudio.path));
  } catch (e) {
    print("Error playing audio: $e");
  }
}

/// Download the audio from GCS and return the file.
Future<File> downloadAudio(Audio? audio, String transcriptId, FirebaseStorage storage) async {
  if (audio == null) {
    throw ("chat: _downloadAudio: audio is null");
  }
  final Directory acd = await audioCacheDir();
  final String audioName = audio.path.split('/').last;
  final File audioFile = File('${acd.path}$transcriptId/$audioName');
  if (await audioFile.exists()) {
    return audioFile;
  }
  if (storage.bucket != audio.bucket) {
    throw ("chat: _downloadAudio: storage.bucket != audio.bucket: ${storage.bucket} != ${audio.bucket}");
  }
  final Reference audioRef = storage.ref().child(audio.path);
  // print("chat: _downloadAudio: audioRef: $audioRef");
  await audioRef.writeToFile(audioFile);
  // print("chat: _downloadAudio: downloaded $audioName to $audioFile");
  return audioFile;
}

Future<void> uploadAudio(String transcriptId, String path, String uid, FirebaseStorage storage) async {
  final File audioFile = File(path);
  final String audioName = audioFile.path.split('/').last;
  final Reference audioRef = storage.ref().child('audio/$uid/$transcriptId/$audioName');
  final UploadTask uploadTask = audioRef.putFile(audioFile);
  await uploadTask.whenComplete(() => null);
}

/// Return what the local path would be for the given audio.
Future<File?> localAudioPath(Audio aud) async {
  Directory acd = await audioCacheDir();
  String transcriptId = aud.path.split('/')[2];
  String audioFilename = aud.path.split('/').last;
  File audioFile = File('${acd.path}$transcriptId/$audioFilename');
  print("localAudioPath: audioFile: $audioFile");
  if (await audioFile.exists()) {
    return audioFile;
  }
  return null;
}
