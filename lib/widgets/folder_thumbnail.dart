import 'package:flutter/material.dart';
import '../models/folder.dart';

const Color kBackground = Color(0xFFFFFDF6);
const Color kPrimary = Color(0xFF2978A0);
const Color kAccent = Color(0xFFBBDEF0);
const Color kHighlight = Color(0xFFF3DFA2);

class FolderThumbnailCard extends StatelessWidget {
  final TravelFolder folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int planCount; 

  const FolderThumbnailCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onLongPress,
    this.planCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder, size: 60, color: kPrimary),
            const SizedBox(height: 10),
            Text(
              folder.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '$planCount Plan${planCount == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
