import 'package:get/get.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';

class FeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostsController>(() => PostsController());
  }
}