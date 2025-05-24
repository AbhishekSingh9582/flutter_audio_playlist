import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/widgets/app_cached_network.dart';
import 'package:flutter_audio_playlist/src/theme/audio_player_theme_data.dart';
import 'package:provider/provider.dart';
import '../providers/audio_playlist_provider.dart';
import '../utils/format_duration.dart';

class CurrentTrackBanner extends StatelessWidget {
  final Widget? customBanner;
  final bool hideOnPlayerScreen;
  final String playerScreenRoute;
  final AudioPlayerThemeData? theme; // Optional theme for default banner

  const CurrentTrackBanner({
    super.key,
    this.customBanner,
    this.hideOnPlayerScreen = false,
    required this.playerScreenRoute,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioPlaylistProvider>();
    // Resolve theme for default banner styling
    final effectiveTheme = theme ??
        AudioPlayerTheme.of(context) ??
        const AudioPlayerThemeData();

    if (provider.currentTrack == null) return const SizedBox.shrink();
    if (hideOnPlayerScreen &&
        ModalRoute.of(context)?.settings.name == playerScreenRoute) {
      return const SizedBox.shrink();
    }

    if (customBanner != null) return customBanner!;

    // Use theme colors if available, otherwise fallback to dominant color logic or defaults
    Color bannerBackgroundColor;
    Color bannerTextColor;
    Color bannerIconColor;

    if (effectiveTheme.useDominantColorForBackground && provider.currentTrackDominantColor != null) {
      final dominantColor = provider.currentTrackDominantColor!;
      final isDarkDominant = dominantColor.computeLuminance() < 0.5;
      bannerBackgroundColor = effectiveTheme.screenBackgroundColor ?? dominantColor; // Example: use screen bg for banner
      bannerTextColor = effectiveTheme.primaryContentColor ?? (isDarkDominant ? Colors.white : Colors.black);
      bannerIconColor = effectiveTheme.controlButtonIconColor ?? (isDarkDominant ? Colors.white70 : Theme.of(context).colorScheme.primary);
    } else {
      bannerBackgroundColor = effectiveTheme.screenBackgroundColor ?? Theme.of(context).colorScheme.surfaceVariant;
      bannerTextColor = effectiveTheme.primaryContentColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
      bannerIconColor = effectiveTheme.controlButtonIconColor ?? Theme.of(context).colorScheme.primary;
    }



    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, playerScreenRoute),
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 1),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bannerBackgroundColor,
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
                    child: AppCachedNetworkImage(
                      url:provider.currentTrack!.imageUrl,
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
                          style: effectiveTheme.titleTextStyle?.copyWith(color: bannerTextColor) ??
                               TextStyle(fontWeight: FontWeight.bold, color: bannerTextColor),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatDuration(provider.position)} / ${formatDuration(provider.totalDuration ?? Duration.zero)}', // Consider theme for this text
                    style: effectiveTheme.trackTimeTextStyle?.copyWith(color: bannerTextColor.withOpacity(0.8)) ??
                           TextStyle(fontSize: 12, color: bannerTextColor.withOpacity(0.8)),
                  ),
                  IconButton(
                    icon: Icon(
                      provider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: bannerIconColor,
                    ),
                    onPressed: provider.togglePlayPause,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: bannerIconColor.withOpacity(0.7)),
                    onPressed: provider.stop,
                  ),
                ],
              ),
            ),
            if (provider.totalDuration != null)
              LinearProgressIndicator(
                value: provider.position.inMilliseconds /
                    (provider.totalDuration!.inMilliseconds + 1),
                backgroundColor: bannerTextColor.withOpacity(0.3),
                minHeight: 3,
                valueColor: AlwaysStoppedAnimation<Color>(bannerIconColor),
              ),
          ],
        ),
      ),
    );
  }
}
