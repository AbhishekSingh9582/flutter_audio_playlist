import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/utils/extension.dart';
import 'package:flutter_audio_playlist/src/theme/audio_player_theme_data.dart';
import 'package:flutter_audio_playlist/src/widgets/app_cached_network.dart';
import 'package:provider/provider.dart';
import '../providers/audio_playlist_provider.dart';
import '../models/audio_track.dart';
import '../utils/format_duration.dart';
import '../enums/repeat_mode.dart';

class AudioPlayerScreen extends StatefulWidget {
  /// Optional theme data to customize the appearance of the audio player screen.
  /// If not provided, it will try to use `AudioPlayerTheme.of(context)` or default styles.
  final AudioPlayerThemeData? theme;

  /// A custom widget to display as the player screen. If provided, this will be
  /// used instead of the default player UI.
  final Widget? customPlayerScreen;

  final List<Duration> sleepTimerOptions;

  const AudioPlayerScreen({
    super.key,
    this.theme,
    this.customPlayerScreen,
    this.sleepTimerOptions = const [
      Duration(minutes: 2),
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
    ],
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  void _showSleepTimerBottomSheet(BuildContext modalContext,
      AudioPlaylistProvider providerForActions, AudioPlayerThemeData theme) {
    showModalBottomSheet(
      context: modalContext,
      backgroundColor: theme.screenBackgroundColor ??
          Theme.of(modalContext).bottomSheetTheme.backgroundColor, // Use theme
      builder: (bottomSheetBuilderContext) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Selector<AudioPlaylistProvider, Duration?>(
                selector: (_, p) => p.sleepTimer,
                builder: (_, sleepTimerValue, __) {
                  if (sleepTimerValue != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                          'Time left: ${formatDuration(sleepTimerValue)}',
                          style: theme.subtitleTextStyle
                                  ?.copyWith(fontWeight: FontWeight.bold) ??
                              TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryContentColor)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              ...widget.sleepTimerOptions.map((duration) => ListTile(
                    title: Text('${duration.inMinutes} minutes'),
                    titleTextStyle: theme.subtitleTextStyle
                        ?.copyWith(color: theme.primaryContentColor),
                    onTap: () {
                      providerForActions.setSleepTimer(duration);
                      Navigator.pop(bottomSheetBuilderContext);
                    },
                  )),
              Selector<AudioPlaylistProvider, Duration?>(
                  selector: (_, p) => p.sleepTimer,
                  builder: (_, sleepTimerValue, __) {
                    if (sleepTimerValue != null) {
                      return TextButton(
                        onPressed: () {
                          providerForActions.cancelSleepTimer();
                          Navigator.pop(bottomSheetBuilderContext);
                        },
                        child: Text('Cancel Timer',
                            style: TextStyle(color: theme.primaryContentColor)),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customPlayerScreen != null) return widget.customPlayerScreen!;
    final width = MediaQuery.of(context).size.width;
    final theme = widget.theme ??
        AudioPlayerTheme.of(context) ??
        const AudioPlayerThemeData();

    return Selector<AudioPlaylistProvider, AudioTrack?>(
      selector: (_, provider) => provider.currentTrack,
      builder: (context, currentTrack, child) {
        if (currentTrack == null) {
          return const Scaffold(
            body: Center(child: Text('No track currently playing')),
          );
        }

        final audioProviderForActions = context.watch<AudioPlaylistProvider>();

        return DefaultAudioPlayerScreenBody(
          theme: theme,
          width: width,
          currentTrack: currentTrack,
          audioPlaylistProvider: audioProviderForActions,
          showSleepTimerBottomSheet: (bottomSheetLauncherContext) =>
              _showSleepTimerBottomSheet(
                  bottomSheetLauncherContext, audioProviderForActions, theme),
        );
      },
    );
  }
}

/// The default UI for the audio player screen.
/// This widget is responsible for laying out the player controls, track details, etc.
/// It uses the provided [AudioPlayerThemeData] for styling.
class DefaultAudioPlayerScreenBody extends StatelessWidget {
  final AudioPlayerThemeData theme;
  final double width;
  final AudioTrack currentTrack;
  final AudioPlaylistProvider
      audioPlaylistProvider; // To access state and actions
  final Function(BuildContext) showSleepTimerBottomSheet;

  const DefaultAudioPlayerScreenBody({
    super.key,
    required this.theme,
    required this.width,
    required this.currentTrack,
    required this.audioPlaylistProvider,
    required this.showSleepTimerBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final dominantColor = context.select<AudioPlaylistProvider, Color?>(
        (p) => p.currentTrackDominantColor);

    Color effectivePrimaryContentColor;
    Color effectiveSecondaryContentColor;
    Gradient effectiveBackgroundGradient;
    Color effectiveBackgroundColor;

    if (theme.useDominantColorForBackground && dominantColor != null) {
      final bool isDarkDominant = dominantColor.computeLuminance() < 0.5;
      effectivePrimaryContentColor = theme.primaryContentColor ??
          (isDarkDominant ? Colors.white : Colors.black87);
      effectiveSecondaryContentColor = theme.secondaryContentColor ??
          (isDarkDominant ? Colors.white70 : Colors.black54);
      effectiveBackgroundGradient = theme.screenBackgroundGradient ??
          LinearGradient(
            colors: [dominantColor, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.8],
          );
      effectiveBackgroundColor = theme.screenBackgroundColor ?? dominantColor;
    } else {
      effectivePrimaryContentColor =
          theme.primaryContentColor ?? Theme.of(context).colorScheme.onSurface;
      effectiveSecondaryContentColor = theme.secondaryContentColor ??
          Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
      effectiveBackgroundGradient = theme.screenBackgroundGradient ??
          LinearGradient(colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor
          ]);
      effectiveBackgroundColor = theme.screenBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: Theme.of(context)
            .iconTheme
            .copyWith(color: theme.primaryContentColor),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: theme.primaryContentColor,
              displayColor: theme.primaryContentColor,
            ),
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: effectiveBackgroundGradient,
          ),
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Ensure it's always scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: statusBarHeight),
                PlayerBackButton(
                  icon: theme.backButtonIcon,
                  color: theme.backButtonColor ?? effectivePrimaryContentColor,
                ),
                Padding(
                  padding: theme.screenPadding ??
                      const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrackDetailsSection(
                        track: currentTrack,
                        imageWidth: width -
                            (theme.screenPadding?.horizontal ??
                                40), // Adjust for padding
                        imageHeight:
                            width - (theme.screenPadding?.horizontal ?? 40),
                        titleTextStyle: theme.titleTextStyle ??
                            TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: effectivePrimaryContentColor),
                        subtitleTextStyle: theme.subtitleTextStyle ??
                            TextStyle(color: effectiveSecondaryContentColor),
                        albumArtBorderRadius:
                            theme.albumArtBorderRadius ?? 16.0,
                        showSleepTimerButton: theme.showSleepTimerButton,
                        sleepTimerIconColor: effectivePrimaryContentColor,
                        onSleepTimerPressed: () =>
                            showSleepTimerBottomSheet(context),
                      ),
                      SizedBox(height: theme.spacingBetweenElements ?? 16.0),
                      ProgressBarSection(
                        position: audioPlaylistProvider.position,
                        totalDuration: audioPlaylistProvider.totalDuration,
                        onSeek: audioPlaylistProvider.seek,
                        sliderThemeData: theme.sliderThemeData ??
                            SliderTheme.of(context).copyWith(
                              activeTrackColor:
                                  theme.sliderThemeData?.activeTrackColor ??
                                      effectivePrimaryContentColor,
                              inactiveTrackColor:
                                  theme.sliderThemeData?.inactiveTrackColor ??
                                      effectiveSecondaryContentColor
                                          .withOpacity(0.3),
                              thumbColor: theme.sliderThemeData?.thumbColor ??
                                  effectivePrimaryContentColor,
                              overlayColor:
                                  (theme.sliderThemeData?.activeTrackColor ??
                                          effectivePrimaryContentColor)
                                      .withOpacity(0.2),
                            ),
                        timeTextStyle: theme.trackTimeTextStyle ??
                            TextStyle(
                                color: effectiveSecondaryContentColor,
                                fontSize: 12),
                      ),
                      SizedBox(
                          height: theme.spacingBetweenElements ??
                              0), // Progress bar usually has its own padding
                      ControlsSection(
                        isPlaying: audioPlaylistProvider.isPlaying,
                        isShuffling: audioPlaylistProvider.isShuffling,
                        repeatMode: audioPlaylistProvider.repeatMode,
                        onPlayPause: audioPlaylistProvider.togglePlayPause,
                        onSkipNext: audioPlaylistProvider.playNext,
                        onSkipPrevious: audioPlaylistProvider.playPrevious,
                        onToggleShuffle:
                            audioPlaylistProvider.toggleShuffleMode,
                        onCycleRepeatMode:
                            audioPlaylistProvider.cycleRepeatMode,
                        showShuffleButton: theme.showShuffleButton,
                        showRepeatButton: theme.showRepeatButton,
                        controlButtonSize: theme.controlButtonSize ?? 36,
                        playPauseButtonSize: theme.playPauseButtonSize ?? 64,
                        controlButtonColor: theme.controlButtonColor ??
                            effectivePrimaryContentColor,
                        activeControlButtonColor:
                            theme.activeControlButtonColor ??
                                (dominantColor ??
                                    Theme.of(context).colorScheme.primary),
                        inactiveControlButtonColor:
                            theme.secondaryContentColor ??
                                effectiveSecondaryContentColor,
                        playPauseButtonColor: theme.playPauseButtonColor ??
                            effectivePrimaryContentColor,
                      ),
                      if (theme.showUpNextSection)
                        UpNextSection(
                          upNextTracks: audioPlaylistProvider.upNextTracks,
                          onTrackSelected: audioPlaylistProvider.playTrack,
                          titleStyle: theme.upNextTitleStyle ??
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: effectivePrimaryContentColor),
                          cardTextStyle: theme.upNextCardTextStyle ??
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: effectivePrimaryContentColor),
                          cardDecoration: theme.upNextCardDecoration,
                          cardItemSize: theme.upNextCardItemSize,
                          cardBackgroundColor: theme
                                  .upNextCardBackgroundColor ??
                              effectiveSecondaryContentColor.withOpacity(0.2),
                          cardPadding: theme.upNextCardPadding,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerBackButton extends StatelessWidget {
  final IconData? icon;
  final Color? color;
  final VoidCallback? onPressed;

  const PlayerBackButton({super.key, this.icon, this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 12.0, vertical: 15), // Adjusted padding
      child: IconButton(
        icon: Icon(icon ?? Icons.arrow_back_ios_new,
            color: color ?? Theme.of(context).iconTheme.color),
        onPressed: onPressed ?? () => Navigator.pop(context),
      ),
    );
  }
}

class TrackDetailsSection extends StatelessWidget {
  final AudioTrack track;
  final double imageWidth;
  final double imageHeight;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final double albumArtBorderRadius;
  final bool showSleepTimerButton;
  final Color? sleepTimerIconColor;
  final VoidCallback? onSleepTimerPressed;

  const TrackDetailsSection({
    super.key,
    required this.track,
    required this.imageWidth,
    required this.imageHeight,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.albumArtBorderRadius = 16.0,
    this.showSleepTimerButton = true,
    this.sleepTimerIconColor,
    this.onSleepTimerPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleStyle = titleTextStyle ??
        Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold);
    final effectiveSubtitleStyle =
        subtitleTextStyle ?? Theme.of(context).textTheme.titleMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(albumArtBorderRadius),
          child: AppCachedNetworkImage(
            url: track.imageUrl,
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.cover,
          ),
        ),
        16.toVerticalSizedBox, // Consider making this configurable via theme
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: effectiveTitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.subtitle,
                    style: effectiveSubtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showSleepTimerButton)
              IconButton(
                icon: Icon(Icons.timer_outlined,
                    color: sleepTimerIconColor ??
                        Theme.of(context).iconTheme.color),
                onPressed: onSleepTimerPressed,
              ),
          ],
        ),
      ],
    );
  }
}

class ProgressBarSection extends StatelessWidget {
  final Duration position;
  final Duration? totalDuration;
  final ValueChanged<Duration> onSeek;
  final SliderThemeData? sliderThemeData;
  final TextStyle? timeTextStyle;

  const ProgressBarSection({
    super.key,
    required this.position,
    this.totalDuration,
    required this.onSeek,
    this.sliderThemeData,
    this.timeTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final localSliderTheme = sliderThemeData ?? SliderTheme.of(context);
    final localTimeTextStyle =
        timeTextStyle ?? Theme.of(context).textTheme.bodySmall;

    return Column(
      children: [
        SliderTheme(
          data: localSliderTheme,
          child: Slider(
            value: position.inMilliseconds
                .toDouble()
                .clamp(0.0, (totalDuration?.inMilliseconds ?? 1).toDouble()),
            max: (totalDuration?.inMilliseconds ?? 1).toDouble(),
            onChanged: (value) => onSeek(Duration(milliseconds: value.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(position), style: localTimeTextStyle),
              Text(formatDuration(totalDuration ?? Duration.zero),
                  style: localTimeTextStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class ControlsSection extends StatelessWidget {
  final bool isPlaying;
  final bool isShuffling;
  final RepeatMode repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeatMode;

  final bool showShuffleButton;
  final bool showRepeatButton;
  final double controlButtonSize;
  final double playPauseButtonSize;
  final Color? controlButtonColor; // General color for icons like prev/next
  final Color? activeControlButtonColor; // For shuffle/repeat when active
  final Color? inactiveControlButtonColor; // For shuffle/repeat when inactive
  final Color? playPauseButtonColor; // For play/pause icon

  const ControlsSection({
    super.key,
    required this.isPlaying,
    required this.isShuffling,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onToggleShuffle,
    required this.onCycleRepeatMode,
    this.showShuffleButton = true,
    this.showRepeatButton = true,
    this.controlButtonSize = 36.0,
    this.playPauseButtonSize = 64.0,
    this.controlButtonColor,
    this.activeControlButtonColor,
    this.inactiveControlButtonColor,
    this.playPauseButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveControlButtonColor =
        controlButtonColor ?? Theme.of(context).iconTheme.color;
    final effectiveActiveColor =
        activeControlButtonColor ?? Theme.of(context).colorScheme.primary;
    final effectiveInactiveColor =
        inactiveControlButtonColor ?? Theme.of(context).disabledColor;
    final effectivePlayPauseButtonColor =
        playPauseButtonColor ?? Theme.of(context).iconTheme.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0), // Consider theming
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showShuffleButton)
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color:
                    isShuffling ? effectiveActiveColor : effectiveInactiveColor,
              ),
              iconSize: controlButtonSize *
                  0.8, // Slightly smaller for shuffle/repeat
              onPressed: onToggleShuffle,
            )
          else
            const SizedBox(width: 48),
          IconButton(
            icon: Icon(Icons.skip_previous, color: effectiveControlButtonColor),
            iconSize: controlButtonSize,
            onPressed: onSkipPrevious,
          ),
          IconButton(
            iconSize: playPauseButtonSize,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                key: ValueKey<bool>(isPlaying),
                color: effectivePlayPauseButtonColor,
              ),
            ),
            onPressed: onPlayPause,
          ),
          IconButton(
            icon: Icon(Icons.skip_next, color: effectiveControlButtonColor),
            iconSize: controlButtonSize,
            onPressed: onSkipNext,
          ),
          if (showRepeatButton)
            Builder(builder: (context) {
              IconData icon;
              Color iconColor;
              switch (repeatMode) {
                case RepeatMode.off:
                  icon = Icons.repeat;
                  iconColor = effectiveInactiveColor;
                  break;
                case RepeatMode.repeatOnce:
                  icon = Icons.repeat_one;
                  iconColor = effectiveActiveColor;
                  break;
                case RepeatMode.repeatCurrent:
                  icon = Icons.repeat_on;
                  iconColor = effectiveActiveColor;
                  break;
              }
              return IconButton(
                icon: Icon(icon, color: iconColor),
                iconSize: controlButtonSize * 0.8, // Slightly smaller
                onPressed: onCycleRepeatMode,
              );
            })
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class UpNextSection extends StatelessWidget {
  final List<AudioTrack> upNextTracks;
  final ValueChanged<AudioTrack> onTrackSelected;
  final TextStyle? titleStyle;
  final TextStyle? cardTextStyle;
  final BoxDecoration? cardDecoration; // For the card itself
  final Size? cardItemSize; // Width and Height for the card
  final Color? cardBackgroundColor;
  final EdgeInsetsGeometry? cardPadding; // Padding inside the card

  const UpNextSection({
    super.key,
    required this.upNextTracks,
    required this.onTrackSelected,
    this.titleStyle,
    this.cardTextStyle,
    this.cardDecoration,
    this.cardItemSize,
    this.cardBackgroundColor,
    this.cardPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (upNextTracks.isEmpty) return const SizedBox.shrink();

    final effectiveTitleStyle = titleStyle ??
        Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold);
    final effectiveCardTextStyle =
        cardTextStyle ?? Theme.of(context).textTheme.bodySmall;
    final effectiveCardItemSize = cardItemSize ?? const Size(100, 150);
    final effectiveCardBackgroundColor = cardBackgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final effectiveCardPadding = cardPadding ?? const EdgeInsets.all(8.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: 16.0, bottom: 8.0), // Theming for this padding?
          child: Text('Up Next', style: effectiveTitleStyle),
        ),
        SizedBox(
          height: effectiveCardItemSize.height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upNextTracks.length,
            itemBuilder: (context, index) {
              final track = upNextTracks[index];
              return Container(
                width: effectiveCardItemSize.width,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: cardDecoration ??
                    BoxDecoration(
                        color: effectiveCardBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]),
                child: InkWell(
                  onTap: () => onTrackSelected(track),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: effectiveCardPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppCachedNetworkImage(
                            url: track.imageUrl,
                            width: effectiveCardItemSize.width *
                                0.6, // Relative size
                            height: effectiveCardItemSize.width * 0.6,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: effectiveCardItemSize.height * 0.05),
                        Text(
                          track.title,
                          style: effectiveCardTextStyle,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
