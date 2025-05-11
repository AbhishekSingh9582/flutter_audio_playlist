import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/utils/extension.dart';
import 'package:flutter_audio_playlist/src/widgets/app_cached_network.dart';
import 'package:provider/provider.dart';
import '../providers/audio_playlist_provider.dart';
import '../utils/format_duration.dart';
import '../enums/playback_mode.dart';

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
  void _showSleepTimerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final provider = Provider.of<AudioPlaylistProvider>(context);
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.sleepTimer != null)
                Text('Time left: ${formatDuration(provider.sleepTimer!)}'),
              ...widget.sleepTimerOptions.map((duration) => ListTile(
                    title: Text('${duration.inMinutes} minutes'),
                    onTap: () {
                      provider.setSleepTimer(duration);
                      Navigator.pop(context);
                    },
                  )),
              if (provider.sleepTimer != null)
                TextButton(
                  onPressed: () {
                    provider.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel Timer'),
                ),
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
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Consumer<AudioPlaylistProvider>(
      builder: (context, provider, child) {
        if (provider.currentTrack == null) {
          return const Scaffold(
            body: Center(child: Text('No track selected')),
          );
        }

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: statusBarHeight,
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 15),
                    child: Row(
                      children: [
                        InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(Icons.arrow_back_ios_new)),
                      ],
                    )),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AppCachedNetworkImage(
                              url: provider.currentTrack!.imageUrl,
                              width: width,
                              height: width,
                              fit: BoxFit.cover,
                            ),
                          ),
                          16.toVerticalSizedBox,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                provider.currentTrack!.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.enableSleepTimer)
                                IconButton(
                                  icon: const Icon(Icons.timer),
                                  onPressed: () =>
                                      _showSleepTimerBottomSheet(context),
                                ),
                            ],
                          ),
                          Text(
                            provider.currentTrack!.subtitle,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: provider.position.inMilliseconds.toDouble(),
                      max: (provider.totalDuration?.inMilliseconds ?? 1)
                          .toDouble(),
                      onChanged: (value) =>
                          provider.seek(Duration(milliseconds: value.toInt())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatDuration(provider.position)),
                          Text(formatDuration(
                              provider.totalDuration ?? Duration.zero)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.enableShuffle)
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color:
                                  provider.playbackMode == PlaybackMode.shuffle
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                            onPressed: () => provider
                                .togglePlaybackMode(PlaybackMode.shuffle),
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              onPressed: provider.playPrevious,
                            ),
                            IconButton(
                              iconSize: 64,
                              icon: Icon(
                                provider.isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                              ),
                              onPressed: provider.togglePlayPause,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: provider.playNext,
                            ),
                          ],
                        ),
                        if (widget.enableRepeat)
                          IconButton(
                            icon: Icon(
                              provider.playbackMode == PlaybackMode.repeat
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                              color:
                                  provider.playbackMode == PlaybackMode.repeat
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                            onPressed: () => provider
                                .togglePlaybackMode(PlaybackMode.repeat),
                          ),
                      ],
                    ),
                  ],
                ),
                if (widget.enableUpNext && provider.upNextTracks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Up Next',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.upNextTracks.length,
                            itemBuilder: (context, index) {
                              final track = provider.upNextTracks[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  onTap: () => provider.playTrack(track),
                                  child: Column(
                                    children: [
                                      AppCachedNetworkImage(
                                        url: track.imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                      Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
