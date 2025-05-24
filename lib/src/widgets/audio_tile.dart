import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/models/audio_track.dart';
import 'package:flutter_audio_playlist/src/providers/audio_playlist_provider.dart';
import 'package:flutter_audio_playlist/src/widgets/app_cached_network.dart';
import 'package:provider/provider.dart';

/// A builder function for creating a custom play/pause icon widget.
///
/// - [context]: The build context.
/// - [isPlaying]: A boolean indicating if the track is currently playing.
/// - [onPressed]: The callback to be invoked when the icon is pressed.
typedef PlayPauseIconBuilder = Widget Function(
    BuildContext context, bool isPlaying, VoidCallback onPressed);

/// A builder function for creating a custom progress indicator widget.
///
/// - [context]: The build context.
/// - [progress]: The current playback progress, a value between 0.0 and 1.0.
typedef ProgressIndicatorBuilder = Widget Function(
    BuildContext context, double progress);

/// A builder function for creating a custom suffix widget for the [AudioTile].
///
/// - [context]: The build context.
/// - [track]: The [AudioTrack] associated with this tile.
/// - [isPlaying]: A boolean indicating if this specific track is currently playing.
typedef SuffixBuilder = Widget Function(
    BuildContext context, AudioTrack track, bool isPlaying);

/// A widget that displays an audio track in a list format.
///
/// It typically shows the track's image, title, subtitle, and playback controls
/// (like a play/pause button or progress indicator). The appearance and behavior
/// can be extensively customized.
///
/// Interacts with [AudioPlaylistProvider] to reflect and control playback state.
///
/// Example:
/// ```dart
/// AudioTile(
///   track: myAudioTrack,
///   titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
///   onTap: () {
///     // Custom tap action
///   },
/// )
/// ```
class AudioTile extends StatelessWidget {
  /// The [AudioTrack] data to display.
  final AudioTrack track;

  /// An optional callback that is invoked when the tile is tapped.
  /// If not provided, the default behavior is to play the track or toggle
  /// its play/pause state.
  final VoidCallback? onTap;

  /// An optional custom widget to display instead of the default tile layout.
  /// If provided, all other layout and styling parameters are ignored.
  final Widget? customTile;

  /// Whether to show a play/pause icon. Defaults to `true`.
  final bool showPlayPauseIcon;

  /// Whether to show a progress indicator (e.g., a circular progress bar)
  /// when this track is playing. Defaults to `true`.
  final bool showProgressIndicator;

  /// A builder function to create a custom play/pause icon.
  /// If provided, this overrides the default play/pause icon.
  final PlayPauseIconBuilder? playPauseBuilder;

  /// A builder function to create a custom progress indicator.
  /// If provided, this overrides the default progress indicator.
  final ProgressIndicatorBuilder? progressBuilder;

  /// The text style for the track title.
  final TextStyle? titleTextStyle;

  /// The text style for the track subtitle.
  final TextStyle? subtitleTextStyle;

  /// The padding around the content of the tile.
  /// Defaults to `EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0)`.
  final EdgeInsetsGeometry? padding;

  /// The size (width and height) of the leading image (album art). Defaults to `50`.
  final double? leadingImageSize;

  /// The border radius for the leading image. Defaults to `8`.
  final double? leadingImageBorderRadius;

  /// The spacing between the leading image and the text (title/subtitle). Defaults to `12`.
  final double? spacingBetweenImageAndText;

  /// The spacing between the text and the trailing controls (play/pause, progress). Defaults to `8`.
  final double? spacingBetweenTextAndControls;

  /// The text style for the track title when this specific track is playing.
  /// If not provided, [titleTextStyle] is used, or a default style with primary color.
  final TextStyle? playingTitleTextStyle;

  /// The text style for the track subtitle when this specific track is playing.
  /// If not provided, [subtitleTextStyle] is used, or a default style with primary color.
  final TextStyle? playingSubtitleTextStyle;

  /// A builder function to create a custom suffix widget, displayed after the title/subtitle
  /// and before the play/pause/progress controls.
  final SuffixBuilder? suffixBuilder;

  const AudioTile({
    super.key,
    required this.track,
    this.onTap,
    this.customTile,
    this.showPlayPauseIcon = true,
    this.showProgressIndicator = true,
    this.playPauseBuilder,
    this.progressBuilder,
    this.titleTextStyle,
    this.playingTitleTextStyle,
    this.playingSubtitleTextStyle,
    this.suffixBuilder,
    this.subtitleTextStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    this.leadingImageSize = 50,
    this.leadingImageBorderRadius = 8,
    this.spacingBetweenImageAndText = 12,
    this.spacingBetweenTextAndControls = 8,
  });

  @override
  Widget build(BuildContext context) {
    // If a custom tile is provided, use it directly and ignore other parameters.
    if (customTile != null) return customTile!;

    return InkWell(
      onTap: onTap ?? () {
        // Default tap behavior: play the track or toggle play/pause if it's the current track.
        final provider = context.read<AudioPlaylistProvider>();
        if (provider.currentTrack?.id == track.id) {
          provider.togglePlayPause();
        } else {
          provider.playTrack(track);
        }
      },
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Apply padding.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading image (album art).
            ClipRRect(
              borderRadius: BorderRadius.circular(leadingImageBorderRadius!),
              child: AppCachedNetworkImage(
                url: track.imageUrl,
                width: leadingImageSize!,
                height: leadingImageSize!,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: spacingBetweenImageAndText!),
            // Title and subtitle section.
            Expanded(
              child: Selector<AudioPlaylistProvider, bool>(
                selector: (_, provider) => provider.currentTrack?.id == track.id,
                // Rebuild only when this track becomes or stops being the current track.
                builder: (context, isCurrentlyPlayingThisTrack, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Important for Column inside Row
                    children: [
                      Text(
                        track.title,
                        // Apply playing-specific style or default title style.
                        style: isCurrentlyPlayingThisTrack
                            ? (playingTitleTextStyle ?? titleTextStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))
                            : (titleTextStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.subtitle,
                        // Apply playing-specific style or default subtitle style.
                        style: isCurrentlyPlayingThisTrack
                            ? (playingSubtitleTextStyle ?? subtitleTextStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary.withOpacity(0.8)))
                            : (subtitleTextStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              )
            ),
            SizedBox(width: spacingBetweenTextAndControls!),
            // Optional custom suffix widget.
            if (suffixBuilder != null)
              Selector<AudioPlaylistProvider, bool>(
                selector: (_, provider) => provider.currentTrack?.id == track.id,
                // Rebuild suffix only when this track's playing state changes.
                builder: (context, isCurrentlyPlayingThisTrack, child) {
                  return suffixBuilder!(context, track, isCurrentlyPlayingThisTrack);
                },
              ),
            // Add a small spacer if suffix is present and controls are also shown.
            if (suffixBuilder != null && (showPlayPauseIcon || showProgressIndicator))
              SizedBox(width: spacingBetweenTextAndControls! / 2),

            // Play/pause icon and/or progress indicator.
            if (showPlayPauseIcon || showProgressIndicator)
              Consumer<AudioPlaylistProvider>(
                builder: (context, provider, child) {
                  final bool isCurrentlyPlayingThisTrack =
                      provider.currentTrack?.id == track.id;
                  final bool isPlaying =
                      provider.isPlaying && isCurrentlyPlayingThisTrack;
                  // Calculate progress only if it's the current track and duration is valid.
                  final double progress = isCurrentlyPlayingThisTrack &&
                          provider.totalDuration != null &&
                          provider.totalDuration!.inMilliseconds > 0
                      ? provider.position.inMilliseconds /
                          provider.totalDuration!.inMilliseconds
                      : 0.0;

                  Widget playPauseWidget;
                  if (showPlayPauseIcon) {
                    if (playPauseBuilder != null) {
                      // Use custom play/pause builder if provided.
                      playPauseWidget =
                          playPauseBuilder!(context, isPlaying, () {
                        if (isCurrentlyPlayingThisTrack) {
                          provider.togglePlayPause();
                        } else {
                          provider.playTrack(track);
                        }
                      });
                    } else {
                      // Default play/pause icon button.
                      playPauseWidget = IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Theme.of(context).colorScheme.primary,
                          size: 31.0,
                        ),
                        onPressed: () {
                          if (isCurrentlyPlayingThisTrack) {
                            provider.togglePlayPause();
                          } else {
                            provider.playTrack(track);
                          }
                        },
                        tooltip: isPlaying
                            ? 'Pause ${track.title}'
                            : 'Play ${track.title}',
                      );
                    }
                  } else {
                    playPauseWidget = const SizedBox.shrink();
                  }

                  Widget progressWidget;
                  if (showProgressIndicator && isCurrentlyPlayingThisTrack) {
                    if (progressBuilder != null) {
                      // Use custom progress builder if provided.
                      progressWidget =
                          progressBuilder!(context, progress.clamp(0.0, 1.0));
                    } else {
                      // Default circular progress indicator.
                      progressWidget = SizedBox(
                        width: 33,
                        height: 33,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary),
                        ),
                      );
                    }
                    // Stack play/pause icon on top of progress indicator if both are shown.
                    return Stack(
                        alignment: Alignment.center,
                        children: [progressWidget, playPauseWidget]);
                  }
                  // If only play/pause is shown (or progress is not applicable).
                  return playPauseWidget;
                },
              ),
          ],
        ),
      ),
    );
  }
}
