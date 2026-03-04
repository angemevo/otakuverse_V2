import 'package:get/get.dart';
import 'package:otakuverse/features/activity/controller/notification_controller.dart';
import 'package:otakuverse/features/feed/controllers/bookmark_controller.dart';
import 'package:otakuverse/features/feed/controllers/comment_controller.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/profile/controllers/follow_controller.dart';

class FeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostsController>(() => PostsController());
    Get.lazyPut(() => FollowController());
    Get.lazyPut(() => CommentController());
    Get.lazyPut(() => NotificationController());
    Get.lazyPut(() => BookmarkController());
  }
}