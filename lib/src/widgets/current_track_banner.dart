import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/widgets/app_cached_network.dart';
import 'package:flutter_audio_playlist/src/theme/audio_player_theme_data.dart';
import 'package:provider/provider.dart';
import '../providers/audio_playlist_provider.dart';
import '../utils/format_duration.dart';

/// A banner widget that displays information about the currently playing audio track.
///
/// It typically appears at the bottom of the screen and shows the track's image,
/// title, playback progress, and controls like play/pause and close.
/// Tapping the banner usually navigates to the main player screen.
///
/// The appearance can be customized using the [theme] property or by providing
/// a completely [customBanner].
///
/// Example:
/// ```dart
/// CurrentTrackBanner(
///   playerScreenRoute: '/player', // The route to navigate to on tap.
///   theme: AudioPlayerThemeData(
///     screenBackgroundColor: Colors.amber, // For banner background
///     primaryContentColor: Colors.black,   // For text and icons
///   ),
/// )
/// ```
class CurrentTrackBanner extends StatelessWidget {
  /// An optional custom widget to display as the banner.
  /// If provided, all other layout and styling parameters are ignored.
  final Widget? customBanner;
  /// If `true`, the banner will be hidden when the current route matches [playerScreenRoute].
  /// Defaults to `false`.
  final bool hideOnPlayerScreen;
  /// The named route of the main audio player screen. Tapping the banner
  /// will navigate to this route.
  final String playerScreenRoute;
  /// Optional theme data to customize the appearance of the default banner.
  /// If not provided, it will try to use `AudioPlayerTheme.of(context)` or default styles.
  final AudioPlayerThemeData? theme;
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
    // Resolve the theme for default banner styling:
    // 1. Use the theme passed directly to the widget.
    // 2. If not available, try to find an AudioPlayerTheme higher in the widget tree.
    // 3. Fallback to a default AudioPlayerThemeData if none is found.
    final effectiveTheme = theme ??
        AudioPlayerTheme.of(context) ??
        const AudioPlayerThemeData();

    // If no track is playing, don't show the banner.
    if (provider.currentTrack == null) return const SizedBox.shrink();

    // Optionally hide the banner if we are already on the player screen.
    if (hideOnPlayerScreen &&
        ModalRoute.of(context)?.settings.name == playerScreenRoute) {
      return const SizedBox.shrink();
    }

    // If a custom banner is provided, use it directly.
    if (customBanner != null) return customBanner!;

    // Determine banner colors based on the effective theme and dominant color settings.
    Color bannerBackgroundColor;
    Color bannerTextColor;
    Color bannerIconColor;

    if (effectiveTheme.useDominantColorForBackground && provider.currentTrackDominantColor != null) {
      final dominantColor = provider.currentTrackDominantColor!;
      final isDarkDominant = dominantColor.computeLuminance() < 0.5;
      // Use screenBackgroundColor from theme for banner, or fallback to dominant color.
      bannerBackgroundColor = effectiveTheme.bannerBackgroundColor ??  dominantColor;
      bannerTextColor = effectiveTheme.primaryContentColor ?? (isDarkDominant ? Colors.white : Colors.black);
      bannerIconColor = effectiveTheme.controlButtonIconColor ?? (isDarkDominant ? Colors.white70 : Theme.of(context).colorScheme.primary);
    } else {
      // Fallback to theme's banner color, screen color, or Material surface variant.
      bannerBackgroundColor = effectiveTheme.bannerBackgroundColor ?? effectiveTheme.screenBackgroundColor ?? Theme.of(context).colorScheme.surfaceVariant;
      bannerTextColor = effectiveTheme.primaryContentColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
      bannerIconColor = effectiveTheme.controlButtonIconColor ?? Theme.of(context).colorScheme.primary;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, playerScreenRoute),
      // Main container for the banner.
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 1),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bannerBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Row containing track info and controls.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  ClipRRect(
                    // Track image.
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
                      // Track title.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.currentTrack!.title,
                          // Apply title style from theme or default.
                          style: effectiveTheme.titleTextStyle?.copyWith(color: bannerTextColor) ??
                               TextStyle(fontWeight: FontWeight.bold, color: bannerTextColor),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    // Playback position and total duration.
                    '${formatDuration(provider.position)} / ${formatDuration(provider.totalDuration ?? Duration.zero)}',
                    // Apply time text style from theme or default.
                    style: effectiveTheme.trackTimeTextStyle?.copyWith(color: bannerTextColor.withOpacity(0.8)) ??
                           TextStyle(fontSize: 12, color: bannerTextColor.withOpacity(0.8)),
                  ),
                  IconButton(
                    // Play/pause button.
                    icon: Icon(
                      provider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: bannerIconColor,
                    ),
                    onPressed: provider.togglePlayPause,
                  ),
                  IconButton(
                    // Close button to stop playback and dismiss banner (implicitly).
                    icon: Icon(Icons.close, color: bannerIconColor.withOpacity(0.7)),
                    onPressed: provider.stop,
                  ),
                ],
              ),
            ),
            // Linear progress indicator.
            if (provider.totalDuration != null)
              LinearProgressIndicator(
                value: provider.position.inMilliseconds /
                    (provider.totalDuration!.inMilliseconds + 1), // Add 1 to avoid division by zero if duration is 0.
                backgroundColor: bannerTextColor.withOpacity(0.3),
                minHeight: 3,
                // Use bannerIconColor for the progress value color.
                valueColor: AlwaysStoppedAnimation<Color>(bannerIconColor),
              ),
          ],
        ),
      ),
    );
  }
}
