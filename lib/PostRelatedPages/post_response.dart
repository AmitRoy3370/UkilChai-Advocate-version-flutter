import 'dart:ui';

import '../PostRelatedPages/post_reaction.dart';
import '../PostRelatedPages/post_reaction_response.dart';

import '../Utils/AdvocateSpeciality.dart';

class PostResponse {
  final String id;
  final String advocateId;
  final String advocateName;
  final AdvocateSpeciality postType;
  final String postContent;
  final String? attachmentId;
  final List<PostReactionResponse> reactions;

  PostResponse({
    required this.id,
    required this.advocateId,
    required this.advocateName,
    required this.postType,
    required this.postContent,
    this.attachmentId,
    required this.reactions,
  });

  // From JSON Factory Constructor
  factory PostResponse.fromJson(Map<String, dynamic> json) {
    return PostResponse(
      id: json['id'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      postType: AdvocateSpecialityExt.fromApi(json['postType']),
      postContent: json['postContent'] ?? '',
      attachmentId: json['attachmentId'],
      reactions: (json['reactions'] as List?)
          ?.map((reaction) => PostReactionResponse.fromJson(reaction))
          .toList() ??
          [],
    );
  }

  // To JSON Method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advocateId': advocateId,
      'advocateName': advocateName,
      'postType': postType.apiValue,
      'postContent': postContent,
      if (attachmentId != null) 'attachmentId': attachmentId,
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
    };
  }

  // Copy With Method (State Update এর জন্য)
  PostResponse copyWith({
    String? id,
    String? advocateId,
    String? advocateName,
    AdvocateSpeciality? postType,
    String? postContent,
    String? attachmentId,
    List<PostReactionResponse>? reactions,
  }) {
    return PostResponse(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      advocateName: advocateName ?? this.advocateName,
      postType: postType ?? this.postType,
      postContent: postContent ?? this.postContent,
      attachmentId: attachmentId ?? this.attachmentId,
      reactions: reactions ?? this.reactions,
    );
  }

  // Computed Properties
  int get totalReactions => reactions.length;

  Map<PostReactions, int> get reactionCounts {
    final Map<PostReactions, int> counts = {};
    for (var reaction in reactions) {
      counts[reaction.postReaction] = (counts[reaction.postReaction] ?? 0) + 1;
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
    return 'PostResponse(id: $id, advocateName: $advocateName, postType: ${postType.label}, reactions: ${reactions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostResponse &&
        other.id == id &&
        other.advocateId == advocateId &&
        other.advocateName == advocateName &&
        other.postType == postType &&
        other.postContent == postContent &&
        other.attachmentId == attachmentId &&
        other.reactions.length == reactions.length;
  }

  @override
  int get hashCode {
    return Object.hash(id, advocateId, advocateName, postType, postContent, attachmentId, reactions.length);
  }
}