## 0.0.1 - Initial Release

*   **Pre-built Player UI:** Introduced `AudioPlayerScreen` for a ready-to-use audio playback interface.
*   **Customization:**
    *   Added `AudioPlayerTheme` and `AudioPlayerThemeData` for extensive UI theming (colors, text styles, spacing, visibility of sections).
    *   Support for providing a completely custom player screen widget.
*   **Reusable Components:** Exposed individual UI widgets (`TrackDetailsSection`, `ControlsSection`, `ProgressBarSection`, `UpNextSection`, `AudioTile`, `CurrentTrackBanner`) for use in custom layouts.
*   **State Management:** Implemented `AudioPlaylistProvider` for managing audio state, playlist, current track, shuffle/repeat modes, and sleep timer.
*   **Core Playback Features:**
    *   Playlist loading and management.
    *   Play, pause, stop, seek.
    *   Next, previous track navigation.
    *   Shuffle and repeat modes (off, repeat once, repeat current).
    *   Sleep timer functionality.
*   **Background Audio Support:** Integrated with `just_audio` and `just_audio_background` for background playback and notification controls.
*   **Example App:** Included a comprehensive example demonstrating various features and integration methods.