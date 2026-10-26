// simple_audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'dart:html' as html;


class SimpleAudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  // ✅ সাউন্ড প্লে করার সহজ উপায়
  static Future<void> playNotificationSound() async {
    try {
      // ১ম পদ্ধতি: বিল্ট-ইন সিস্টেম সাউন্ড (শুধু মোবাইল)
      if (!kIsWeb) {
        await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      } else {
        // ওয়েবের জন্য Alternative - HTML5 Audio
        _playWebAudio();
      }
    } catch (e) {
      print("Audio play error: $e");
      // ব্যাকআপ: CPU বীপ তৈরি
      _playCpuBeep();
    }
  }



  static void _playWebAudio() {
    // ১ম পদ্ধতি: অডিও এলিমেন্ট তৈরি
    final audio = html.AudioElement();
    audio.src = 'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3'; // অনলাইন সাউন্ড
    audio.load();
    audio.play().catchError((e) {
      print("Audio play error: $e");
      _playFallbackSound();
    });
  }

  static void _playFallbackSound() {
    // ব্যাকআপ: সিম্পল বীপ
    html.window.console.log('\x07'); // কনসোল বীপ
  }

  // ✅ CPU বীপ (সব প্ল্যাটফর্মে কাজ করে)
  static void _playCpuBeep() {
    // এটি শুধুমাত্র কনসোলের জন্য
    print('\x07'); // ASCII বেল ক্যারেক্টার
  }
}