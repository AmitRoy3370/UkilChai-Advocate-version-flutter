import 'package:flutter/material.dart';
import '../PostRelatedPages/post_reaction.dart';
import '../PostRelatedPages/post_reaction_response.dart';
import '../Utils/AdvocateSpeciality.dart';

class PostResponse {
  final String id;
  final String advocateId;
  final String advocateName;
  final String? advocateFullName;
  final AdvocateSpeciality postType;
  final String postContent;
  final String? postTitle;
  final String? attachmentId;
  final List<PostReactionResponse> reactions;

  PostResponse({
    required this.id,
    required this.advocateId,
    required this.advocateName,
    required this.advocateFullName,
    required this.postType,
    required this.postContent,
    this.postTitle,
    this.attachmentId,
    required this.reactions,
  });

  factory PostResponse.fromJson(Map<String, dynamic> json) {
    return PostResponse(
      id: json['id'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      advocateFullName: json['advocateFullName'],
      postType: AdvocateSpecialityExt.fromApi(json['postType']),
      postContent: json['postContent'] ?? '',
      postTitle: json['postTitle'],
      attachmentId: json['attachmentId'],
      reactions: (json['reactions'] as List?)
              ?.map((reaction) => PostReactionResponse.fromJson(reaction))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advocateId': advocateId,
      'advocateName': advocateName,
      'advocateFullName': advocateFullName,
      'postType': postType.apiValue,
      'postContent': postContent,
      if (postTitle != null) 'postTitle': postTitle,
      if (attachmentId != null) 'attachmentId': attachmentId,
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
    };
  }

  PostResponse copyWith({
    String? id,
    String? advocateId,
    String? advocateName,
    String? advocateFullName,
    AdvocateSpeciality? postType,
    String? postContent,
    String? postTitle,
    String? attachmentId,
    List<PostReactionResponse>? reactions,
  }) {
    return PostResponse(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      advocateName: advocateName ?? this.advocateName,
      advocateFullName: advocateFullName ?? this.advocateFullName,
      postType: postType ?? this.postType,
      postContent: postContent ?? this.postContent,
      postTitle: postTitle ?? this.postTitle,
      attachmentId: attachmentId ?? this.attachmentId,
      reactions: reactions ?? this.reactions,
    );
  }

  int get totalReactions => reactions.length;

  Map<PostReactions, int> get reactionCounts {
    final Map<PostReactions, int> counts = {};
    for (var reaction in reactions) {
      if (reaction.postReaction != null) {
        counts[reaction.postReaction!] =
            (counts[reaction.postReaction] ?? 0) + 1;
      }
    }
    return counts;
  }

  bool get hasAttachment => attachmentId != null && attachmentId!.isNotEmpty;
  String get formattedPostType => postType.label;

  bool isReactedByUser(String userId) {
    return reactions.any((reaction) => reaction.userId == userId);
  }

  PostReactionResponse? getUserReaction(String userId) {
    try {
      return reactions.firstWhere((reaction) => reaction.userId == userId);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'PostResponse(id: $id, advocateName: $advocateName, postType: ${postType.label}, postTitle: $postTitle, reactions: ${reactions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostResponse &&
        other.id == id &&
        other.advocateId == advocateId &&
        other.advocateName == advocateName &&
        other.advocateFullName == advocateFullName &&
        other.postType == postType &&
        other.postContent == postContent &&
        other.postTitle == postTitle &&
        other.attachmentId == attachmentId &&
        other.reactions.length == reactions.length;
  }

  @override
  int get hashCode {
    return Object.hash(id, advocateId, advocateName, advocateFullName,
        postType, postContent, postTitle, attachmentId, reactions.length);
  }
}