import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;

  UserProfile({required this.id, required this.name});
}

class User {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String bio;
  final bool isAnonymous;
  final int followersCount;
  final int followingCount;
  final int createdRecipeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    this.bio = '',
    this.isAnonymous = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.createdRecipeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'] ?? '',
      bio: data['bio'] ?? '',
      isAnonymous: data['isAnonymous'] ?? false,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      createdRecipeCount: data['createdRecipeCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'isAnonymous': isAnonymous,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdRecipeCount': createdRecipeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  User copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    bool? isAnonymous,
    int? followersCount,
    int? followingCount,
    int? createdRecipeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdRecipeCount: createdRecipeCount ?? this.createdRecipeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
