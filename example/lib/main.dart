import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/flutter_video_playlist.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

void main() async{
  // It's good practice to initialize services like JustAudioBackground if your
  // AudioPlayerService uses it, before runApp.
  // Example: await JustAudioBackground.init(...);
    await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlaylistProvider(),
      // You can wrap your MaterialApp with AudioPlayerTheme to provide a global
      // theme for all player instances, or apply themes individually.
      child: AudioPlayerTheme(
        data: const AudioPlayerThemeData(
            // Example of a global theme setting (can be overridden locally)
            // screenBackgroundColor: Colors.grey[900],
            // primaryContentColor: Colors.white,
            // titleTextStyle: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
        child: MaterialApp(
          title: 'Audio Player Package Example',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            iconTheme: const IconThemeData(
              color: Colors.deepPurple,
              size: 24.0,
            ),
            fontFamily: 'Roboto', // Example font
          ),
          debugShowCheckedModeBanner: false,
          // Define routes for different demonstration screens
          routes: {
            '/': (context) => const HomeScreen(),
            '/defaultPlayerList': (context) => const PlaylistScreen(
                  playerRoute: '/defaultPlayerInstance',
                ),
            '/defaultPlayerInstance': (context) => const AudioPlayerScreen(
                // This instance will pick up the global AudioPlayerTheme
                // or use its internal defaults if no global theme is set.
                ),
            '/themedPlayerList': (context) => const PlaylistScreen(
                  playerRoute: '/themedPlayerInstance',
                  // Pass a specific theme for the banner on this screen
                  bannerTheme: AudioPlayerThemeData(
                    bannerBackgroundColor: Colors.teal,
                    primaryContentColor: Colors.white,
                  ),
                ),
            '/themedPlayerInstance': (context) => const AudioPlayerScreen(
                  // This instance uses a specific theme, overriding any global theme.
                  theme: AudioPlayerThemeData(
                    screenBackgroundColor: Colors.indigo,
                    screenBackgroundGradient: LinearGradient(
                      colors: [Colors.indigo, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    primaryContentColor: Colors.white,
                    secondaryContentColor: Colors.white70,
                    titleTextStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    subtitleTextStyle:
                        TextStyle(fontSize: 16, color: Colors.white70),
                    progressSliderActiveColor: Colors.amber,
                    progressSliderThumbColor: Colors.amberAccent,
                    controlButtonColor: Colors.white,
                    playPauseButtonColor: Colors.amber,
                    activeControlButtonColor: Colors.amberAccent,
                    showUpNextSection: true,
                    upNextCardBackgroundColor: Colors.white12,
                  ),
                ),
            '/customUIPlayer': (context) => const CustomPlayerUIScreen(),
            '/standaloneComponents': (context) =>
                const StandaloneComponentsDemoScreen(),
          },
          initialRoute: '/',
        ),
      ),
    );
  }
}

/// HomeScreen: Provides navigation to different demo scenarios.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize tracks once when HomeScreen is built.
    // In a real app, this might be done in a splash screen or an init provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AudioPlaylistProvider>(context, listen: false);
      if (provider.tracks.isEmpty) {
        // Load tracks only if not already loaded
        _initializeTracks(provider);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Player Demos')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Default Player'),
            subtitle: const Text(
                'Uses default AudioPlayerScreen and CurrentTrackBanner.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/defaultPlayerList'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Themed Player'),
            subtitle: const Text(
                'Customizes AudioPlayerScreen via AudioPlayerThemeData.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/themedPlayerList'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Custom UI Player'),
            subtitle: const Text(
                'Builds a player UI using individual package components.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/customUIPlayer'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Standalone Components'),
            subtitle: const Text(
                'Demonstrates using components like ControlsSection independently.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/standaloneComponents'),
          ),
        ],
      ),
    );
  }
}

/// PlaylistScreen: Displays a list of audio tracks using AudioTile.
/// Tapping a tile plays the track. Includes CurrentTrackBanner.
class PlaylistScreen extends StatelessWidget {
  final String playerRoute; // Route to navigate to when banner is tapped
  final AudioPlayerThemeData? bannerTheme; // Optional theme for the banner

  const PlaylistScreen({
    super.key,
    required this.playerRoute,
    this.bannerTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track List')),
      body: Column(
        children: [
          Expanded(
            // Use Selector to only rebuild the ListView when the tracks list itself changes.
            // Individual AudioTiles will manage their own state updates.
            child: Consumer<AudioPlaylistProvider>(
              // Consumer to ensure tracks are loaded
              builder: (context, provider, child) {
                if (provider.tracks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: provider.tracks.length,
                  itemBuilder: (context, index) {
                    final track = provider.tracks[index];
                    // AudioTile displays each track and handles tap-to-play.
                    return AudioTile(
                      key: ValueKey(track.id), // Important for list performance
                      track: track,
                      // Example of customizing AudioTile appearance
                      titleTextStyle:
                          const TextStyle(fontWeight: FontWeight.w500),
                      subtitleTextStyle: TextStyle(color: Colors.grey[600]),
                      playingTitleTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    );
                  },
                );
              },
            ),
          ),
          // CurrentTrackBanner shows the currently playing track and navigates to the player.
          CurrentTrackBanner(
            playerScreenRoute: playerRoute,
            theme: bannerTheme, // Apply specific theme to this banner instance
          ),
        ],
      ),
    );
  }
}

/// CustomPlayerUIScreen: Demonstrates building a custom player UI
/// using individual components from the package.
class CustomPlayerUIScreen extends StatelessWidget {
  const CustomPlayerUIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get live updates for the UI components.
    final audioProvider = context.watch<AudioPlaylistProvider>();
    final currentTrack = audioProvider.currentTrack;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define a specific theme for this custom screen's components
    const customComponentTheme = AudioPlayerThemeData(
      primaryContentColor: Colors.white,
      secondaryContentColor: Colors.white70,
      titleTextStyle: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      subtitleTextStyle: TextStyle(fontSize: 15, color: Colors.white70),
      progressSliderActiveColor: Colors.redAccent,
      progressSliderThumbColor: Colors.red,
      controlButtonColor: Colors.white,
      playPauseButtonColor: Colors.redAccent,
      activeControlButtonColor: Colors.red,
      upNextCardBackgroundColor: Colors.black38,
      upNextCardTextStyle: TextStyle(color: Colors.white, fontSize: 12),
    );

    if (currentTrack == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Custom UI Player')),
        body: const Center(
            child: Text('No track selected. Play a track from a list first.')),
      );
    }

    return Scaffold(
      // Apply a theme specifically for the components used in this custom screen
      body: AudioPlayerTheme(
        data: customComponentTheme,
        child: Container(
          // Example custom background
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[850]!, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Using PlayerBackButton (assuming it's exported)
                    Align(
                      alignment: Alignment.topLeft,
                      child: PlayerBackButton(
                          color: customComponentTheme.primaryContentColor),
                    ),
                    const SizedBox(height: 20),
                    // Using TrackDetailsSection
                    TrackDetailsSection(
                      track: currentTrack,
                      imageWidth: screenWidth * 0.7,
                      imageHeight: screenWidth * 0.7,
                      albumArtBorderRadius: 20,

                      titleTextStyle: customComponentTheme.titleTextStyle,
                      subtitleTextStyle: customComponentTheme.subtitleTextStyle,
                      showSleepTimerButton: true, // Enable sleep timer
                      sleepTimerIconColor:
                          customComponentTheme.primaryContentColor,
                      onSleepTimerPressed: () {
                        // Example: Manually show a sleep timer dialog or bottom sheet
                        // This part would require you to implement _showSleepTimerBottomSheet
                        // or a similar utility if you want the exact same behavior as AudioPlayerScreen.
                        // For simplicity, we'll just log here.
                        print("Sleep timer pressed on custom screen");
                        // You could call a method similar to _showSleepTimerBottomSheet from AudioPlayerScreen
                        // by passing necessary context and provider.
                      },
                    ),
                    const SizedBox(height: 30),
                    // Using ProgressBarSection
                    ProgressBarSection(
                      position: audioProvider.position,
                      totalDuration: audioProvider.totalDuration,
                      onSeek: audioProvider.seek,
                      sliderThemeData: SliderTheme.of(context).copyWith(
                        activeTrackColor:
                            customComponentTheme.progressSliderActiveColor,
                        inactiveTrackColor: customComponentTheme
                            .progressSliderActiveColor
                            ?.withOpacity(0.3),
                        thumbColor:
                            customComponentTheme.progressSliderThumbColor,
                      ),
                      timeTextStyle: TextStyle(
                          color: customComponentTheme.secondaryContentColor),
                    ),
                    const SizedBox(height: 20),
                    // Using ControlsSection
                    ControlsSection(
                      isPlaying: audioProvider.isPlaying,
                      isShuffling: audioProvider.isShuffling,
                      repeatMode: audioProvider.repeatMode,
                      onPlayPause: audioProvider.togglePlayPause,
                      onSkipNext: audioProvider.playNext,
                      onSkipPrevious: audioProvider.playPrevious,
                      onToggleShuffle: audioProvider.toggleShuffleMode,
                      onCycleRepeatMode: audioProvider.cycleRepeatMode,
                      controlButtonColor:
                          customComponentTheme.controlButtonColor,
                      playPauseButtonColor:
                          customComponentTheme.playPauseButtonColor,
                      activeControlButtonColor:
                          customComponentTheme.activeControlButtonColor,
                      inactiveControlButtonColor:
                          customComponentTheme.secondaryContentColor,
                    ),
                    const SizedBox(height: 30),
                    // Using UpNextSection (if tracks are available)
                    if (audioProvider.upNextTracks.isNotEmpty)
                      UpNextSection(
                        upNextTracks: audioProvider.upNextTracks,
                        onTrackSelected: audioProvider.playTrack,
                        titleStyle: customComponentTheme.titleTextStyle
                            ?.copyWith(fontSize: 18),
                        cardTextStyle: customComponentTheme.upNextCardTextStyle,
                        cardBackgroundColor:
                            customComponentTheme.upNextCardBackgroundColor,
                        cardItemSize: const Size(120, 180), // Custom size
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// StandaloneComponentsDemoScreen: Demonstrates using one or two components
/// like ControlsSection independently.
class StandaloneComponentsDemoScreen extends StatelessWidget {
  const StandaloneComponentsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get live data for the standalone component.
    final audioProvider = context.watch<AudioPlaylistProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Standalone Controls Demo')),
      body: Center(
        child: audioProvider.currentTrack == null
            ? const Text(
                'No track selected. Play a track from a list first to see controls.')
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Now Playing: ${audioProvider.currentTrack!.title}',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Using ControlsSection standalone with custom styling.
                    ControlsSection(
                      isPlaying: audioProvider.isPlaying,
                      isShuffling: audioProvider.isShuffling,
                      repeatMode: audioProvider.repeatMode,
                      onPlayPause: audioProvider.togglePlayPause,
                      onSkipNext: audioProvider.playNext,
                      onSkipPrevious: audioProvider.playPrevious,
                      onToggleShuffle: audioProvider.toggleShuffleMode,
                      onCycleRepeatMode: audioProvider.cycleRepeatMode,
                      // Custom styling for this standalone instance
                      controlButtonColor: Colors.green,
                      playPauseButtonColor: Colors.lightGreenAccent,
                      activeControlButtonColor: Colors.greenAccent,
                      inactiveControlButtonColor: Colors.grey,
                      controlButtonSize: 40,
                      playPauseButtonSize: 70,
                      showShuffleButton: true,
                      showRepeatButton: true,
                    ),
                    const SizedBox(height: 30),
                    ProgressBarSection(
                      position: audioProvider.position,
                      totalDuration: audioProvider.totalDuration,
                      onSeek: audioProvider.seek,
                      sliderThemeData: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.green,
                        thumbColor: Colors.greenAccent,
                      ),
                      timeTextStyle: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Helper function to initialize tracks (simulates fetching data)
void _initializeTracks(AudioPlaylistProvider provider) {
  final tracks = [
    AudioTrack(
      id: '1',
      title: 'Ambient Dreams',
      subtitle: 'Nature Sounds',
      audioUrl:
          'https://d1ass895x5m7xs.cloudfront.net/Test/music/om+namah+shivaya+final+MASTER+2.wav',
      imageUrl:
          'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/om+namah+shivay.jpg',
      duration: const Duration(minutes: 2, seconds: 30),
    ),
    AudioTrack(
      id: '2',
      title: 'Cosmic Journey',
      subtitle: 'Space Ambient',
      audioUrl:
          'https://d1ass895x5m7xs.cloudfront.net/Test/music/hare+krishna+hare+rama+FINAL+MASTER+4.wav',
      imageUrl:
          'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/hare+krishna+hare+rama.jpg',
      duration: const Duration(minutes: 3, seconds: 15),
    ),
    AudioTrack(
      id: '3',
      title: 'Mystic Flute',
      subtitle: 'Meditation Sounds',
      audioUrl:
          'https://d1ass895x5m7xs.cloudfront.net/Test/music/lingashtakam+final+1.wav',
      imageUrl:
          'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/Lingastkam.jpg',
      duration: const Duration(minutes: 4, seconds: 5),
    ),
    AudioTrack(
      id: '4',
      title: 'Ocean Waves',
      subtitle: 'Relaxation Mix',
      audioUrl:
          'https://d1ass895x5m7xs.cloudfront.net/Test/music/nemastasya+namoh+nmaah+final+mater+2.wav',
      imageUrl:
          'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/namastasya+namo+namah.jpg',
      duration: const Duration(minutes: 1, seconds: 55),
    ),
  ];
  provider.setTracks(tracks);
}
