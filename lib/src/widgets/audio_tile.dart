import 'package:flutter/material.dart';
import '../models/audio_track.dart';

class AudioTile extends StatelessWidget {
  final AudioTrack track;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTap;
  final Widget? customTile;

  const AudioTile({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.progress,
    required this.onTap,
    this.customTile,
  });

  @override
  Widget build(BuildContext context) {
    if (customTile != null) return customTile!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                track.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.subtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.blue,
                  size: 24.0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
