import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/flutter_video_playlist.dart';
import 'package:provider/provider.dart';
import '../models/audio_track.dart';

class AudioTile extends StatelessWidget {
  final AudioTrack track;
  final VoidCallback? onTap;
  final Widget? customTile;

  const AudioTile({
    super.key,
    required this.track,
     this.onTap,
    this.customTile,
  });

  @override
  Widget build(BuildContext context) {
    if (customTile != null) return customTile!;

    return InkWell(
      onTap: onTap ?? () {
        if (context.read<AudioPlaylistProvider>().currentTrack?.id == track.id) {
          context.read<AudioPlaylistProvider>().togglePlayPause();
        } else {
          context.read<AudioPlaylistProvider>().playTrack(track);
        }
      },
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
                Consumer<AudioPlaylistProvider>(
                    builder: (context, audioPlaylistProvier, child) {
                  return SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: audioPlaylistProvier.currentTrack?.id == track.id
                          ? audioPlaylistProvier.position.inMilliseconds /
                              (audioPlaylistProvier
                                      .totalDuration?.inMilliseconds ??
                                  1)
                          : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  );
                }),
                Selector<AudioPlaylistProvider, bool>(
                    selector: (_, provider) =>
                        provider.isPlaying &&
                        provider.currentTrack?.id == track.id,
                    builder: (context, isPlaying, child) {
                      return Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.blue,
                        size: 24.0,
                      );
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
