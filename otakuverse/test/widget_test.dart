// Smoke tests for core models — fast sanity checks.
// Full tests are in models/, controllers/, security/ subdirectories.

import 'package:flutter_test/flutter_test.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/models/comment_model.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'helpers/fixtures.dart';

void main() {
  group('Smoke tests - core models', () {
    test('PostModel parses from JSON without error', () {
      expect(() => PostModel.fromJson(postJson()), returnsNormally);
    });

    test('ProfileModel parses from JSON without error', () {
      expect(() => ProfileModel.fromJson(profileJson()), returnsNormally);
    });

    test('CommentModel parses from JSON without error', () {
      expect(() => CommentModel.fromJson(commentJson()), returnsNormally);
    });

    test('PostModel.copyWith does not mutate original', () {
      final original = PostModel.fromJson(postJson());
      original.copyWith(likesCount: 9999);
      expect(original.likesCount, 42); // unchanged
    });

    test('ProfileModel.levelProgress is between 0.0 and 1.0', () {
      final model = ProfileModel.fromJson(profileJson());
      expect(model.levelProgress, inInclusiveRange(0.0, 1.0));
    });
  });
}
