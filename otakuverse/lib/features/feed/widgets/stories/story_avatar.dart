import 'package:flutter/material.dart';
import 'package:otakuverse/features/feed/models/stories_model.dart';

class StoryAvatar extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;
  
  const StoryAvatar({super.key, required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            // Anneau de couleur
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.seen
                  ? null
                  : const LinearGradient(
                      colors: [Colors.orange, Colors.pink, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                  ),
                  color: story.seen ? Colors.grey[700] : null
              ),
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(story.avatarUrl!),
                ),
              ),
            ),
            SizedBox(height: 4,),
            Text(
              story.username,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }
}