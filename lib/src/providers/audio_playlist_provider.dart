import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/enums/repeat_mode.dart'; // Updated import
import 'package:palette_generator/palette_generator.dart';
// import 'package:palette_generator/palette_generator.dart';
// import 'package:just_audio/just_audio.dart'; // No longer needed here
import '../services/audio_player_service.dart';
import '../models/audio_track.dart';

class AudioPlaylistProvider with ChangeNotifier {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  List<AudioTrack> _tracks = [];
  AudioTrack? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _totalDuration;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffling = false;
  Duration? _sleepTimer;
  List<AudioTrack> _upNextTracks = [];
  Color? _currentTrackDominantColor;

  AudioPlaylistProvider() {
    _audioPlayerService.init();
    _audioPlayerService.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      final newTrack = _audioPlayerService.currentTrack;
      if (_currentTrack?.id != newTrack?.id) {
        _currentTrack = newTrack;
        _updateDominantColor(_currentTrack);
      }
      _upNextTracks = _audioPlayerService.getUpNextTracks();
      notifyListeners();
    });
    _audioPlayerService.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });
    _audioPlayerService.durationStream.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });
    _audioPlayerService.repeatModeStream.listen((mode) {
      _repeatMode = mode;
      _upNextTracks = _audioPlayerService.getUpNextTracks();
      notifyListeners();
    });
    _audioPlayerService.shuffleModeStream.listen((isShuffling) {
      _isShuffling = isShuffling;
      _upNextTracks = _audioPlayerService.getUpNextTracks(); // Up next depends on shuffle
      notifyListeners();
    });
    _audioPlayerService.sleepTimerStream.listen((timer) {
      _sleepTimer = timer;
      notifyListeners();
    });
  }

  List<AudioTrack> get tracks => _tracks;
  AudioTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get totalDuration => _totalDuration;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffling => _isShuffling;
  Duration? get sleepTimer => _sleepTimer;
  List<AudioTrack> get upNextTracks => _upNextTracks;
  Color? get currentTrackDominantColor => _currentTrackDominantColor;

  Future<void> setTracks(List<AudioTrack> tracks) async {
    _tracks = tracks;
    await _audioPlayerService.setPlaylist(tracks);
    notifyListeners();
  }

  Future<void> playTrack(AudioTrack track) async {
    await _audioPlayerService.play(track);
    // The playerStateStream listener will handle _currentTrack update
    // and trigger _updateDominantColor.
    // If immediate color update is desired here, can call _updateDominantColor(track)
  }

  Future<void> togglePlayPause() async {
    await _audioPlayerService.togglePlayPause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayerService.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayerService.stop();
  }

  Future<void> playNext() async {
    await _audioPlayerService.playNext();
  }

  Future<void> playPrevious() async {
    await _audioPlayerService.playPrevious();
  }

  Future<void> cycleRepeatMode() async {
    await _audioPlayerService.cycleRepeatMode();
  }

  Future<void> toggleShuffleMode() async {
    await _audioPlayerService.toggleShuffleMode();
  }

  void setSleepTimer(Duration duration) {
    _audioPlayerService.setSleepTimer(duration);
  }

  void cancelSleepTimer() {
    _audioPlayerService.cancelSleepTimer();
  }

  Future<void> _updateDominantColor(AudioTrack? track) async {
    if (track == null || track.imageUrl.isEmpty) {
      _currentTrackDominantColor = null;
      notifyListeners();
      return;
    }
    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(track.imageUrl),
      );
      _currentTrackDominantColor = paletteGenerator.dominantColor?.color;
    } catch (e) {
      _currentTrackDominantColor = null; // Reset on error
    }
    notifyListeners();
  }
  @override
  void dispose() {
    _audioPlayerService.dispose();
    super.dispose();
  }
}
