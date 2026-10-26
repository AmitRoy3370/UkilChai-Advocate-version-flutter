// lib/Questions/screens/question_attachment_viewer.dart

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;

// ✅ For DOCX in-screen preview
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

// WEB ONLY
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class QuestionAttachmentViewer extends StatefulWidget {
  final String attachmentId;
  final String? jwtToken;

  const QuestionAttachmentViewer({
    super.key,
    required this.attachmentId,
    required this.jwtToken,
  });

  @override
  State<QuestionAttachmentViewer> createState() =>
      _QuestionAttachmentViewerState();
}

class _QuestionAttachmentViewerState extends State<QuestionAttachmentViewer> {
  Uint8List? fileBytes;
  String? contentType;
  String? tempFilePath;
  String? webUrl;

  VideoPlayerController? videoController;
  AudioPlayer? audioPlayer;

  // ✅ DOCX extracted text
  String? _docxText;

  // ✅ Audio state for UI
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _audioPlaying = false;

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

  // ============================================================
  // FILE EXTENSION FROM MIME
  // ============================================================
  String getFileExtension(String? mime) {
    if (mime == null) return '';

    if (mime.contains('pdf')) return '.pdf';
    if (mime == 'application/msword') return '.doc';
    if (mime.contains('wordprocessingml')) return '.docx';
    if (mime == 'application/vnd.ms-excel') return '.xls';
    if (mime.contains('spreadsheetml')) return '.xlsx';
    if (mime == 'application/vnd.ms-powerpoint') return '.ppt';
    if (mime.contains('presentationml')) return '.pptx';
    if (mime == 'text/plain') return '.txt';
    if (mime == 'text/csv') return '.csv';
    if (mime.contains('json')) return '.json';
    if (mime.contains('xml')) return '.xml';

    if (mime.startsWith('image/jpeg')) return '.jpg';
    if (mime.startsWith('image/jpg')) return '.jpg';
    if (mime.startsWith('image/png')) return '.png';
    if (mime.startsWith('image/gif')) return '.gif';
    if (mime.startsWith('image/webp')) return '.webp';
    if (mime.startsWith('image/bmp')) return '.bmp';
    if (mime.startsWith('image/heic')) return '.heic';
    if (mime.startsWith('image/heif')) return '.heif';
    if (mime.startsWith('image/svg')) return '.svg';
    if (mime.startsWith('image/tiff')) return '.tiff';

    if (mime.startsWith('video/mp4')) return '.mp4';
    if (mime.startsWith('video/quicktime')) return '.mov';
    if (mime.startsWith('video/x-msvideo')) return '.avi';
    if (mime.startsWith('video/webm')) return '.webm';
    if (mime.startsWith('video/x-matroska')) return '.mkv';
    if (mime.startsWith('video/3gpp')) return '.3gp';

    if (mime.startsWith('audio/mpeg')) return '.mp3';
    if (mime.startsWith('audio/wav') || mime.startsWith('audio/x-wav')) {
      return '.wav';
    }
    if (mime.startsWith('audio/ogg')) return '.ogg';
    if (mime.startsWith('audio/aac')) return '.aac';
    if (mime.startsWith('audio/m4a') || mime.startsWith('audio/x-m4a')) {
      return '.m4a';
    }
    if (mime.startsWith('audio/flac')) return '.flac';
    if (mime.startsWith('audio/webm')) return '.weba';

    return '';
  }

  // ============================================================
  // MAGIC BYTE DETECTION
  // ============================================================
  String? detectContentType(Uint8List bytes) {
    if (bytes.length < 12) return null;

    debugPrint('🔍 Detecting content-type from magic bytes...');
    debugPrint(
        '   First 16 bytes: ${bytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    // PNG
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      debugPrint('   ✅ Detected: PNG');
      return 'image/png';
    }

    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      debugPrint('   ✅ Detected: JPEG');
      return 'image/jpeg';
    }

    // GIF
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      debugPrint('   ✅ Detected: GIF');
      return 'image/gif';
    }

    // WEBP
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      debugPrint('   ✅ Detected: WEBP');
      return 'image/webp';
    }

    // BMP
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      debugPrint('   ✅ Detected: BMP');
      return 'image/bmp';
    }

    // TIFF
    if (bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A) {
      debugPrint('   ✅ Detected: TIFF');
      return 'image/tiff';
    }
    if (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00) {
      debugPrint('   ✅ Detected: TIFF');
      return 'image/tiff';
    }

    // PDF
    if (bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      debugPrint('   ✅ Detected: PDF');
      return 'application/pdf';
    }

    // OLE
    if (bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      debugPrint('   ✅ Detected: OLE');
      return 'application/msword';
    }

    // ZIP
    if (bytes[0] == 0x50 && bytes[1] == 0x4B) {
      debugPrint('   ✅ Detected: ZIP');
      return 'application/zip';
    }

    // ISO-BMFF
    if (String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      debugPrint('   ISO-BMFF brand: $brand');

      if (brand == 'heic' ||
          brand == 'heix' ||
          brand == 'heim' ||
          brand == 'heis' ||
          brand == 'hevc' ||
          brand == 'hevx') {
        debugPrint('   ✅ Detected: HEIC');
        return 'image/heic';
      }
      if (brand == 'mif1' || brand == 'msf1') {
        debugPrint('   ✅ Detected: HEIF');
        return 'image/heif';
      }
      if (brand == 'avif' || brand == 'avis') {
        debugPrint('   ✅ Detected: AVIF');
        return 'image/avif';
      }
      if (brand == 'qt  ') {
        debugPrint('   ✅ Detected: MOV');
        return 'video/quicktime';
      }
      if (brand == '3gp4' ||
          brand == '3gp5' ||
          brand == '3g2a' ||
          brand == '3g2b') {
        debugPrint('   ✅ Detected: 3GP');
        return 'video/3gpp';
      }
      if (brand == 'isom' ||
          brand == 'iso2' ||
          brand == 'iso4' ||
          brand == 'iso5' ||
          brand == 'iso6' ||
          brand == 'mp41' ||
          brand == 'mp42' ||
          brand == 'avc1' ||
          brand == 'M4V ' ||
          brand == 'M4VH' ||
          brand == 'M4VP' ||
          brand == 'dash' ||
          brand == 'f4v ') {
        debugPrint('   ✅ Detected: MP4');
        return 'video/mp4';
      }
      if (brand == 'M4A ' || brand == 'M4B ' || brand == 'M4P ') {
        debugPrint('   ✅ Detected: M4A');
        return 'audio/mp4';
      }
      debugPrint('   ⚠️ Unknown ISO-BMFF → defaulting to MP4');
      return 'video/mp4';
    }

    // WAV
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE') {
      debugPrint('   ✅ Detected: WAV');
      return 'audio/wav';
    }

    // AVI
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'AVI ') {
      debugPrint('   ✅ Detected: AVI');
      return 'video/x-msvideo';
    }

    // MP3 ID3
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      debugPrint('   ✅ Detected: MP3 (ID3)');
      return 'audio/mpeg';
    }

    // MP3 frame sync
    if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      if (!(bytes[1] == 0xD8)) {
        debugPrint('   ✅ Detected: MP3');
        return 'audio/mpeg';
      }
    }

    // AAC
    if (bytes[0] == 0xFF && (bytes[1] == 0xF1 || bytes[1] == 0xF9)) {
      debugPrint('   ✅ Detected: AAC');
      return 'audio/aac';
    }

    // OGG
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'OggS') {
      debugPrint('   ✅ Detected: OGG');
      return 'audio/ogg';
    }

    // FLAC
    if (bytes[0] == 0x66 &&
        bytes[1] == 0x4C &&
        bytes[2] == 0x61 &&
        bytes[3] == 0x43) {
      debugPrint('   ✅ Detected: FLAC');
      return 'audio/flac';
    }

    // WEBM/MKV
    if (bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      final searchLen = bytes.length > 100 ? 100 : bytes.length;
      final head = String.fromCharCodes(bytes.sublist(0, searchLen));
      if (head.contains('webm')) {
        debugPrint('   ✅ Detected: WEBM');
        return 'video/webm';
      }
      debugPrint('   ✅ Detected: MKV');
      return 'video/x-matroska';
    }

    debugPrint('   ❌ Could not detect');
    return null;
  }

  // ============================================================
  // DOCX → TEXT EXTRACTION
  // ============================================================
  String? _extractDocxText(Uint8List bytes) {
    try {
      debugPrint('📄 Extracting text from DOCX...');
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => throw Exception('document.xml not found'),
      );
      final xmlBytes = docXml.content as List<int>;
      final xmlContent = utf8.decode(xmlBytes);
      final document = XmlDocument.parse(xmlContent);
      final buffer = StringBuffer();
      var lastWasText = false;

      for (final p in document.findAllElements('w:p')) {
        for (final t in p.findAllElements('w:t')) {
          buffer.write(t.innerText);
          lastWasText = true;
        }
        if (lastWasText) {
          buffer.write('\n');
          lastWasText = false;
        }
      }

      var text = buffer.toString();
      text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
      if (text.trim().isEmpty) {
        return '(Document contains no readable text — may have images only)';
      }
      debugPrint('   ✅ Extracted ${text.length} chars');
      return text;
    } catch (e) {
      debugPrint('❌ DOCX parse error: $e');
      return null;
    }
  }

  // ============================================================
  // LOAD ATTACHMENT
  // ============================================================
  Future<void> loadAttachment() async {
    // ✅ Question attachment view URL
    final url = Uri.parse(
      '${BASE_URL.Urls().baseURL}questions/attachment/view/${widget.attachmentId}',
    );

    debugPrint('═══════════════════════════════════════════');
    debugPrint('📥 QUESTION ATTACHMENT LOAD');
    debugPrint('   ID: ${widget.attachmentId}');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.jwtToken}'},
      );

      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Header Content-Type: ${response.headers['content-type']}');
      debugPrint('   Body bytes: ${response.bodyBytes.length}');

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load attachment')),
          );
        }
        return;
      }

      fileBytes = response.bodyBytes;
      contentType = response.headers['content-type'];
      debugPrint('   contentType from header: $contentType');

      if (contentType == null ||
          contentType == 'application/octet-stream' ||
          contentType == 'application/x-www-form-urlencoded' ||
          contentType == 'binary/octet-stream') {
        debugPrint('   ⚠️ Generic/wrong content-type, detecting from bytes...');
        final detected = detectContentType(fileBytes!);
        if (detected != null) {
          contentType = detected;
          debugPrint('   ✅ Updated contentType: $contentType');
        } else {
          debugPrint('   ❌ Detection failed');
        }
      } else {
        debugPrint('   ✅ Header content-type OK: $contentType');
      }

      // ✅ Refine ZIP → DOCX
      if (contentType == 'application/zip' && fileBytes != null) {
        final docxText = _extractDocxText(fileBytes!);
        if (docxText != null) {
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          _docxText = docxText;
          debugPrint('   ✅ Detected as DOCX with text');
        }
      }

      if (contentType != null &&
          contentType!.contains('wordprocessingml') &&
          fileBytes != null) {
        _docxText = _extractDocxText(fileBytes!);
      }

      debugPrint('   FINAL contentType: $contentType');
      debugPrint('   isImage: ${contentType?.startsWith('image/')}');
      debugPrint('   isVideo: ${contentType?.startsWith('video/')}');
      debugPrint('   isAudio: ${contentType?.startsWith('audio/')}');
      debugPrint('═══════════════════════════════════════════');

      // WEB blob URL
      if (kIsWeb) {
        final blob = html.Blob(
          [fileBytes!],
          contentType ?? 'application/octet-stream',
        );
        webUrl = html.Url.createObjectUrlFromBlob(blob);
      }

      // MOBILE temp file
      final needsTempFile = !kIsWeb &&
          contentType != null &&
          (contentType!.contains('pdf') ||
              contentType!.startsWith('video/') ||
              contentType!.startsWith('audio/') ||
              contentType!.contains('word') ||
              contentType!.contains('excel') ||
              contentType!.contains('powerpoint') ||
              contentType!.contains('office') ||
              contentType!.contains('zip') ||
              contentType!.contains('ms'));

      if (needsTempFile) {
        try {
          final dir = await getTemporaryDirectory();
          final fileName =
              '${widget.attachmentId}${getFileExtension(contentType)}';
          tempFilePath = '${dir.path}/$fileName';
          await File(tempFilePath!).writeAsBytes(fileBytes!);
          debugPrint('   📁 Temp file saved: $tempFilePath');
        } catch (e) {
          debugPrint('   ❌ Temp file save failed: $e');
        }
      }

      // WEB PDF iframe — ✅ Unique viewType for Question
      if (kIsWeb && contentType != null && contentType!.contains('pdf')) {
        ui_web.platformViewRegistry.registerViewFactory(
          'question-pdf-${widget.attachmentId}',
          (int viewId) => html.IFrameElement()
            ..src = webUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%',
        );
      }

      // VIDEO
      if (contentType != null && contentType!.startsWith('video/')) {
        try {
          videoController = kIsWeb
              ? VideoPlayerController.networkUrl(Uri.parse(webUrl!))
              : VideoPlayerController.file(File(tempFilePath!));
          await videoController!.initialize();
          videoController!.addListener(() {
            if (mounted) setState(() {});
          });
          await videoController!.play();
          debugPrint('   ✅ Video controller initialized & playing');
        } catch (e) {
          debugPrint('   ❌ Video controller failed: $e');
        }
      }

      // AUDIO
      if (contentType != null && contentType!.startsWith('audio/')) {
        try {
          audioPlayer = AudioPlayer();

          audioPlayer!.onPositionChanged.listen((p) {
            if (mounted) setState(() => _audioPosition = p);
          });
          audioPlayer!.onDurationChanged.listen((d) {
            if (mounted) setState(() => _audioDuration = d);
          });
          audioPlayer!.onPlayerStateChanged.listen((state) {
            if (mounted) {
              setState(() => _audioPlaying = state == PlayerState.playing);
            }
          });

          if (kIsWeb) {
            await audioPlayer!.play(UrlSource(webUrl!));
          } else {
            await audioPlayer!.play(DeviceFileSource(tempFilePath!));
          }
          debugPrint('   ✅ Audio player started');
        } catch (e) {
          debugPrint('   ❌ Audio player failed: $e');
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Load error: $e');
    }
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================
  String _getExtensionFromContentType(String? contentType) {
    if (contentType == null) return ".bin";
    if (contentType.contains("pdf")) return ".pdf";
    if (contentType.contains("jpeg")) return ".jpeg";
    if (contentType.contains("jpg")) return ".jpg";
    if (contentType.contains("png")) return ".png";
    if (contentType.contains("gif")) return ".gif";
    if (contentType.contains("webp")) return ".webp";
    if (contentType.contains("heic")) return ".heic";
    if (contentType.contains("mp4")) return ".mp4";
    if (contentType.contains("quicktime")) return ".mov";
    if (contentType.contains("mp3")) return ".mp3";
    if (contentType.contains("wav")) return ".wav";
    if (contentType.contains("word")) return ".docx";
    if (contentType.contains("excel")) return ".xlsx";
    if (contentType.contains("powerpoint")) return ".pptx";
    if (contentType.contains("text")) return ".txt";
    return ".bin";
  }

  Future<void> _openOrDownload() async {
    try {
      // ✅ Question download URL
      final url =
          "${BASE_URL.Urls().baseURL}questions/downloadQuestionContentent?attachmentId=${widget.attachmentId}";

      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download failed")),
        );
        return;
      }

      String fileName = "attachment";
      final disposition = response.headers['content-disposition'];
      if (disposition != null) {
        final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
        if (match != null) fileName = match.group(1)!;
      }

      final ct = response.headers['content-type'] ?? "application/octet-stream";

      if (!fileName.contains(".")) {
        fileName += _getExtensionFromContentType(ct);
      }

      if (kIsWeb) {
        final blob = html.Blob([response.bodyBytes], ct);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: blobUrl)
          ..setAttribute("download", fileName)
          ..click();

        html.Url.revokeObjectUrl(blobUrl);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attachment error: $e")),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (fileBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // ═══════════════════════════════════════════════════════
    // IMAGE
    // ═══════════════════════════════════════════════════════
    if (contentType != null && contentType!.startsWith('image/')) {
      // HEIC/HEIF web fallback
      if (kIsWeb &&
          (contentType!.contains('heic') ||
              contentType!.contains('heif'))) {
        return _heicFallback();
      }

      // ✅ WebP on web → use native browser decoder
      if (kIsWeb && contentType!.contains('webp')) {
        return _buildWebImagePreview();
      }

      // Standard Flutter renderer for JPG/PNG/GIF/etc.
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.memory(
            fileBytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Image render error: $error');
              // Web fallback → native browser <img>
              if (kIsWeb && webUrl != null) {
                return _buildWebImagePreview();
              }
              return _imageErrorFallback();
            },
          ),
        ),
      );
    }

    // PDF
    if (contentType != null && contentType!.contains('pdf')) {
      if (kIsWeb) {
        return HtmlElementView(
            viewType: 'question-pdf-${widget.attachmentId}');
      } else {
        return PDFView(
          filePath: tempFilePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
        );
      }
    }

    // DOCX in-screen
    if (contentType != null &&
        contentType!.contains('wordprocessingml') &&
        _docxText != null) {
      return _buildDocxPreview(_docxText!);
    }

    // TEXT / JSON / CSV / XML
    if (contentType != null &&
        (contentType!.startsWith('text/') ||
            contentType!.contains('json') ||
            contentType!.contains('xml') ||
            contentType!.contains('csv'))) {
      return _buildTextPreview();
    }

    // VIDEO
    if (contentType != null && contentType!.startsWith('video/')) {
      return _buildVideoPlayer();
    }

    // AUDIO
    if (contentType != null && contentType!.startsWith('audio/')) {
      return _buildAudioPlayer();
    }

    // FALLBACK
    return _buildFallback();
  }

  // ============================================================
  // ✅ Web Image Preview (WebP via browser native decoder)
  // ============================================================
  Widget _buildWebImagePreview() {
    final viewType = 'question-img-${widget.attachmentId}';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final img = html.ImageElement()
          ..src = webUrl!
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = 'transparent';
        return img;
      },
    );

    return Container(
      color: Colors.black12,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }

  // ============================================================
  // DOCX Preview
  // ============================================================
  Widget _buildDocxPreview(String text) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description,
                      color: Color(0xFF6A1B9A), size: 16),
                  SizedBox(width: 8),
                  Text('Word Document (read-only)',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF6A1B9A))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              text,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEXT Preview
  // ============================================================
  Widget _buildTextPreview() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          String.fromCharCodes(fileBytes!),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO Player — full screen, no overflow
  // ============================================================
  Widget _buildVideoPlayer() {
    if (videoController == null || !videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final value = videoController!.value;

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: value.aspectRatio,
                  child: VideoPlayer(videoController!),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black87,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF6A1B9A),
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDuration(value.position),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 48,
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            value.isPlaying
                                ? videoController!.pause()
                                : videoController!.play();
                          });
                        },
                      ),
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.replay, color: Colors.white),
                        onPressed: () =>
                            videoController!.seekTo(Duration.zero),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatDuration(value.duration),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AUDIO Player
  // ============================================================
  Widget _buildAudioPlayer() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6A1B9A).withOpacity(0.1),
                      ),
                      child: const Icon(Icons.audiotrack,
                          size: 70, color: Color(0xFF6A1B9A)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Audio: ${contentType!.split('/').last.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 24),
                    Slider(
                      value: _audioDuration.inMilliseconds > 0
                          ? _audioPosition.inMilliseconds /
                              _audioDuration.inMilliseconds
                          : 0,
                      onChanged: (v) {
                        final ms =
                            (v * _audioDuration.inMilliseconds).round();
                        audioPlayer?.seek(Duration(milliseconds: ms));
                      },
                      activeColor: const Color(0xFF6A1B9A),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_audioPosition),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Text(_formatDuration(_audioDuration),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 40,
                          icon: const Icon(Icons.replay_10),
                          onPressed: () {
                            final newPos = _audioPosition -
                                const Duration(seconds: 10);
                            audioPlayer?.seek(newPos.isNegative
                                ? Duration.zero
                                : newPos);
                          },
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF6A1B9A),
                          ),
                          child: IconButton(
                            iconSize: 50,
                            icon: Icon(
                              _audioPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              if (_audioPlaying) {
                                await audioPlayer?.pause();
                              } else {
                                await audioPlayer?.resume();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          iconSize: 40,
                          icon: const Icon(Icons.forward_10),
                          onPressed: () {
                            final newPos = _audioPosition +
                                const Duration(seconds: 10);
                            audioPlayer?.seek(newPos);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // ============================================================
  // Fallback
  // ============================================================
  Widget _buildFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconForContentType(contentType),
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              _labelForContentType(contentType),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preview not supported.\nTap below to open or download.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Open / Download'),
              onPressed: _openOrDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEIC Fallback
  // ============================================================
  Widget _heicFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_iphone,
                size: 80, color: Color(0xFF6A1B9A)),
            const SizedBox(height: 16),
            const Text(
              'iPhone Photo (HEIC)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'HEIC format cannot be previewed in browser.\nPlease download to view.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download HEIC'),
              onPressed: _openOrDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Image Error Fallback
  // ============================================================
  Widget _imageErrorFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image,
                size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Unable to preview this image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Format: ${contentType ?? "unknown"}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              onPressed: _openOrDownload,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForContentType(String? ct) {
    if (ct == null) return Icons.insert_drive_file;
    if (ct.contains('word')) return Icons.description;
    if (ct.contains('excel') || ct.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    if (ct.contains('powerpoint') || ct.contains('presentation')) {
      return Icons.slideshow;
    }
    if (ct.contains('zip') || ct.contains('rar')) return Icons.archive;
    if (ct.contains('json')) return Icons.data_object;
    if (ct.contains('xml')) return Icons.code;
    return Icons.insert_drive_file;
  }

  String _labelForContentType(String? ct) {
    if (ct == null) return 'Unknown File';
    if (ct.contains('word')) return 'Word Document';
    if (ct.contains('excel') || ct.contains('spreadsheet')) {
      return 'Excel Spreadsheet';
    }
    if (ct.contains('powerpoint') || ct.contains('presentation')) {
      return 'PowerPoint Presentation';
    }
    if (ct.contains('zip')) return 'ZIP Archive';
    return 'Document';
  }
}