import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/models/audio_track.dart';
import 'package:flutter_audio_playlist/src/providers/audio_playlist_provider.dart';
import 'package:flutter_audio_playlist/src/widgets/app_cached_network.dart';
import 'package:provider/provider.dart';

typedef PlayPauseIconBuilder = Widget Function(
    BuildContext context, bool isPlaying, VoidCallback onPressed);
typedef ProgressIndicatorBuilder = Widget Function(
    BuildContext context, double progress);

typedef SuffixBuilder = Widget Function(
    BuildContext context, AudioTrack track, bool isPlaying);

class AudioTile extends StatelessWidget {
  final AudioTrack track;
  final VoidCallback? onTap;
  final Widget? customTile;
  final bool showPlayPauseIcon;
  final bool showProgressIndicator;
  final PlayPauseIconBuilder? playPauseBuilder;
  final ProgressIndicatorBuilder? progressBuilder;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final EdgeInsetsGeometry? padding;
  final double? leadingImageSize;
  final double? leadingImageBorderRadius;
  final double? spacingBetweenImageAndText;
  final double? spacingBetweenTextAndControls;
  final TextStyle? playingTitleTextStyle;
  final TextStyle? playingSubtitleTextStyle;
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
    if (customTile != null) return customTile!;

    return InkWell(
      onTap: onTap ?? () {
        final provider = context.read<AudioPlaylistProvider>();
        if (provider.currentTrack?.id == track.id) {
          provider.togglePlayPause();
        } else {
          provider.playTrack(track);
        }
      },
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            Expanded(
              child: Selector<AudioPlaylistProvider, bool>(
                selector: (_, provider) => provider.currentTrack?.id == track.id,
                builder: (context, isCurrentlyPlayingThisTrack, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Important for Column inside Row
                    children: [
                      Text(
                        track.title,
                        style: isCurrentlyPlayingThisTrack
                            ? (playingTitleTextStyle ?? titleTextStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))
                            : (titleTextStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.subtitle,
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
            // Suffix builder also needs to know if this track is playing.
            if (suffixBuilder != null)
              Selector<AudioPlaylistProvider, bool>(
                selector: (_, provider) => provider.currentTrack?.id == track.id,
                builder: (context, isCurrentlyPlayingThisTrack, child) {
                  return suffixBuilder!(context, track, isCurrentlyPlayingThisTrack);
                },
              ),
            if (suffixBuilder != null && (showPlayPauseIcon || showProgressIndicator))
              SizedBox(width: spacingBetweenTextAndControls! / 2),

            if (showPlayPauseIcon || showProgressIndicator)
              Consumer<AudioPlaylistProvider>(
      
                builder: (context, provider, child) {
                  final bool isCurrentlyPlayingThisTrack =
                      provider.currentTrack?.id == track.id;
                  final bool isPlaying =
                      provider.isPlaying && isCurrentlyPlayingThisTrack;
                  final double progress = isCurrentlyPlayingThisTrack &&
                          provider.totalDuration != null &&
                          provider.totalDuration!.inMilliseconds > 0
                      ? provider.position.inMilliseconds /
                          provider.totalDuration!.inMilliseconds
                      : 0.0;

                  Widget playPauseWidget;
                  if (showPlayPauseIcon) {
                    if (playPauseBuilder != null) {
                      playPauseWidget =
                          playPauseBuilder!(context, isPlaying, () {
                        if (isCurrentlyPlayingThisTrack) {
                          provider.togglePlayPause();
                        } else {
                          provider.playTrack(track);
                        }
                      });
                    } else {
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
                      progressWidget =
                          progressBuilder!(context, progress.clamp(0.0, 1.0));
                    } else {
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
                    return Stack(
                        alignment: Alignment.center,
                        children: [progressWidget, playPauseWidget]);
                  }
                  return playPauseWidget; 
                },
              ),
          ],
        ),
      ),
    );
  }
}
