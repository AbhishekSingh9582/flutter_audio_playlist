import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/src/enums/playback_mode.dart';
import '../services/audio_player_service.dart';
import '../models/audio_track.dart';

class AudioPlaylistProvider with ChangeNotifier {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  List<AudioTrack> _tracks = [];
  AudioTrack? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _totalDuration;
  PlaybackMode _playbackMode = PlaybackMode.normal;
  Duration? _sleepTimer;
  List<AudioTrack> _upNextTracks = [];

  AudioPlaylistProvider() {
    _audioPlayerService.init();
    _audioPlayerService.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _currentTrack = _audioPlayerService.currentTrack;
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
    _audioPlayerService.playbackModeStream.listen((mode) {
      _playbackMode = mode;
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
  PlaybackMode get playbackMode => _playbackMode;
  Duration? get sleepTimer => _sleepTimer;
  List<AudioTrack> get upNextTracks => _upNextTracks;

  Future<void> setTracks(List<AudioTrack> tracks) async {
    _tracks = tracks;
    await _audioPlayerService.setPlaylist(tracks);
    notifyListeners();
  }

  Future<void> playTrack(AudioTrack track) async {
    await _audioPlayerService.play(track);
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

  Future<void> togglePlaybackMode(PlaybackMode mode) async {
    await _audioPlayerService.togglePlaybackMode(mode);
  }

  void setSleepTimer(Duration duration) {
    _audioPlayerService.setSleepTimer(duration);
  }

  void cancelSleepTimer() {
    _audioPlayerService.cancelSleepTimer();
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    super.dispose();
  }
}
