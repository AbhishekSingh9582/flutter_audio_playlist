import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/utils/extension.dart';
import 'package:flutter_audio_playlist/src/theme/audio_player_theme_data.dart';
import 'package:flutter_audio_playlist/src/widgets/app_cached_network.dart';
import 'package:provider/provider.dart';
import '../providers/audio_playlist_provider.dart';
import '../models/audio_track.dart';
import '../utils/format_duration.dart';
import '../enums/repeat_mode.dart';

/// A screen that provides a pre-built UI for audio playback.
///
/// This screen displays track details, playback controls, progress bar,
/// and an "Up Next" section. It is highly customizable through the [theme]
/// property or by providing a [customPlayerScreen].
///
/// It interacts with [AudioPlaylistProvider] to manage and reflect the audio playback state.
///
/// Example:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => AudioPlayerScreen(
///       theme: AudioPlayerThemeData(
///         screenBackgroundColor: Colors.blueGrey,
///         titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
///       ),
///     ),
///   ),
/// );
/// ```
class AudioPlayerScreen extends StatefulWidget {
  /// Optional theme data to customize the appearance of the audio player screen.
  /// If not provided, it will try to use `AudioPlayerTheme.of(context)` or default styles
  /// defined within [AudioPlayerThemeData].
  final AudioPlayerThemeData? theme;

  /// An optional custom widget to display as the entire player screen.
  /// If provided, this widget will be used instead of the default UI built by
  /// [DefaultAudioPlayerScreenBody]. This allows for complete UI replacement
  /// while still leveraging the navigation to this screen.
  final Widget? customPlayerScreen;

  /// A list of [Duration] options to be displayed in the sleep timer bottom sheet.
  /// Defaults to 2, 5, 10, and 15 minutes.
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
  // Shows a modal bottom sheet for selecting or cancelling a sleep timer.
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
                    // Display each sleep timer option.
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
    // If a custom screen is provided, display it directly.
    if (widget.customPlayerScreen != null) return widget.customPlayerScreen!;
    final width = MediaQuery.of(context).size.width;
    // Resolve the theme:
    // 1. Use the theme passed directly to the widget.
    // 2. If not available, try to find an AudioPlayerTheme higher in the widget tree.
    // 3. Fallback to a default AudioPlayerThemeData if none is found.
    final theme = widget.theme ??
        AudioPlayerTheme.of(context) ??
        const AudioPlayerThemeData();

    return Selector<AudioPlaylistProvider, AudioTrack?>(
      // Rebuild the screen body only when the current track changes or becomes null.
      selector: (_, provider) => provider.currentTrack,
      builder: (context, currentTrack, child) {
        if (currentTrack == null) {
          // Display a message if no track is currently playing.
          return const Scaffold(
            body: Center(child: Text('No track currently playing')),
          );
        }
        // DefaultAudioPlayerScreenBody will use context.watch internally for other state changes.
        // However, actions like setting sleep timer still need a provider instance.
        final audioProviderForActions = context.watch<AudioPlaylistProvider>();

        return DefaultAudioPlayerScreenBody(
          theme: theme,
          width: width,
          currentTrack: currentTrack,
          // Pass the provider instance that DefaultAudioPlayerScreenBody will watch.
          // This ensures DefaultAudioPlayerScreenBody rebuilds on relevant state changes.
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
///
/// It receives an [AudioPlaylistProvider] instance (obtained via `context.watch` by its parent)
/// to get live updates for playback state (e.g., position, isPlaying)
/// and passes this data down to its child components.
class DefaultAudioPlayerScreenBody extends StatelessWidget {
  /// The theme data for styling the player screen.
  final AudioPlayerThemeData theme;

  /// The width of the screen, used for responsive image sizing.
  final double width;

  /// The currently playing audio track.
  final AudioTrack currentTrack;

  /// The audio playlist provider, watched by the parent, to access state and actions.
  final AudioPlaylistProvider audioPlaylistProvider;

  /// Callback to show the sleep timer bottom sheet.
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

    // Use the dominant color from the provider, which is already being watched by the parent.
    final dominantColor = context.select<AudioPlaylistProvider, Color?>(
        (p) => p.currentTrackDominantColor);

    Color effectivePrimaryContentColor;
    Color effectiveSecondaryContentColor;
    Gradient effectiveBackgroundGradient;
    Color effectiveBackgroundColor;

    // Determine colors and gradients based on theme settings and dominant color.
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
          Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()); // Adjusted for typical secondary opacity
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
        // Apply primary content color to default icon themes if not overridden by specific theme properties.
        iconTheme: Theme.of(context)
            .iconTheme
            .copyWith(color: theme.primaryContentColor),
        // Apply primary content color to default text themes if not overridden by specific theme properties.
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: theme.primaryContentColor,
              displayColor: theme.primaryContentColor,
            ),
      ),
      child: Scaffold(
        backgroundColor: effectiveBackgroundColor,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrackDetailsSection(
                      track: currentTrack,
                      imageWidth: width -
                          (theme.screenPadding?.horizontal ??
                              40), // Adjust for padding
                      imageHeight:
                          width - (theme.screenPadding?.horizontal ?? 40),
                      screenPadding: theme.screenPadding,
                      titleTextStyle: theme.titleTextStyle ??
                          TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: effectivePrimaryContentColor),
                      subtitleTextStyle: theme.subtitleTextStyle ??
                          TextStyle(color: effectiveSecondaryContentColor),
                      albumArtBorderRadius: theme.albumArtBorderRadius ?? 16.0,
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
                      screenPadding: theme.screenPadding,
                      sliderThemeData: theme.sliderThemeData ??
                          SliderTheme.of(context).copyWith(
                            // Use the theme's progressSliderActiveColor if available
                            activeTrackColor: theme.progressSliderActiveColor ??
                                effectivePrimaryContentColor,
                            inactiveTrackColor: theme
                                    .progressSliderInactiveColor ?? // Assuming you might add this later
                                effectiveSecondaryContentColor.withAlpha((0.3 * 255).round()),
                            // Use the theme's progressSliderThumbColor if available
                            thumbColor: theme.progressSliderThumbColor ??
                                effectivePrimaryContentColor,
                            overlayColor: (theme.progressSliderActiveColor ??
                                    effectivePrimaryContentColor)
                                .withAlpha((0.2 * 255).round()),
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
                      onToggleShuffle: audioPlaylistProvider.toggleShuffleMode,
                      onCycleRepeatMode: audioPlaylistProvider.cycleRepeatMode,
                      showShuffleButton: theme.showShuffleButton,
                      showRepeatButton: theme.showRepeatButton,
                      controlButtonSize: theme.controlButtonSize ?? 36,
                      playPauseButtonSize: theme.playPauseButtonSize ?? 64,
                      screenPadding: theme.screenPadding,
                      controlButtonColor: theme.controlButtonColor ??
                          effectivePrimaryContentColor,
                      activeControlButtonColor:
                          theme.activeControlButtonColor ??
                              (dominantColor ??
                                  Theme.of(context).colorScheme.primary),
                      inactiveControlButtonColor: theme.secondaryContentColor ??
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
                            Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: effectivePrimaryContentColor),
                        cardDecoration: theme.upNextCardDecoration,
                        cardItemSize: theme.upNextCardItemSize ?? const Size(100,150), // Ensure default if null
                        cardBackgroundColor: theme.upNextCardBackgroundColor ??
                            effectiveSecondaryContentColor.withAlpha((0.2 * 255).round()),
                        cardPadding: theme.upNextCardPadding,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable back button widget, typically used at the top of the player screen.
///
/// Allows customization of the icon, color, and onPressed behavior.
class PlayerBackButton extends StatelessWidget {
  /// The icon to display. Defaults to [Icons.arrow_back_ios_new].
  final IconData? icon;

  /// The color of the icon. Defaults to the ambient [IconThemeData.color].
  final Color? color;

  /// The callback to be invoked when the button is pressed.
  /// Defaults to `Navigator.pop(context)`.
  final VoidCallback? onPressed;

  /// Creates a player back button.
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

/// A widget that displays the details of an [AudioTrack].
///
/// This includes the album art, title, subtitle, and an optional sleep timer button.
/// Styling can be customized via constructor parameters.
class TrackDetailsSection extends StatelessWidget {
  /// The audio track whose details are to be displayed.
  final AudioTrack track;

  /// The width of the album art image.
  final double imageWidth;

  /// The height of the album art image.
  final double imageHeight;

  /// The text style for the track title.
  final TextStyle? titleTextStyle;

  /// The text style for the track subtitle (e.g., artist name).
  final TextStyle? subtitleTextStyle;

  /// The border radius for the album art image. Defaults to 16.0.
  final double albumArtBorderRadius;

  /// Whether to show the sleep timer button. Defaults to true.
  final bool showSleepTimerButton;

  /// The color of the sleep timer icon.
  final Color? sleepTimerIconColor;

  /// Callback invoked when the sleep timer button is pressed.
  final VoidCallback? onSleepTimerPressed;

  final EdgeInsetsGeometry? screenPadding;

  /// Creates a track details section.
  ///
  /// Requires [track], [imageWidth], and [imageHeight].
  /// Other parameters are optional and provide styling customization.
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
    this.screenPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve effective text styles, falling back to theme defaults if not provided.
    final effectiveTitleStyle = titleTextStyle ??
        Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold);
    final effectiveSubtitleStyle =
        subtitleTextStyle ?? Theme.of(context).textTheme.titleMedium;

    return Padding(
      padding: screenPadding ?? const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
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
      ),
    );
  }
}

/// A widget that displays the audio playback progress bar, current position,
/// and total duration.
///
/// Allows users to seek to a specific position by interacting with the slider.
/// Styling for the slider and text can be customized.
class ProgressBarSection extends StatelessWidget {
  /// The current playback position.
  final Duration position;

  /// The total duration of the current track. Can be null if duration is not yet known.
  final Duration? totalDuration;

  /// Callback invoked when the user seeks to a new position using the slider.
  final ValueChanged<Duration> onSeek;

  /// Custom theme data for the slider.
  final SliderThemeData? sliderThemeData;

  /// Custom text style for the time indicators (current position and total duration).
  final TextStyle? timeTextStyle;

  final EdgeInsetsGeometry? screenPadding;

  /// Creates a progress bar section.
  const ProgressBarSection({
    super.key,
    required this.position,
    this.totalDuration,
    required this.onSeek,
    this.sliderThemeData,
    this.timeTextStyle,
    this.screenPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve slider theme and text style, falling back to context theme if not provided.
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
          // To align time labels with the slider ends (which respect screenPadding), set internal horizontal padding to zero.
          padding: screenPadding ?? const EdgeInsets.symmetric(horizontal: 20),
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

/// A widget that provides playback control buttons.
///
/// Includes buttons for play/pause, skip next, skip previous, shuffle, and repeat.
/// The visibility, size, and color of these buttons can be customized.
class ControlsSection extends StatelessWidget {
  /// Whether the audio is currently playing.
  final bool isPlaying;

  /// Whether shuffle mode is active.
  final bool isShuffling;

  /// The current repeat mode ([RepeatMode.off], [RepeatMode.repeatOnce], [RepeatMode.repeatCurrent]).
  final RepeatMode repeatMode;

  /// Callback invoked when the play/pause button is pressed.
  final VoidCallback onPlayPause;

  /// Callback invoked when the skip next button is pressed.
  final VoidCallback onSkipNext;

  /// Callback invoked when the skip previous button is pressed.
  final VoidCallback onSkipPrevious;

  /// Callback invoked when the shuffle button is pressed.
  final VoidCallback onToggleShuffle;

  /// Callback invoked when the repeat button is pressed, cycling through repeat modes.
  final VoidCallback onCycleRepeatMode;

  /// Whether to show the shuffle button. Defaults to true.
  final bool showShuffleButton;

  /// Whether to show the repeat button. Defaults to true.
  final bool showRepeatButton;

  /// The size for standard control buttons (skip, shuffle, repeat). Defaults to 36.0.
  final double controlButtonSize;

  /// The size for the play/pause button. Defaults to 64.0.
  final double playPauseButtonSize;

  /// The color for general control button icons (e.g., skip next/previous).
  /// Defaults to the ambient [IconThemeData.color].
  final Color? controlButtonColor;

  /// The color for control buttons when they are in an active state (e.g., shuffle on, repeat on).
  /// Defaults to [ColorScheme.primary].
  final Color? activeControlButtonColor;

  /// The color for control buttons when they are in an inactive state (e.g., shuffle off, repeat off).
  /// Defaults to [ThemeData.disabledColor].
  final Color? inactiveControlButtonColor;

  /// The color for the play/pause button icon.
  /// Defaults to the ambient [IconThemeData.color].
  final Color? playPauseButtonColor;

  /// Padding around widget
  final EdgeInsetsGeometry? screenPadding;

  /// Creates a controls section.
  const ControlsSection(
      {super.key,
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
      this.screenPadding});

  @override
  Widget build(BuildContext context) {
    // Resolve effective colors for buttons, falling back to theme defaults.
    final effectiveControlButtonColor =
        controlButtonColor ?? Theme.of(context).iconTheme.color;
    final effectiveActiveColor =
        activeControlButtonColor ?? Theme.of(context).colorScheme.primary;
    final effectiveInactiveColor =
        inactiveControlButtonColor ?? Theme.of(context).disabledColor;
    final effectivePlayPauseButtonColor =
        playPauseButtonColor ?? Theme.of(context).iconTheme.color;

    return Padding(
      // To align controls with TrackDetailsSection content (respecting screenPadding), set internal horizontal padding to zero.
      padding: screenPadding ?? const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showShuffleButton)
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.shuffle,
                color:
                    isShuffling ? effectiveActiveColor : effectiveInactiveColor,
              ),
              iconSize: controlButtonSize * 0.8,
              onPressed: onToggleShuffle,
            )
          else
            const SizedBox(width: 48),
          IconButton(
            padding: EdgeInsets.zero,
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
            // Repeat button, icon changes based on current repeat mode.
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

/// A widget that displays a horizontal list of upcoming tracks.
///
/// Each track is shown as a card with album art and title.
/// Tapping a card triggers playback of that track.
/// Styling for the section title and track cards can be customized.
class UpNextSection extends StatelessWidget {
  /// The list of audio tracks to be displayed as "Up Next".
  final List<AudioTrack> upNextTracks;

  /// Callback invoked when an "Up Next" track card is tapped.
  final ValueChanged<AudioTrack> onTrackSelected;

  /// The text style for the "Up Next" section title.
  final TextStyle? titleStyle;

  /// The text style for the track title within each card.
  final TextStyle? cardTextStyle;

  /// The decoration for each track card.
  final BoxDecoration? cardDecoration;

  /// The size (width and height) for each track card. Defaults to Size(100, 150).
  final Size? cardItemSize;

  /// The background color for each track card.
  /// Overridden by [cardDecoration] if both are provided.
  final Color? cardBackgroundColor;

  /// The padding inside each track card. Defaults to EdgeInsets.all(8.0).
  final EdgeInsetsGeometry? cardPadding;

  /// Creates an "Up Next" section.
  ///
  /// Requires [upNextTracks] and [onTrackSelected].
  /// Other parameters are optional for styling.

  /// Screen padding
  final EdgeInsetsGeometry? screenPadding;

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
    this.screenPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Do not build the section if there are no upcoming tracks.
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
        Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round());
    final effectiveCardPadding = cardPadding ?? const EdgeInsets.all(8.0);

    return Padding(
      padding: screenPadding ?? const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 16.0, bottom: 8.0), // Theming for this padding?
            child: Text('Up Next', style: effectiveTitleStyle),
          ),
          SizedBox(
            // Constrain the height of the horizontal list.
            height: effectiveCardItemSize.height,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: upNextTracks.length,
              itemBuilder: (context, index) {
                final track = upNextTracks[index];
                // Build each track card.
                return Container(
                  width: effectiveCardItemSize.width,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: cardDecoration ??
                      BoxDecoration(
                          color: effectiveCardBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black..withAlpha((0.1 * 255).round()),
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
      ),
    );
  }
}
