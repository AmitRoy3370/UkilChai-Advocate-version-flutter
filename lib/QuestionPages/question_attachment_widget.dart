// ========== question_attachment_widget.dart ==========
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class QuestionAttachmentWidget extends StatefulWidget {
  final String attachmentId;
  final double height;
  final Function(String) onViewAttachment;

  const QuestionAttachmentWidget({
    super.key,
    required this.attachmentId,
    this.height = 260, // ফেসবুক/ইনস্টাগ্রাম লুকের জন্য ব্যাকআপ হাইট
    required this.onViewAttachment,
  });

  @override
  State<QuestionAttachmentWidget> createState() => _QuestionAttachmentWidgetState();
}

class _QuestionAttachmentWidgetState extends State<QuestionAttachmentWidget> {
  static final Map<String, _AttachmentCache> _cache = {};

  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasError = false;
  Uint8List? _fileBytes;
  String? _contentType;
  bool _isImageOrVideo = false;

  @override
  void initState() {
    super.initState();
    _initialize();
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
      return;
    }
    await _loadAttachment();
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
        '${BASE_URL.Urls().baseURL}questions/attachment/view/${widget.attachmentId}',
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
            _contentType == 'application/x-www-form-urlencoded') {
          final detected = _detectContentType(_fileBytes!);
          if (detected != null) {
            _contentType = detected;
          }
        }

        _isImageOrVideo = _contentType != null &&
            (_contentType!.startsWith('image/') ||
                _contentType!.startsWith('video/'));

        _cache[widget.attachmentId] = _AttachmentCache(
          fileBytes: _fileBytes!,
          contentType: _contentType!,
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
      print('Failed to load attachment: $e');
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
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    return null;
  }

  // ========== ইমেজের রিয়েল উইডথ এবং হাইট বের করার হেল্পার ফাংশন ==========
  Future<Size> _getImageSize(Uint8List bytes) async {
    final imageInfo = await decodeImageFromList(bytes);
    return Size(imageInfo.width.toDouble(), imageInfo.height.toDouble());
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

        return Column(
          children: [
            _buildHangingString(), // দেয়ালের ঝুলন্ত দড়ি ও হুক ডিজাইন
            if (_isLoaded && _isImageOrVideo && _fileBytes != null) ...[
              if (_contentType != null && _contentType!.startsWith('image/'))
                _buildImageWidget(),
              if (_contentType != null && _contentType!.startsWith('video/'))
                _buildVideoWidget(),
            ],
            if (_isLoaded && !_isImageOrVideo) _buildOtherAttachmentWidget(),
          ],
        );
      },
    );
  }

  // ========== ঝুলন্ত দড়ি এবং হুক (Hanging String Concept) ==========
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
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue, width: 1),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text('Failed to load', style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(height: 4),
              Text('Tap to retry', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // ========== 🔥 আকর্ষণীয় ডাইনামিক ইমেজ ফ্রেম উইজেট ==========
  Widget _buildImageWidget() {
    return FutureBuilder<Size>(
      future: _getImageSize(_fileBytes!),
      builder: (context, snapshot) {
        double aspectRatio = 16 / 9;
        if (snapshot.hasData && snapshot.data!.height > 0) {
          aspectRatio = snapshot.data!.width / snapshot.data!.height;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2), // উডেন ফ্রেমের থিকনেস
          decoration: BoxDecoration(
            color: Colors.blue[50], 
            borderRadius: BorderRadius.circular(2), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5), 
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              widget.onViewAttachment(widget.attachmentId);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1), // ইনার ফ্রেম বর্ডার ফিক্সড
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio, 
                child: Image.memory(
                  _fileBytes!,
                  fit: BoxFit.contain, 
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.blue[50],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
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

  // ========== 🔥 আকর্ষণীয় ভিডিও ফ্রেম উইজেট ==========
  Widget _buildVideoWidget() {
    return FutureBuilder<Size>(
      future: _getImageSize(_fileBytes!),
      builder: (context, snapshot) {
        double aspectRatio = 16 / 9;
        if (snapshot.hasData && snapshot.data!.height > 0) {
          aspectRatio = snapshot.data!.width / snapshot.data!.height;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50], // ✅ FIXED: Removed 'const'
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              widget.onViewAttachment(widget.attachmentId);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio, 
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1),
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
                              color: Colors.blue,
                              child: const Center(
                                child: Icon(Icons.video_library, color: Colors.grey, size: 40),
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1)
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 44),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Play', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

  // ========== অন্যান্য অ্যাটাচমেন্ট (যেমন: Audio / PDF ফাইল ফ্রেম) ==========
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
      } else if (_contentType!.contains('word') || _contentType!.contains('document')) {
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view file',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
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