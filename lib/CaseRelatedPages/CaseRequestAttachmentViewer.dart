import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Mobile PDF
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:ui_web'
    as ui_web; // Add this import for platformViewRegistry on web
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Web & Mobile PDF
import 'package:open_file/open_file.dart'; // Add this for opening files on mobile
import '../Utils/BaseURL.dart' as BASE_URL;

class CaseRequestAttachmentViewer extends StatefulWidget {
  final String attachmentId;
  final String jwtToken;

  const CaseRequestAttachmentViewer({
    super.key,
    required this.attachmentId,
    required this.jwtToken,
  });

  @override
  State<CaseRequestAttachmentViewer> createState() =>
      _CaseRequestAttachmentViewState();
}

class _CaseRequestAttachmentViewState
    extends State<CaseRequestAttachmentViewer> {
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

  String getFileExtension(String? mime) {
    if (mime == null) return '';
    if (mime.contains('pdf')) return '.pdf';
    if (mime.startsWith('image/jpeg')) return '.jpg';
    if (mime.startsWith('image/png')) return '.png';
    if (mime.startsWith('video/mp4')) return '.mp4';
    if (mime.startsWith('audio/mpeg')) return '.mp3';
    if (mime.startsWith('audio/wav')) return '.wav';
    if (mime.startsWith('audio/ogg')) return '.ogg';
    if (mime == 'application/msword') return '.doc';
    if (mime ==
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      return '.docx';
    return '';
  }

  Future<void> loadAttachment() async {
    final url = Uri.parse(
      '${BASE_URL.Urls().baseURL}case-request/attachment/view/${widget.attachmentId}',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.jwtToken}'},
    );

    if (response.statusCode == 200) {
      fileBytes = response.bodyBytes;
      contentType = response.headers['content-type'];

      // Fallback detection if contentType is missing or generic
      if (contentType == null ||
          contentType == 'application/octet-stream' ||
          contentType == 'application/x-www-form-urlencoded') {
        final detected = detectContentType(fileBytes!);
        if (detected != null) {
          contentType = detected;
        }
      }

      // Create blob URL for web (all types)
      if (kIsWeb) {
        final blob = html.Blob([
          fileBytes!,
        ], contentType ?? 'application/octet-stream');
        webUrl = html.Url.createObjectUrlFromBlob(blob);
      }

      // Save temp file ONLY for Mobile if needed (pdf / video / audio / word)
      if (!kIsWeb &&
          contentType != null &&
          (contentType!.contains('pdf') ||
              contentType!.startsWith('video/') ||
              contentType!.startsWith('audio/') ||
              contentType! == 'application/msword' ||
              contentType! ==
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document')) {
        final dir = await getTemporaryDirectory();
        String fileName = widget.attachmentId.replaceAll(
          RegExp(r"[^\w\-_\.]"),
          "_",
        );
        fileName += getFileExtension(contentType);
        tempFilePath = '${dir.path}/$fileName';
        await File(tempFilePath!).writeAsBytes(fileBytes!);
      }

      // Register iframe for web PDF (fallback if Syncfusion blanks)
      if (kIsWeb && contentType != null && contentType!.contains('pdf')) {
        ui_web.platformViewRegistry.registerViewFactory(
          'pdf-viewer-${widget.attachmentId}',
          (int viewId) => html.IFrameElement()
            ..src = webUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%',
        );
      }

      // Init video
      if (contentType != null && contentType!.startsWith('video/')) {
        if (kIsWeb) {
          videoController = VideoPlayerController.network(webUrl!);
        } else {
          videoController = VideoPlayerController.file(File(tempFilePath!));
        }
        await videoController!.initialize();
        videoController!.setLooping(true); // Optional
      }

      // Init audio with auto-play
      if (contentType != null && contentType!.startsWith('audio/')) {
        audioPlayer = AudioPlayer();
        if (kIsWeb) {
          await audioPlayer!.play(UrlSource(webUrl!));
        } else {
          await audioPlayer!.play(DeviceFileSource(tempFilePath!));
        }
      }

      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load attachment')),
      );
    }
  }

  Future<void> _openOrDownload() async {
    if (kIsWeb) {
      // Download on web
      final blob = html.Blob([fileBytes!], contentType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "document${getFileExtension(contentType)}")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Open with external app on mobile
      final result = await OpenFile.open(tempFilePath!);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fileBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 🖼 IMAGE
    if (contentType != null && contentType!.startsWith('image/')) {
      return InteractiveViewer(child: Image.memory(fileBytes!));
    }

    // 📄 PDF
    if (contentType != null && contentType!.contains('pdf')) {
      if (kIsWeb) {
        // Use iframe for reliable web PDF rendering
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: HtmlElementView(viewType: 'pdf-viewer-${widget.attachmentId}'),
        );
        // Alternative: SfPdfViewer.network(webUrl!); // If iframe not preferred, but may cause blank
      } else {
        return PDFView(
          filePath: tempFilePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: false,
        );
      }
    }

    // 📝 TEXT / JSON / CSV
    if (contentType != null &&
        (contentType!.startsWith('text/') ||
            contentType!.contains('application/json'))) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(String.fromCharCodes(fileBytes!)),
      );
    }

    // 🎥 VIDEO
    if (contentType != null && contentType!.startsWith('video/')) {
      return Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: videoController!.value.aspectRatio,
              child: VideoPlayer(videoController!),
            ),
          ),
          VideoProgressIndicator(videoController!, allowScrubbing: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
        ],
      );
    }

    // 🔊 AUDIO
    if (contentType != null && contentType!.startsWith('audio/')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audiotrack, size: 80),
            const SizedBox(height: 12),
            const Text('Playing audio...'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () => audioPlayer?.pause(),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => audioPlayer?.resume(),
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () => audioPlayer?.stop(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // WORD DOCUMENT
    if (contentType == 'application/msword' ||
        contentType ==
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 80),
            const SizedBox(height: 12),
            const Text(
              'Word document preview is not supported inside the app.\nTap below to open externally.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Document'),
              onPressed: _openOrDownload,
            ),
          ],
        ),
      );
    }

    // ❌ OTHER FILE TYPES
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 80),
          const SizedBox(height: 12),
          const Text(
            'Preview not supported for this file type.\nTap below to download/open.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download/Open File'),
            onPressed: _openOrDownload,
          ),
        ],
      ),
    );
  }
}
