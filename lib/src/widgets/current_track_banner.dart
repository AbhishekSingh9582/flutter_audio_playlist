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
    final provider = context.watch<AudioPlaylistProvider>();
    if (provider.currentTrack == null) return const SizedBox.shrink();
    if (hideOnPlayerScreen &&
        ModalRoute.of(context)?.settings.name == playerScreenRoute) {
      return const SizedBox.shrink();
    }

    if (customBanner != null) return customBanner!;

    final dominantColor = provider.currentTrackDominantColor;
    final bannerColor = dominantColor ?? Colors.blue[50];
    final textColor =
        dominantColor != null && dominantColor.computeLuminance() < 0.5
            ? Colors.white
            : Colors.black;
    final iconColor =
        dominantColor != null && dominantColor.computeLuminance() < 0.5
            ? Colors.white70
            : Colors.blue;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, playerScreenRoute),
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 1),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                          provider
                              .currentTrack!.title, // Consider textColor here
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatDuration(provider.position)} / ${formatDuration(provider.totalDuration ?? Duration.zero)}',
                    style: TextStyle(
                        fontSize: 12, color: textColor.withOpacity(0.8)),
                  ),
                  IconButton(
                    icon: Icon(
                      provider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: iconColor,
                    ),
                    onPressed: provider.togglePlayPause,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: iconColor.withOpacity(0.7)),
                    onPressed: provider.stop,
                  ),
                ],
              ),
            ),
            if (provider.totalDuration != null)
              LinearProgressIndicator(
                value: provider.position.inMilliseconds /
                    (provider.totalDuration!.inMilliseconds + 1),
                backgroundColor: textColor.withOpacity(0.3),
                minHeight: 3,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
          ],
        ),
      ),
    );
  }
}
