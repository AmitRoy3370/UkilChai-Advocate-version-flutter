import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'package:open_filex/open_filex.dart';

// WEB ONLY
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:open_file/open_file.dart';
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class CaseJudgmentAttachmentView extends StatefulWidget {
  final String attachmentId;
  final String jwtToken;

  const CaseJudgmentAttachmentView({
    super.key,
    required this.attachmentId,
    required this.jwtToken,
  });

  @override
  State<CaseJudgmentAttachmentView> createState() =>
      _CaseJudgmentAttachmentViewState();
}

class _CaseJudgmentAttachmentViewState
    extends State<CaseJudgmentAttachmentView> {
  Uint8List? fileBytes;
  String? contentType;
  String? tempFilePath;
  String? webUrl;

  VideoPlayerController? videoController;
  AudioPlayer? audioPlayer;

  @override
  void initState() {
    super.initState();
    loadAttachment();
  }

  @override
  void dispose() {
    videoController?.dispose();
    audioPlayer?.dispose();
    if (kIsWeb && webUrl != null) {
      html.Url.revokeObjectUrl(webUrl!);
    }
    super.dispose();
  }

  // ---------- FILE EXTENSION ----------
  String getFileExtension(String? mime) {
    if (mime == null) return '';
    if (mime.contains('pdf')) return '.pdf';
    if (mime.startsWith('image/jpeg')) return '.jpg';
    if (mime.startsWith('image/png')) return '.png';
    if (mime.startsWith('video/mp4')) return '.mp4';
    if (mime.startsWith('audio/mpeg')) return '.mp3';
    if (mime.startsWith('audio/wav')) return '.wav';
    if (mime == 'application/msword') return '.doc';
    if (mime ==
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return '.docx';
    }
    return '';
  }

  String? detectContentType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'application/pdf';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      return 'video/mp4';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return 'audio/mpeg';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'audio/mpeg';
    }
    if (bytes.length >= 4 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF') {
      return 'audio/wav';
    }
    if (bytes.length >= 4 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'OggS') {
      return 'audio/ogg';
    }
    return null;
  }

  // ---------- LOAD ATTACHMENT ----------
  Future<void> loadAttachment() async {
    print("trying to load attachment");

    final url = Uri.parse(
      '${BASE_URL.Urls().baseURL}case-judgment/attachment/view/${widget.attachmentId}',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.jwtToken}'},
    );

    print("attachment loading status :- ${response.statusCode}");

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load attachment')),
      );
      return;
    }

    fileBytes = response.bodyBytes;
    contentType = response.headers['content-type'];

    if (contentType == null ||
        contentType == 'application/octet-stream' ||
        contentType == 'application/x-www-form-urlencoded') {
      final detected = detectContentType(fileBytes!);
      if (detected != null) {
        contentType = detected;
      }
    }

    // WEB: Create blob URL
    if (kIsWeb) {
      final blob = html.Blob([
        fileBytes!,
      ], contentType ?? 'application/octet-stream');
      webUrl = html.Url.createObjectUrlFromBlob(blob);
    }

    // MOBILE: Save temp file
    if (!kIsWeb &&
        contentType != null &&
        (contentType!.contains('pdf') ||
            contentType!.startsWith('video/') ||
            contentType!.startsWith('audio/') ||
            contentType!.contains('word'))) {
      final dir = await getTemporaryDirectory();
      final fileName = '${widget.attachmentId}${getFileExtension(contentType)}';
      tempFilePath = '${dir.path}/$fileName';
      await File(tempFilePath!).writeAsBytes(fileBytes!);
    }

    // WEB PDF iframe
    if (kIsWeb && contentType != null && contentType!.contains('pdf')) {
      ui_web.platformViewRegistry.registerViewFactory(
        'case-pdf-${widget.attachmentId}',
        (int viewId) => html.IFrameElement()
          ..src = webUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%',
      );
    }

    // VIDEO
    if (contentType != null && contentType!.startsWith('video/')) {
      videoController = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(webUrl!))
          : VideoPlayerController.file(File(tempFilePath!));
      await videoController!.initialize();
    }

    // AUDIO
    if (contentType != null && contentType!.startsWith('audio/')) {
      audioPlayer = AudioPlayer();
      if (kIsWeb) {
        await audioPlayer!.play(UrlSource(webUrl!));
      } else {
        await audioPlayer!.play(DeviceFileSource(tempFilePath!));
      }
    }

    setState(() {});
  }

  String _getExtensionFromContentType(String? contentType) {
    if (contentType == null) return ".bin";

    if (contentType.contains("pdf")) return ".pdf";
    if (contentType.contains("jpeg")) return ".jpeg";
    if (contentType.contains("jpg")) return ".jpg";
    if (contentType.contains("png")) return ".png";
    if (contentType.contains("word")) return ".docx";
    if (contentType.contains("excel")) return ".xlsx";
    if (contentType.contains("text")) return ".txt";

    return ".bin";
  }

  // ---------- DOWNLOAD / OPEN ----------
  Future<void> _openOrDownload() async {
    try {
      final url =
          "${BASE_URL.Urls().baseURL}case-judgment/attachment/${widget.attachmentId}";

      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Download failed")));
        return;
      }

      // 🔹 Extract filename from header
      String fileName = "attachment";
      final disposition = response.headers['content-disposition'];
      if (disposition != null) {
        final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
        if (match != null) {
          fileName = match.group(1)!;
        }
      }

      // 🔹 Get content type
      final contentType =
          response.headers['content-type'] ?? "application/octet-stream";

      // 🔹 Add extension if missing
      if (!fileName.contains(".")) {
        fileName += _getExtensionFromContentType(contentType);
      }

      // ==========================================
      // 🌐 WEB
      // ==========================================
      if (kIsWeb) {
        final blob = html.Blob([response.bodyBytes], contentType);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();

        html.Url.revokeObjectUrl(url);
        return;
      }

      // ==========================================
      // 📱 MOBILE
      // ==========================================
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Attachment error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fileBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // IMAGE
    if (contentType != null && contentType!.startsWith('image/')) {
      return InteractiveViewer(child: Image.memory(fileBytes!));
    }

    // PDF
    if (contentType != null && contentType!.contains('pdf')) {
      if (kIsWeb) {
        return HtmlElementView(viewType: 'case-pdf-${widget.attachmentId}');
      } else {
        return PDFView(filePath: tempFilePath!);
      }
    }

    // TEXT / JSON
    if (contentType != null &&
        (contentType!.startsWith('text/') ||
            contentType!.contains('application/json'))) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(String.fromCharCodes(fileBytes!)),
      );
    }

    // VIDEO
    if (contentType != null && contentType!.startsWith('video/')) {
      return SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: videoController!.value.aspectRatio,
              child: VideoPlayer(videoController!),
            ),
            VideoProgressIndicator(videoController!, allowScrubbing: true),
            IconButton(
              icon: Icon(
                videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  videoController!.value.isPlaying
                      ? videoController!.pause()
                      : videoController!.play();
                });
              },
            ),
          ],
        ),
      );
    }

    // AUDIO
    if (contentType != null && contentType!.startsWith('audio/')) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, size: 80),
            SizedBox(height: 12),
            Text('Playing audio...'),
          ],
        ),
      );
    }

    // WORD / OTHER
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 80),
          const SizedBox(height: 12),
          const Text(
            'Preview not supported.\nTap below to open or download.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Open / Download'),
            onPressed: _openOrDownload,
          ),
        ],
      ),
    );
  }
}
