import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class PresenceSocketService {
  WebSocketChannel? _channel;

  void connect(String userId) {
    _channel = WebSocketChannel.connect(
      Uri.parse("wss://ukilchai.abrdns.com/ws-chat?userId=$userId"),
    );

    _channel!.stream.listen((message) {
      print("WS MESSAGE: $message");
    });

    print("CONNECTED: $userId");
  }

  void disconnect() {
    _channel?.sink.close();
  }
}