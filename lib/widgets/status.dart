/// Connection status widget.
/// This widget contains four status indicators the user will see to provide
/// insight into the process of connecting to the server and setting up a
/// conversation.
import 'package:flutter/material.dart';

class ConnectionStatus extends StatelessWidget {
  final MicStatus micStatus;
  final ServerStatus serverStatus;
  final CallStatus callStatus;
  final ColorScheme colorScheme;

  ConnectionStatus({
    required this.micStatus,
    required this.serverStatus,
    required this.callStatus,
    required this.colorScheme,
  });

  Widget _micIcon(MicStatus status) {
    return switch (status) {
      MicStatus.off => Icon(Icons.mic_off_outlined, color: colorScheme.background),
      MicStatus.noPermission => Icon(Icons.mic_off, color: colorScheme.error),
      MicStatus.muted => Icon(Icons.mic_none_outlined, color: colorScheme.primary),
      MicStatus.on => Icon(Icons.mic_outlined, color: colorScheme.tertiary)
    };
  }

  Widget _serverIcon(ServerStatus status) {
    return switch (status) {
      ServerStatus.unknown => Icon(Icons.cloud_outlined, color: colorScheme.background),
      ServerStatus.pending => Icon(Icons.cloud_sync_outlined, color: colorScheme.secondary),
      ServerStatus.ready => Icon(Icons.cloud_done_outlined, color: colorScheme.primary),
      ServerStatus.error => Icon(Icons.cloud_off_outlined, color: colorScheme.error)
    };
  }

  Widget _callIcon(CallStatus status) {
    return switch (status) {
      CallStatus.idle => Icon(Icons.call_outlined, color: colorScheme.background),
      CallStatus.ringing => Icon(Icons.call_outlined, color: colorScheme.tertiary),
      CallStatus.inCall => Icon(Icons.call_outlined, color: colorScheme.primary),
      CallStatus.error => Icon(Icons.call_missed_outgoing_outlined, color: colorScheme.error),
    };
  }

  @override
  Widget build(BuildContext context) {
    print('micStatus: $micStatus');
    print('serverStatus: $serverStatus');
    print('callStatus: $callStatus');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [_micIcon(micStatus), _serverIcon(serverStatus), _callIcon(callStatus)],
    );
  }
}

enum MicStatus {
  noPermission,
  off,
  muted,
  on,
}

enum ServerStatus {
  pending,
  unknown,
  ready,
  error,
}

enum CallStatus {
  idle,
  ringing,
  inCall,
  error,
}
