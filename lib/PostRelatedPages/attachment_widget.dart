// ========== attachment_widget.dart ==========
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

// WEB ONLY
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class AttachmentWidget extends StatefulWidget {
  final String attachmentId;
  final double height;
  final Function(String) onViewAttachment;

  const AttachmentWidget({
    super.key,
    required this.attachmentId,
    this.height = 260,
    required this.onViewAttachment,
  });

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  static final Map<String, _AttachmentCache> _cache = {};

  // ✅ Track registered view types globally so we never double-register
  static final Set<String> _registeredViewTypes = {};

  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasError = false;
  Uint8List? _fileBytes;
  String? _contentType;
  bool _isImageOrVideo = false;
  String? _webUrl;

  // ✅ Stable unique viewType per widget (computed once in initState)
  late final String _webImgViewType;
  late final String _webVideoViewType;

  @override
  void initState() {
    super.initState();

    // ✅ Compute stable view types using the widget's hashcode + attachmentId
    // This ensures two widgets with the same attachmentId in different
    // screens don't collide, AND it stays stable across rebuilds.
    final uniqueSuffix = '${widget.attachmentId}_${identityHashCode(this)}';
    _webImgViewType = 'post-thumb-img-$uniqueSuffix';
    _webVideoViewType = 'post-thumb-video-$uniqueSuffix';

    _initialize();
  }

  @override
  void dispose() {
    if (kIsWeb && _webUrl != null) {
      html.Url.revokeObjectUrl(_webUrl!);
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    final cached = _cache[widget.attachmentId];
    if (cached != null) {
      if (mounted) {
        setState(() {
          _fileBytes = cached.fileBytes;
          _contentType = cached.contentType;
          _isImageOrVideo = cached.isImageOrVideo;
          _isLoaded = true;
          _isLoading = false;
          _hasError = false;
        });
      }
      if (kIsWeb) _createWebUrl();
      return;
    }
    await _loadAttachment();
  }

  void _createWebUrl() {
    if (kIsWeb && _fileBytes != null && _contentType != null) {
      final blob = html.Blob([_fileBytes!], _contentType!);
      _webUrl = html.Url.createObjectUrlFromBlob(blob);
    }
  }

  Future<void> _loadAttachment() async {
    if (_isLoading || _isLoaded) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final url = Uri.parse(
        '${BASE_URL.Urls().baseURL}advocate/posts/attachment/view/${widget.attachmentId}',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _fileBytes = response.bodyBytes;
        _contentType = response.headers['content-type'];

        if (_contentType == null ||
            _contentType == 'application/octet-stream' ||
            _contentType == 'application/x-www-form-urlencoded' ||
            _contentType == 'binary/octet-stream') {
          final detected = _detectContentType(_fileBytes!);
          if (detected != null) {
            _contentType = detected;
          }
        }

        _isImageOrVideo = _contentType != null &&
            (_contentType!.startsWith('image/') ||
                _contentType!.startsWith('video/'));

        if (kIsWeb) _createWebUrl();

        _cache[widget.attachmentId] = _AttachmentCache(
          fileBytes: _fileBytes!,
          contentType: _contentType ?? 'application/octet-stream',
          isImageOrVideo: _isImageOrVideo,
        );

        setState(() {
          _isLoaded = true;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoaded = true;
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load attachment: $e');
      if (mounted) {
        setState(() {
          _isLoaded = true;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  String? _detectContentType(Uint8List bytes) {
    if (bytes.length < 12) return null;

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
      return 'image/png';
    }

    // JPEG
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // GIF
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }

    // WEBP
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }

    // BMP
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }

    // TIFF
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A) {
      return 'image/tiff';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00) {
      return 'image/tiff';
    }

    // PDF
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'application/pdf';
    }

    // ISO-BMFF
    if (bytes.length >= 8 &&
        String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      if (brand == 'heic' || brand == 'heix' || brand == 'heim' ||
          brand == 'heis' || brand == 'hevc' || brand == 'hevx') {
        return 'image/heic';
      }
      if (brand == 'mif1' || brand == 'msf1') return 'image/heif';
      if (brand == 'avif' || brand == 'avis') return 'image/avif';
      if (brand == 'qt  ') return 'video/quicktime';
      if (brand == '3gp4' || brand == '3gp5' ||
          brand == '3g2a' || brand == '3g2b') {
        return 'video/3gpp';
      }
      if (brand == 'M4A ' || brand == 'M4B ' || brand == 'M4P ') {
        return 'audio/mp4';
      }
      return 'video/mp4';
    }

    // WAV
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE') {
      return 'audio/wav';
    }

    // AVI
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'AVI ') {
      return 'video/x-msvideo';
    }

    // MP3 ID3
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      return 'audio/mpeg';
    }

    // MP3 frame sync
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      if (bytes[1] != 0xD8) return 'audio/mpeg';
    }

    // OGG
    if (bytes.length >= 4 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'OggS') {
      return 'audio/ogg';
    }

    // FLAC
    if (bytes.length >= 4 &&
        bytes[0] == 0x66 && bytes[1] == 0x4C &&
        bytes[2] == 0x61 && bytes[3] == 0x43) {
      return 'audio/flac';
    }

    // MKV/WEBM
    if (bytes.length >= 4 &&
        bytes[0] == 0x1A && bytes[1] == 0x45 &&
        bytes[2] == 0xDF && bytes[3] == 0xA3) {
      final searchLen = bytes.length > 100 ? 100 : bytes.length;
      final head = String.fromCharCodes(bytes.sublist(0, searchLen));
      if (head.contains('webm')) return 'video/webm';
      return 'video/x-matroska';
    }

    return null;
  }

  Future<Size> _getImageSize(Uint8List bytes) async {
    final imageInfo = await decodeImageFromList(bytes);
    return Size(imageInfo.width.toDouble(), imageInfo.height.toDouble());
  }

  // ============================================================
  // ✅ Register platform view factory ONLY ONCE per viewType
  // ============================================================
  void _ensureImageFactoryRegistered() {
    if (!kIsWeb) return;
    if (_registeredViewTypes.contains(_webImgViewType)) return;

    ui_web.platformViewRegistry.registerViewFactory(
      _webImgViewType,
      (int viewId) {
        final img = html.ImageElement()
          ..src = _webUrl ?? ''
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = 'transparent';
        return img;
      },
    );
    _registeredViewTypes.add(_webImgViewType);
  }

  void _ensureVideoFactoryRegistered() {
    if (!kIsWeb) return;
    if (_registeredViewTypes.contains(_webVideoViewType)) return;

    ui_web.platformViewRegistry.registerViewFactory(
      _webVideoViewType,
      (int viewId) {
        final video = html.VideoElement()
          ..src = _webUrl ?? ''
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = 'black'
          ..controls = false
          ..muted = true
          ..autoplay = false;
        video.load();
        return video;
      },
    );
    _registeredViewTypes.add(_webVideoViewType);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0) {
          return const SizedBox.shrink();
        }

        if (_isLoading) {
          return _buildLoadingWidget();
        }

        if (_hasError) {
          return _buildErrorWidget();
        }

        // ✅ Wrap in RepaintBoundary to prevent parent setState from
        // causing the platform view to re-render / blink.
        return RepaintBoundary(
          child: Column(
            children: [
              _buildHangingString(),
              if (_isLoaded && _isImageOrVideo && _fileBytes != null) ...[
                if (_contentType != null &&
                    _contentType!.startsWith('image/'))
                  _buildImageWidget(),
                if (_contentType != null &&
                    _contentType!.startsWith('video/'))
                  _buildVideoWidget(),
              ],
              if (_isLoaded && !_isImageOrVideo)
                _buildOtherAttachmentWidget(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHangingString() {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 14,
          color: Colors.grey.shade400,
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return GestureDetector(
      onTap: _loadAttachment,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text('Failed to load',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(height: 4),
              Text('Tap to retry',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE
  // ============================================================
  Widget _buildImageWidget() {
    if (kIsWeb && _webUrl != null) {
      return _buildWebImageWidget();
    }

    return FutureBuilder<Size>(
      future: _getImageSize(_fileBytes!),
      builder: (context, snapshot) {
        double aspectRatio = 16 / 9;
        if (snapshot.hasData && snapshot.data!.height > 0) {
          aspectRatio = snapshot.data!.width / snapshot.data!.height;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => widget.onViewAttachment(widget.attachmentId),
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Image.memory(
                  _fileBytes!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.blue[50],
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey, size: 40),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Web image — register factory ONCE, use stable HtmlElementView
  Widget _buildWebImageWidget() {
    _ensureImageFactoryRegistered();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => widget.onViewAttachment(widget.attachmentId),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            // ✅ Stable key prevents HtmlElementView from being recreated
            child: HtmlElementView(
              key: ValueKey(_webImgViewType),
              viewType: _webImgViewType,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO
  // ============================================================
  Widget _buildVideoWidget() {
    if (kIsWeb && _webUrl != null) {
      return _buildWebVideoWidget();
    }

    return FutureBuilder<Size>(
      future: _getImageSize(_fileBytes!),
      builder: (context, snapshot) {
        double aspectRatio = 16 / 9;
        if (snapshot.hasData && snapshot.data!.height > 0) {
          aspectRatio = snapshot.data!.width / snapshot.data!.height;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => widget.onViewAttachment(widget.attachmentId),
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _fileBytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.blue[50],
                              child: const Center(
                                child: Icon(Icons.video_library,
                                    color: Colors.grey, size: 40),
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4)
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    spreadRadius: 1)
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.black, size: 44),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Play',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Web video — register factory ONCE, use stable HtmlElementView
  Widget _buildWebVideoWidget() {
    _ensureVideoFactoryRegistered();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => widget.onViewAttachment(widget.attachmentId),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ✅ Stable key prevents HtmlElementView from being recreated
                  HtmlElementView(
                    key: ValueKey(_webVideoViewType),
                    viewType: _webVideoViewType,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4)
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 1)
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.black, size: 44),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Play',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherAttachmentWidget() {
    IconData icon;
    String label;
    Color color;

    if (_contentType != null) {
      if (_contentType!.contains('pdf')) {
        icon = Icons.picture_as_pdf_rounded;
        label = 'PDF Document';
        color = Colors.red.shade600;
      } else if (_contentType!.startsWith('audio/')) {
        icon = Icons.music_note_rounded;
        label = 'Audio File';
        color = Colors.teal.shade600;
      } else if (_contentType!.contains('word') ||
          _contentType!.contains('document')) {
        icon = Icons.description_rounded;
        label = 'Document';
        color = Colors.blue.shade600;
      } else {
        icon = Icons.get_app_rounded;
        label = 'Attachment File';
        color = Colors.indigo.shade600;
      }
    } else {
      icon = Icons.attach_file_rounded;
      label = 'Attachment';
      color = Colors.grey.shade700;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onViewAttachment(widget.attachmentId),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view file',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }
}

class _AttachmentCache {
  final Uint8List fileBytes;
  final String contentType;
  final bool isImageOrVideo;

  _AttachmentCache({
    required this.fileBytes,
    required this.contentType,
    required this.isImageOrVideo,
  });
}