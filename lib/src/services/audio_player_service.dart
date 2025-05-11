import 'dart:async';
import 'package:flutter_audio_playlist/src/enums/playback_mode.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../models/audio_track.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BehaviorSubject<List<AudioTrack>> _playlist =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<PlaybackMode> _playbackMode =
      BehaviorSubject.seeded(PlaybackMode.normal);
  final BehaviorSubject<Duration?> _sleepTimer = BehaviorSubject.seeded(null);
  Timer? _sleepTimerInstance;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlaybackMode> get playbackModeStream => _playbackMode.stream;
  Stream<List<AudioTrack>> get playlistStream => _playlist.stream;
  Stream<Duration?> get sleepTimerStream => _sleepTimer.stream;

  bool get isPlaying => _audioPlayer.playing;
  Duration? get duration => _audioPlayer.duration;
  Duration get position => _audioPlayer.position;
  AudioTrack? get currentTrack => _currentTrack;

  AudioTrack? _currentTrack;
  List<AudioTrack> _originalPlaylist = [];
  List<AudioTrack> _shuffledPlaylist = [];

  Future<void> init() async {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onTrackComplete();
      }
    });
  }

  Future<void> setPlaylist(List<AudioTrack> tracks) async {
    _originalPlaylist = List.from(tracks);
    _shuffledPlaylist = List.from(tracks)..shuffle();
    _playlist.add(_playbackMode.value == PlaybackMode.shuffle
        ? _shuffledPlaylist
        : _originalPlaylist);
  }

  Future<void> play(AudioTrack track) async {
    _currentTrack = track;
    await _audioPlayer.setAudioSource(
      AudioSource.uri(
        Uri.parse(track.audioUrl),
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artUri: Uri.parse(track.imageUrl),
        ),
      ),
    );
    await _audioPlayer.play();
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    _currentTrack = null;
    await _audioPlayer.stop();
    _playbackMode.add(PlaybackMode.normal);
  }

  Future<void> togglePlaybackMode(PlaybackMode mode) async {
    if (_playbackMode.value == mode) {
      _playbackMode.add(PlaybackMode.normal);
      _playlist.add(_originalPlaylist);
    } else {
      _playbackMode.add(mode);
      if (mode == PlaybackMode.shuffle) {
        _shuffledPlaylist = List.from(_originalPlaylist)..shuffle();
        _playlist.add(_shuffledPlaylist);
      } else if (mode == PlaybackMode.repeat && _currentTrack != null) {
        await play(_currentTrack!);
      }
    }
  }

  Future<void> playNext() async {
    if (_currentTrack == null) return;
    final currentList = _playbackMode.value == PlaybackMode.shuffle
        ? _shuffledPlaylist
        : _originalPlaylist;
    final currentIndex =
        currentList.indexWhere((track) => track.id == _currentTrack!.id);
    if (currentIndex < currentList.length - 1) {
      await play(currentList[currentIndex + 1]);
    } else {
      await play(currentList[0]);
    }
  }

  Future<void> playPrevious() async {
    if (_currentTrack == null) return;
    final currentList = _playbackMode.value == PlaybackMode.shuffle
        ? _shuffledPlaylist
        : _originalPlaylist;
    final currentIndex =
        currentList.indexWhere((track) => track.id == _currentTrack!.id);
    if (currentIndex > 0) {
      await play(currentList[currentIndex - 1]);
    } else {
      await play(currentList.last);
    }
  }

  void setSleepTimer(Duration duration) {
    _sleepTimerInstance?.cancel();
    _sleepTimer.add(duration);
    _sleepTimerInstance = Timer(duration, () async {
      await stop();
      _sleepTimer.add(null);
    });
  }

  void cancelSleepTimer() {
    _sleepTimerInstance?.cancel();
    _sleepTimer.add(null);
  }

  Future<void> _onTrackComplete() async {
    if (_currentTrack == null) return;
    if (_playbackMode.value == PlaybackMode.repeat) {
      await play(_currentTrack!);
    } else {
      await playNext();
    }
  }

  List<AudioTrack> getUpNextTracks() {
    if (_currentTrack == null) return [];
    final currentList = _playbackMode.value == PlaybackMode.shuffle
        ? _shuffledPlaylist
        : _originalPlaylist;
    final currentIndex =
        currentList.indexWhere((track) => track.id == _currentTrack!.id);
    if (currentIndex == -1 || currentIndex == currentList.length - 1) {
      return [];
    }
    return currentList.sublist(currentIndex + 1);
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _playlist.close();
    await _playbackMode.close();
    await _sleepTimer.close();
    _sleepTimerInstance?.cancel();
  }
}
