import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../Utils/BaseURL.dart' as BASE_URL;

class NotificationSocketService {
  StompClient? stompClient;

  void connect(String userId, Function(dynamic) onMessage) {
    stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '${BASE_URL.Urls().baseURL.replaceAll("/api/","")}/ws',
        onConnect: (frame) {
          print("Connected to notification socket");

          stompClient!.subscribe(
            destination: '/user/$userId/queue/notifications',
            callback: (frame) {
              if (frame.body != null) {
                onMessage(jsonDecode(frame.body!));
              }
            },
          );
        },
        onWebSocketError: (error) => print(error),
      ),
    );

    stompClient!.activate();
  }

  void disconnect() {
    stompClient?.deactivate();
  }
}
