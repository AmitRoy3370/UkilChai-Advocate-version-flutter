import 'package:flutter/material.dart';

class TextFormatter {
  // প্রিটি স্টেজ নাম বানানোর উন্নত ফাংশন
  static String prettyStageName(String stage, {BuildContext? context}) {
    if (stage.isEmpty) return '';

    // প্রথমে সব রিপ্লেসমেন্ট করুন
    String name = stage
        .replaceAll("CASE_", "")
        .replaceAll("_PAYMENT", "")
        .replaceAll("_", " ");

    // ছোট শব্দের তালিকা (যেগুলো capital করা যাবে না)
    final smallWords = {'of', 'and', 'for', 'in', 'to', 'on', 'at', 'by', 'with'};

    // প্রতিটি শব্দ প্রসেস করুন
    final words = name.split(' ');
    final processedWords = words.map((word) {
      final lowerWord = word.toLowerCase();

      // ছোট শব্দ চেক
      if (smallWords.contains(lowerWord)) {
        return lowerWord;
      }

      // বড় শব্দের জন্য প্রথম অক্ষর বড়, বাকি ছোট
      if (word.length > 2) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }

      // ২ অক্ষরের শব্দ
      return word.toUpperCase();
    }).toList();

    // প্রথম শব্দ সবসময় ক্যাপিটাল
    if (processedWords.isNotEmpty) {
      processedWords[0] = processedWords[0][0].toUpperCase() +
          processedWords[0].substring(1);
    }

    String result = processedWords.join(' ');

    // স্ক্রিন সাইজ অনুযায়ী শর্ট করা (ঐচ্ছিক)
    if (context != null) {
      final screenWidth = MediaQuery.of(context).size.width;
      result = _shortenForMobile(result, screenWidth);
    }

    return result;
  }

  // মোবাইলের জন্য টেক্সট শর্ট করা
  static String _shortenForMobile(String text, double screenWidth) {
    if (screenWidth < 380 && text.length > 25) {
      // খুব ছোট স্ক্রিনে লম্বা টেক্সট শর্ট করুন
      return _abbreviateText(text);
    }
    if (screenWidth < 480 && text.length > 35) {
      return _abbreviateText(text);
    }
    return text;
  }

  // টেক্সট অ্যাব্রিভিয়েট করুন
  static String _abbreviateText(String text) {
    // কিছু সাধারণ রিপ্লেসমেন্ট
    final abbreviations = {
      'Document': 'Doc',
      'Registration': 'Reg',
      'Preparation': 'Prep',
      'Verification': 'Verif',
      'Investigation': 'Invest',
      'Consultation': 'Consult',
      'Submission': 'Submit',
      'Settlement': 'Settle',
      'Negotiation': 'Negot',
      'Certification': 'Cert',
      'Authentication': 'Auth',
    };

    String abbreviated = text;
    for (var entry in abbreviations.entries) {
      abbreviated = abbreviated.replaceAll(entry.key, entry.value);
    }

    return abbreviated;
  }

  // টেক্সটকে লাইন ব্রেক সহ ফরম্যাট করা
  static List<String> formatForLines(String text, int maxLineLength) {
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';

    for (var word in words) {
      if ((currentLine + word).length > maxLineLength) {
        lines.add(currentLine.trim());
        currentLine = word;
      } else {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine.trim());
    }

    return lines;
  }
}