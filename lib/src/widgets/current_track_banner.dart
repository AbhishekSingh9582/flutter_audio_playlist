import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_playlist_provider.dart';
import '../utils/format_duration.dart';

class CurrentTrackBanner extends StatelessWidget {
  final Widget? customBanner;
  final bool hideOnPlayerScreen;
  final String playerScreenRoute;

  const CurrentTrackBanner({
    super.key,
    this.customBanner,
    this.hideOnPlayerScreen = false,
    required this.playerScreenRoute,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioPlaylistProvider>(context);
    if (provider.currentTrack == null) return const SizedBox.shrink();
    if (hideOnPlayerScreen &&
        ModalRoute.of(context)?.settings.name == playerScreenRoute) {
      return const SizedBox.shrink();
    }

    if (customBanner != null) return customBanner!;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, playerScreenRoute),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                provider.currentTrack!.imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.currentTrack!.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                  if (provider.position != null &&
                      provider.totalDuration != null)
                    LinearProgressIndicator(
                      value: provider.position.inMilliseconds /
                          (provider.totalDuration!.inMilliseconds + 1),
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                ],
              ),
            ),
            Text(
              '${formatDuration(provider.position)} / ${formatDuration(provider.totalDuration ?? Duration.zero)}',
              style: const TextStyle(fontSize: 12),
            ),
            IconButton(
              icon: Icon(
                provider.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.blue,
              ),
              onPressed: provider.togglePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: provider.stop,
            ),
          ],
        ),
      ),
    );
  }
}
