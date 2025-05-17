import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/utils/extension.dart';
import 'package:flutter_audio_playlist/src/widgets/app_cached_network.dart';
import 'package:provider/provider.dart';
import '../providers/audio_playlist_provider.dart';
import '../models/audio_track.dart';
import '../utils/format_duration.dart';
import '../enums/repeat_mode.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Widget? customPlayerScreen;
  final bool enableShuffle;
  final bool enableRepeat;
  final bool enableSleepTimer;
  final bool enableUpNext;
  final List<Duration> sleepTimerOptions;

  const AudioPlayerScreen({
    super.key,
    this.customPlayerScreen,
    this.enableShuffle = true,
    this.enableRepeat = true,
    this.enableSleepTimer = true,
    this.enableUpNext = true,
    this.sleepTimerOptions = const [
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
    ],
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  void _showSleepTimerBottomSheet(
      BuildContext modalContext, AudioPlaylistProvider providerForActions) {
    showModalBottomSheet(
      context: modalContext,
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
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              ...widget.sleepTimerOptions.map((duration) => ListTile(
                    title: Text('${duration.inMinutes} minutes'),
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
                        child: const Text('Cancel Timer'),
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

    return Selector<AudioPlaylistProvider, AudioTrack?>(
      selector: (_, provider) => provider.currentTrack,
      builder: (context, currentTrack, child) {
        if (currentTrack == null) {
          return const Scaffold(
            body: Center(child: Text('No track currently playing')),
          );
        }

        final audioProviderForActions = context.read<AudioPlaylistProvider>();

        return _AudioPlayerScreenBody(
          width: width,
          enableShuffle: widget.enableShuffle,
          enableRepeat: widget.enableRepeat,
          enableSleepTimer: widget.enableSleepTimer,
          enableUpNext: widget.enableUpNext,
          showSleepTimerBottomSheet: (bottomSheetLauncherContext) =>
              _showSleepTimerBottomSheet(
                  bottomSheetLauncherContext, audioProviderForActions),
        );
      },
    );
  }
}

class _AudioPlayerScreenBody extends StatelessWidget {
  final double width;
  final bool enableShuffle;
  final bool enableRepeat;
  final bool enableSleepTimer;
  final bool enableUpNext;
  final Function(BuildContext) showSleepTimerBottomSheet;

  const _AudioPlayerScreenBody({
    required this.width,
    required this.enableShuffle,
    required this.enableRepeat,
    required this.enableSleepTimer,
    required this.enableUpNext,
    required this.showSleepTimerBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: statusBarHeight),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new),
              ),
            ),
            _TrackDetailsSection(
              width: width,
              enableSleepTimer: enableSleepTimer,
              showSleepTimerBottomSheet: () =>
                  showSleepTimerBottomSheet(context),
            ),
            16.toVerticalSizedBox,
            const _ProgressBarSection(),
            _ControlsSection(
              enableShuffle: enableShuffle,
              enableRepeat: enableRepeat,
            ),
            if (enableUpNext) const _UpNextSection(),
          ],
        ),
      ),
    );
  }
}

class _TrackDetailsSection extends StatelessWidget {
  final double width;
  final bool enableSleepTimer;
  final VoidCallback showSleepTimerBottomSheet;

  const _TrackDetailsSection({
    required this.width,
    required this.enableSleepTimer,
    required this.showSleepTimerBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    final currentTrack = context
        .select<AudioPlaylistProvider, AudioTrack?>((p) => p.currentTrack);
    if (currentTrack == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AppCachedNetworkImage(
              url: currentTrack.imageUrl,
              width: width,
              height: width,
              fit: BoxFit.cover,
            ),
          ),
          16.toVerticalSizedBox,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTrack.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentTrack.subtitle,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (enableSleepTimer)
                IconButton(
                  icon: const Icon(Icons.timer_outlined),
                  onPressed: showSleepTimerBottomSheet,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBarSection extends StatelessWidget {
  const _ProgressBarSection();

  @override
  Widget build(BuildContext context) {
    final position =
        context.select<AudioPlaylistProvider, Duration>((p) => p.position);
    final totalDuration = context
        .select<AudioPlaylistProvider, Duration?>((p) => p.totalDuration);
    final provider = context.read<AudioPlaylistProvider>();

    return Column(
      children: [
        Slider(
          value: position.inMilliseconds
              .toDouble()
              .clamp(0.0, (totalDuration?.inMilliseconds ?? 1).toDouble()),
          max: (totalDuration?.inMilliseconds ?? 1).toDouble(),
          onChanged: (value) =>
              provider.seek(Duration(milliseconds: value.toInt())),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(position)),
              Text(formatDuration(totalDuration ?? Duration.zero)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlsSection extends StatelessWidget {
  final bool enableShuffle;
  final bool enableRepeat;

  const _ControlsSection(
      {required this.enableShuffle, required this.enableRepeat});

  @override
  Widget build(BuildContext context) {
    final repeatMode =
        context.select<AudioPlaylistProvider, RepeatMode>((p) => p.repeatMode);
    final isPlaying =
        context.select<AudioPlaylistProvider, bool>((p) => p.isPlaying);
    final isShuffling =
        context.select<AudioPlaylistProvider, bool>((p) => p.isShuffling);
    final audioProvider = context.read<AudioPlaylistProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (enableShuffle)
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color: isShuffling
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              onPressed: audioProvider.toggleShuffleMode,
            )
          else
            const SizedBox(width: 48),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 36,
            onPressed: audioProvider.playPrevious,
          ),
          IconButton(
            iconSize: 64,
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
              ),
            ),
            onPressed: audioProvider.togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 36,
            onPressed: audioProvider.playNext,
          ),
          if (enableRepeat)
            Builder(builder: (context) {
              // Use Builder to get context for Theme
              IconData icon;
              Color color;
              switch (repeatMode) {
                case RepeatMode.off:
                  icon = Icons.repeat;
                  color = Colors.grey;
                  break;
                case RepeatMode.repeatOnce:
                  icon = Icons.repeat_one;
                  color = Theme.of(context).colorScheme.primary;
                  break;
                case RepeatMode.repeatCurrent:
                  icon = Icons
                      .repeat_on; // Consider Icons.repeat if Icons.repeat_on is not available/preferred
                  color = Theme.of(context).colorScheme.primary;
                  break;
              }
              return IconButton(
                icon: Icon(icon, color: color),
                onPressed: audioProvider.cycleRepeatMode,
              );
            })
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _UpNextSection extends StatelessWidget {
  const _UpNextSection();

  @override
  Widget build(BuildContext context) {
    final upNextTracks = context
        .select<AudioPlaylistProvider, List<AudioTrack>>((p) => p.upNextTracks);
    final provider = context.read<AudioPlaylistProvider>();

    if (upNextTracks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Up Next',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          10.toVerticalSizedBox,
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: upNextTracks.length,
              itemBuilder: (context, index) {
                final track = upNextTracks[index];
                return Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () => provider.playTrack(track),
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppCachedNetworkImage(
                                url: track.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            8.toVerticalSizedBox,
                            Text(
                              track.title,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
