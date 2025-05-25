# Flutter Audio Playlist Player

[![pub package](https://img.shields.io/pub/v/flutter_audio_playlist.svg)](https://pub.dev/packages/flutter_audio_playlist) 
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A highly customizable Flutter audio player package that provides a pre-built player UI, individual player widgets, and robust state management for creating beautiful audio playback experiences.

This package allows you to quickly integrate a full-featured audio player screen or use its components to build your own custom player interface. It supports theming, background audio playback (via `just_audio_background`), playlist management, shuffle, repeat modes, and more.

## Features

*   **Pre-built Player Screen:** `AudioPlayerScreen` offers a ready-to-use UI with track details, progress bar, controls, and an "Up Next" section.
*   **Customizable UI:**
    *   Theme the player using `AudioPlayerTheme` and `AudioPlayerThemeData` (colors, text styles, slider themes, spacings, button styles).
    *   Show/hide optional sections like "Up Next".
    *   Provide your own custom screen widget for the player.
*   **Reusable Widgets:** Use individual components like `TrackDetailsSection`, `ControlsSection`, `ProgressBarSection`, `UpNextSection`, `AudioTile`, and `CurrentTrackBanner` independently in your custom layouts.
*   **State Management:** Built-in `AudioPlaylistProvider` (using `Provider` and `ChangeNotifier`) to manage playback state, playlist, current track, shuffle/repeat modes, etc.
*   **Background Audio:** Leverages `just_audio` and `just_audio_background` for background playback and notification controls.
*   **Playlist Functionality:** Load and manage playlists, play next/previous, shuffle, and repeat.
*   **Dominant Color Theming:** Optionally adapt the player background to the dominant color of the current track's artwork.
*   **Sleep Timer:** Built-in sleep timer functionality.

---

**(Optional: Add a GIF or Screenshots of your player here)**

<!-- Example:
<p align="center">
  <img src="https://path.to.your/screenshot1.png" width="200" alt="Screenshot 1">
  &nbsp; &nbsp; &nbsp;
  <img src="https://path.to.your/player_demo.gif" width="200" alt="Player Demo GIF">
</p>
-->

---

## Installation

1.  Add this to your package's `pubspec.yaml` file:

    ```yaml
    dependencies:
      flutter_audio_playlist: ^latest_version # Replace with the latest version
    ```

2.  Install packages from the command line:

    ```bash
    flutter pub get
    ```

## Setup

### 1. Initialize Background Audio

To enable background audio playback and lock screen controls, you need to initialize `just_audio_background`. Call this in your `main.dart` **before** `runApp()`:

```dart
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.mycompany.myapp.channel.audio', // Replace with your channel ID
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(MyApp());
}
```

### 2. Android Configuration

Modify your `android/app/src/main/AndroidManifest.xml`:

*   Add the `WAKE_LOCK` permission:
    ```xml
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    ```
*   Add the `FOREGROUND_SERVICE` permission (if targeting Android P or above):
    ```xml
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    ```
*   Inside the `<application>` tag, register the service for `just_audio_background`:
    ```xml
    <application ...>
      <activity ...>
        ...
      </activity>

      <!-- Add this service -->
      <service android:name="com.ryanheise.audioservice.AudioService"
          android:foregroundServiceType="mediaPlayback"
          android:exported="true">
        <intent-filter>
          <action android:name="android.media.browse.MediaBrowserService"/>
        </intent-filter>
      </service>

      <!-- Add this receiver -->
      <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
          android:exported="true">
        <intent-filter>
          <action android:name="android.intent.action.MEDIA_BUTTON"/>
        </intent-filter>
      </receiver>
    </application>
    ```

### 3. iOS Configuration

Modify your `ios/Runner/Info.plist`:

*   Add the "Required background modes" key with the "audio" item:
    ```xml
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
    ```

## Usage

### 1. Wrap your app with `AudioPlaylistProvider`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/flutter_audio_playlist.dart'; // Assuming this is your main export
import 'package:provider/provider.dart';

void main() async {
  // ... (JustAudioBackground.init() as above)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @Override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlaylistProvider(),
      child: MaterialApp(
        // ... your app setup
        home: HomeScreen(),
      ),
    );
  }
}
```

### 2. Load Tracks

Fetch your audio tracks and provide them to the `AudioPlaylistProvider`:

```dart
void _initializeTracks(BuildContext context) {
  final provider = Provider.of<AudioPlaylistProvider>(context, listen: false);
  final tracks = [
    AudioTrack(
      id: '1',
      title: 'Ambient Dreams',
      subtitle: 'Nature Sounds',
      audioUrl: 'https://your.domain.com/audio1.mp3',
      imageUrl: 'https://your.domain.com/image1.jpg',
      duration: const Duration(minutes: 2, seconds: 30), // Optional but recommended
    ),
    // ... more tracks
  ];
  provider.setTracks(tracks);
}
```

### 3. Displaying a Playlist with `AudioTile`

```dart
ListView.builder(
  itemCount: provider.tracks.length,
  itemBuilder: (context, index) {
    final track = provider.tracks[index];
    return AudioTile(
      track: track,
      // onTap: () => provider.playTrack(track), // Default behavior is to play/toggle
      titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
      playingTitleTextStyle: TextStyle(color: Theme.of(context).primaryColor),
    );
  },
)
```

### 4. Using `CurrentTrackBanner`

Display a banner for the currently playing track:

```dart
CurrentTrackBanner(
  playerScreenRoute: '/playerScreen', // Route to your AudioPlayerScreen
)
```

### 5. Opening the Default `AudioPlayerScreen`

Navigate to the pre-built player screen:

```dart
Navigator.pushNamed(context, '/playerScreen');

// In your MaterialApp routes:
routes: {
  '/playerScreen': (context) => const AudioPlayerScreen(),
}
```

### 6. Customizing with `AudioPlayerTheme`

**Global Theme:**

```dart
ChangeNotifierProvider(
  create: (_) => AudioPlaylistProvider(),
  child: AudioPlayerTheme(
    data: const AudioPlayerThemeData(
      screenBackgroundColor: Colors.black,
      primaryContentColor: Colors.white,
      titleTextStyle: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
      // ... more theme properties
    ),
    child: MaterialApp(
      // ...
    ),
  ),
)
```

**Local Theme for a specific `AudioPlayerScreen` instance:**

```dart
AudioPlayerScreen(
  theme: AudioPlayerThemeData(
    screenBackgroundColor: Colors.deepPurple,
    playPauseButtonColor: Colors.amber,
    showUpNextSection: false,
    // ...
  ),
)
```

### 7. Using Individual Components for Custom UI

You can build your own player UI by using the exported components:
`TrackDetailsSection`, `ProgressBarSection`, `ControlsSection`, `UpNextSection`, `PlayerBackButton`.

```dart
// In your custom player widget:
final audioProvider = context.watch<AudioPlaylistProvider>();
final currentTrack = audioProvider.currentTrack;

if (currentTrack == null) return SizedBox(); // Or some placeholder

Column(
  children: [
    TrackDetailsSection(track: currentTrack, ...),
    ProgressBarSection(
      position: audioProvider.position,
      totalDuration: audioProvider.totalDuration,
      onSeek: audioProvider.seek,
      ...
    ),
    ControlsSection(
      isPlaying: audioProvider.isPlaying,
      onPlayPause: audioProvider.togglePlayPause,
      ...
    ),
  ],
)
```

## API Documentation

For more details on all available classes, methods, and properties, check out the API documentation. <flutter_audio_playlist.dart>

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.

## License

This package is licensed under the MIT License - see the LICENSE file for details.