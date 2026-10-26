// lib/CaseRelatedPages/document_draft_details_page.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/BaseURL.dart' as BASE_URL;
import '../Utils/responsive_helper.dart';
import 'document_draft.dart';
import 'document_draft_service.dart';
import 'DocumentDraftAttachmentViewer.dart';

class DocumentDraftDetailsPage extends StatefulWidget {
  final DocumentDraftResponse draft;
  final String token;
  final String? advocateUserId;
  final String? advocateId;

  const DocumentDraftDetailsPage({
    super.key,
    required this.draft,
    required this.token,
    this.advocateUserId,
    this.advocateId,
  });

  @override
  State<DocumentDraftDetailsPage> createState() =>
      _DocumentDraftDetailsPageState();
}

class _DocumentDraftDetailsPageState
    extends State<DocumentDraftDetailsPage> {
  late DocumentDraftResponse _draft;

  bool _isAdvocate = false;
  bool _isUploading = false;

  List<PlatformFile> _newFiles = [];
  List<String> _existingAttachments = [];
  Set<String> _attachmentsToDelete = {};

  // ────────────────────────────────────────────────────────────
  // Debug helpers
  // ────────────────────────────────────────────────────────────
  void _dbg(String msg) {
    debugPrint('🟥 DRAFT-DBG | $msg');
  }

  String _maskToken(String? t) {
    if (t == null) return 'null';
    if (t.isEmpty) return '(empty)';
    if (t.length <= 12) return '$t (len=${t.length})';
    return '${t.substring(0, 8)}...${t.substring(t.length - 4)} '
        '(len=${t.length})';
  }

  void _inspectJwt(String? token) {
    if (token == null || token.isEmpty) {
      _dbg('JWT inspect: token is empty');
      return;
    }

    final parts = token.split('.');
    _dbg('JWT inspect: parts=${parts.length} len=${token.length}');
    if (parts.length != 3) {
      _dbg('❌ JWT inspect: malformed token '
          '(expected 3 parts, got ${parts.length})');
      return;
    }

    try {
      final headerJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[0])),
      );
      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final header = jsonDecode(headerJson) as Map<String, dynamic>;
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      _dbg('JWT header  = $header');
      _dbg('JWT payload = $payload');

      final alg = header['alg']?.toString();
      if (alg != null) {
        _dbg('JWT alg=$alg');
        if (alg.toLowerCase() == 'none') {
          _dbg('❌ JWT alg is "none" → unsigned token → backend rejects');
        }
      }

      final exp = payload['exp'];
      if (exp is int) {
        final expMs = exp * 1000;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final remainingSec = (expMs - nowMs) ~/ 1000;
        _dbg('JWT exp=$exp (${DateTime.fromMillisecondsSinceEpoch(expMs)})');
        if (remainingSec < 0) {
          _dbg('❌ JWT expired ${-remainingSec}s ago');
        } else {
          _dbg('JWT valid for ${remainingSec}s more');
        }
      } else {
        _dbg('JWT has no "exp" claim');
      }

      _dbg('JWT sub=${payload['sub']}');
      _dbg('JWT iat=${payload['iat']}');
      _dbg('JWT iss=${payload['iss']}');
      _dbg('JWT userId=${payload['userId']} '
          'advocateId=${payload['advocateId']} '
          'role=${payload['role'] ?? payload['roles']}');
    } catch (e) {
      _dbg('❌ JWT inspect: failed to decode → $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _existingAttachments = List.from(_draft.attachmentsId);

    _dbg('================ initState ================');
    _dbg('draftId=${_draft.id}');
    _dbg('caseId=${_draft.caseId}');
    _dbg('draft.advocateId=${_draft.advocateId}');
    _dbg('draft.documentDraftedCase?.advocateId='
        '${_draft.documentDraftedCase?.advocateId}');
    _dbg('widget.advocateId=${widget.advocateId}');
    _dbg('widget.advocateUserId=${widget.advocateUserId}');
    _dbg('widget.token=${_maskToken(widget.token)}');
    _dbg('attachments count=${_existingAttachments.length}');
    _dbg('isWeb=$kIsWeb');
    _dbg('===========================================');

    _inspectJwt(widget.token);
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    final myAdvocateId = prefs.getString('advocateId');
    final myUserId = prefs.getString('userId');
    final myToken = prefs.getString('jwt_token');

    final draftAdvocateId =
        widget.advocateId ?? _draft.documentDraftedCase?.advocateId;

    _dbg('---- _checkOwnership ----');
    _dbg('prefs.advocateId=$myAdvocateId');
    _dbg('prefs.userId=$myUserId');
    _dbg('prefs.jwt_token=${_maskToken(myToken)}');
    _dbg('draftAdvocateId (resolved)=$draftAdvocateId');
    _dbg('widget.token matched prefs?=${widget.token == myToken}');
    _dbg('matches advocate?='
        '${myAdvocateId != null && draftAdvocateId != null && myAdvocateId == draftAdvocateId}');

    if (!mounted) return;
    setState(() {
      _isAdvocate = myAdvocateId != null &&
          draftAdvocateId != null &&
          myAdvocateId == draftAdvocateId;
    });
  }

  Future<DocumentDraftService> _freshService() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsToken = prefs.getString('jwt_token');

    String usedToken = widget.token;
    if (prefsToken != null && prefsToken.isNotEmpty) {
      usedToken = prefsToken;
    }

    _dbg('_freshService: prefsToken=${_maskToken(prefsToken)}, '
        'widgetToken=${_maskToken(widget.token)}, '
        'using=${_maskToken(usedToken)}');

    if (usedToken.isEmpty) {
      throw Exception("No JWT token — please log in again");
    }

    return DocumentDraftService(usedToken);
  }

  Future<String?> _resolveUserId() async {
    if (widget.advocateUserId != null && widget.advocateUserId!.isNotEmpty) {
      _dbg('_resolveUserId → widget.advocateUserId=${widget.advocateUserId}');
      return widget.advocateUserId;
    }

    final draftAdvocateId = _draft.documentDraftedCase?.advocateId
        ?? widget.advocateId
        ?? _draft.advocateId;

    if (draftAdvocateId.isNotEmpty) {
      try {
        _dbg('_resolveUserId → fetching /advocate/$draftAdvocateId …');

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token') ?? widget.token;

        final res = await http.get(
          Uri.parse(
            "${BASE_URL.Urls().baseURL}advocate/$draftAdvocateId",
          ),
          headers: {
            "content-type": "application/json",
            "Authorization": "Bearer $token",
          },
        );

        _dbg('_resolveUserId → /advocate status=${res.statusCode}');

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['userId'] != null) {
            final resolved = body['userId'].toString();
            if (resolved.isNotEmpty) {
              _dbg('_resolveUserId → resolved from backend=$resolved');
              return resolved;
            }
          }
        }
      } catch (e) {
        _dbg('_resolveUserId → backend fallback failed: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('userId');
    _dbg('_resolveUserId → prefs.userId=$stored '
        '(widget.advocateUserId was null/empty and backend fallback failed)');
    return stored;
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)} ${_monthShort(d.month)} ${d.year}, "
        "${two(d.hour)}:${two(d.minute)}";
  }

  String _monthShort(int m) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  // ────────────────────────────────────────────────────────────
  // Pre-flight validation
  // ────────────────────────────────────────────────────────────
  Future<({String token, String userId})?> _preflight({
    required String opLabel,
  }) async {
    _dbg('---- PRE-FLIGHT ($opLabel) ----');

    String token;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('jwt_token') ?? widget.token;
    } catch (_) {
      token = widget.token;
    }
    if (token.isEmpty) {
      _dbg('❌ preflight: token is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired — please log in again"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    _inspectJwt(token);

    final userId = await _resolveUserId();
    if (userId == null || userId.isEmpty) {
      _dbg('❌ preflight: userId is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot identify your user account — "
                "please log in again"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    final draftAdvocateId = _draft.documentDraftedCase?.advocateId
        ?? widget.advocateId
        ?? _draft.advocateId;
    final prefs = await SharedPreferences.getInstance();
    final myAdvocateId = prefs.getString('advocateId');

    if (myAdvocateId == null || myAdvocateId != draftAdvocateId) {
      _dbg('❌ preflight: not the advocate '
          '(my=$myAdvocateId, draft=$draftAdvocateId)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Only the case's advocate can modify this draft.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    _dbg('✅ preflight OK: token=${_maskToken(token)}, userId=$userId');
    return (token: token, userId: userId);
  }

  // ────────────────────────────────────────────────────────────
  // Pick new files — WEB ONLY
  // ────────────────────────────────────────────────────────────
  Future<void> _pickNewFilesWebOnly(StateSetter setDialogState) async {
    if (!kIsWeb) {
      _dbg('_pickNewFilesWebOnly called on non-Web — ignoring');
      return;
    }
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // must be true on Web to populate `bytes`
    );
    if (res == null || res.files.isEmpty) return;
    setDialogState(() {
      _newFiles.addAll(
        res.files.where((f) => f.bytes != null && f.bytes!.isNotEmpty),
      );
    });
    _dbg('Picked ${_newFiles.length} web file(s): '
        '${_newFiles.map((f) => f.name).toList()}');
  }

  // ────────────────────────────────────────────────────────────
  // Edit
  // ────────────────────────────────────────────────────────────
  Future<void> _openEditDialog() async {
    _newFiles = [];
    _existingAttachments = List.from(_draft.attachmentsId);
    _attachmentsToDelete = {};

    DateTime selectedDate = _draft.issuedDate;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Document Draft"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Date: ${_formatDate(selectedDate)}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text("Pick"),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                selectedDate.hour,
                                selectedDate.minute,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_existingAttachments.isNotEmpty) ...[
                    const Text(
                      "Existing attachments:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ..._existingAttachments.map((attId) {
                      final willDelete =
                          _attachmentsToDelete.contains(attId);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          willDelete
                              ? Icons.delete_forever
                              : Icons.attach_file,
                          color: willDelete ? Colors.red : Colors.blue,
                        ),
                        title: Text(
                          attId,
                          style: TextStyle(
                            decoration: willDelete
                                ? TextDecoration.lineThrough
                                : null,
                            color: willDelete ? Colors.red : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            willDelete
                                ? Icons.restore
                                : Icons.delete_outline,
                            color: willDelete
                                ? Colors.green
                                : Colors.red,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              if (willDelete) {
                                _attachmentsToDelete.remove(attId);
                              } else {
                                _attachmentsToDelete.add(attId);
                              }
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  if (_newFiles.isNotEmpty) ...[
                    const Text(
                      "New attachments:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ..._newFiles.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final f = entry.value;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                        ),
                        title: Text(f.name),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setDialogState(
                                () => _newFiles.removeAt(idx));
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // ────────────────────────────────────────────
                  // File picker — Web ONLY
                  // ────────────────────────────────────────────
                  if (kIsWeb)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Add new files"),
                      onPressed: () => _pickNewFilesWebOnly(setDialogState),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Adding new attachments is only supported on Web.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isUploading ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () async {
                        setDialogState(() => _isUploading = true);
                        try {
                          final pf = await _preflight(opLabel: 'update');
                          if (pf == null) {
                            setDialogState(() => _isUploading = false);
                            return;
                          }

                          final prefs = await SharedPreferences.getInstance();
                          final presentUserId = prefs.getString("userId");

                          final filteredExisting = _existingAttachments
                              .where((id) =>
                                  !_attachmentsToDelete.contains(id))
                              .toList();

                          _dbg('========== UPDATE REQUEST ==========');
                          _dbg('draftId=${_draft.id}');
                          _dbg('caseId=${_draft.caseId}');
                          _dbg('draft.advocateId=${_draft.advocateId}');
                          _dbg('userId (sent as ?userId=)=${pf.userId}');
                          _dbg('token=${_maskToken(pf.token)}');
                          _dbg('selectedDate=$selectedDate');
                          _dbg('existingFiles count=${filteredExisting.length}');
                          _dbg('existingFiles=$filteredExisting');
                          _dbg('newFiles count=${_newFiles.length}');
                          _dbg(
                              'URL=${BASE_URL.Urls().baseURL}document-draft/update/'
                              '${_draft.id}?userId=${pf.userId}');

                          final service =
                              DocumentDraftService(widget.token!);

                          await DocumentDraftService(widget.token!).updateDraft(
                            draftId: _draft.id,
                            advocateId: _draft.advocateId,
                            caseId: _draft.caseId,
                            userId: presentUserId ?? '',
                            //issuedDate: selectedDate,
                            existingFiles: filteredExisting,
                            // On native, _newFiles stays empty, so
                            // this is a no-op; Web passes the picked files.
                            newFiles: kIsWeb ? _newFiles : const [],
                          );
                          _dbg('✅ updateDraft returned OK');

                          _dbg('Refreshing draft via findById…');
                          final updated =
                              await service.findById(_draft.id);
                          _dbg('✅ findById returned OK');

                          if (mounted) {
                            setState(() {
                              _draft = updated;
                              _existingAttachments =
                                  List.from(_draft.attachmentsId);
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "✓ Document draft updated successfully"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e, st) {
                          _dbg('❌ UPDATE FAILED: $e');
                          _dbg('stack: $st');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✗ Error: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setDialogState(() => _isUploading = false);
                          }
                        }
                      },
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Delete
  // ────────────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Document Draft"),
        content: const Text(
          "Are you sure you want to delete this document draft?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final pf = await _preflight(opLabel: 'delete');
      if (pf == null) return;

      _dbg('========== DELETE REQUEST ==========');
      _dbg('draftId=${_draft.id}');
      _dbg('userId=${pf.userId}');
      _dbg('token=${_maskToken(pf.token)}');
      _dbg(
          'URL=${BASE_URL.Urls().baseURL}document-draft/${_draft.id}?userId=${pf.userId}');

      final service = DocumentDraftService(pf.token);
      final ok = await service.deleteDraft(_draft.id, pf.userId);
      _dbg('deleteDraft returned $ok');
      if (!ok) throw Exception("Backend rejected delete");

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Document draft deleted"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      _dbg('❌ DELETE FAILED: $e');
      _dbg('stack: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✗ Delete failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  // UI
  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.padding(context, 12);
    final titleSize = ResponsiveHelper.fontSize(context, 20);
    final labelSize = ResponsiveHelper.fontSize(context, 14);
    final valueSize = ResponsiveHelper.fontSize(context, 15);

    final draftedCase = _draft.documentDraftedCase;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Draft Details"),
        backgroundColor: Colors.green,
        actions: [
          if (_isAdvocate)
            IconButton(
              tooltip: "Edit draft",
              icon: const Icon(Icons.edit),
              onPressed: _openEditDialog,
            ),
          if (_isAdvocate)
            IconButton(
              tooltip: "Delete draft",
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description,
                            color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Document Draft",
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    _row("Issued Date", _formatDate(_draft.issuedDate),
                        labelSize, valueSize),
                    SizedBox(height: 6),
                    _row("Draft ID", _draft.id, labelSize, valueSize),
                    SizedBox(height: 6),
                    _row("Case ID", _draft.caseId, labelSize, valueSize),
                    SizedBox(height: 6),
                    _row("Advocate ID", _draft.advocateId, labelSize,
                        valueSize),
                    if (draftedCase != null) ...[
                      SizedBox(height: 6),
                      _row("Case Name", draftedCase.caseName, labelSize,
                          valueSize),
                      SizedBox(height: 6),
                      _row("Case Type", draftedCase.caseType, labelSize,
                          valueSize),
                      SizedBox(height: 6),
                      _row("Advocate Name",
                          draftedCase.displayAdvocateName, labelSize,
                          valueSize),
                      SizedBox(height: 6),
                      _row("Client", draftedCase.displayUserName,
                          labelSize, valueSize),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing * 1.5),
            Text(
              "Attachments (${_draft.attachmentsId.length})",
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing),
            if (_draft.attachmentsId.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No attachments",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ..._draft.attachmentsId.map(
              (attId) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.blue,
                  ),
                  title: Text(attId, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentDraftAttachmentView(
                          attachmentId: attId,
                          jwtToken: widget.token,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    double labelSize,
    double valueSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label:",
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: valueSize)),
        ),
      ],
    );
  }
}