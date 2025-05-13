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
  final BehaviorSubject<LoopMode> _loopModeController = 
      BehaviorSubject.seeded(LoopMode.off);
  Timer? _sleepTimerInstance;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlaybackMode> get playbackModeStream => _playbackMode.stream;
  Stream<List<AudioTrack>> get playlistStream => _playlist.stream;
  Stream<Duration?> get sleepTimerStream => _sleepTimer.stream;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;

  bool get isPlaying => _audioPlayer.playing;
  Duration? get duration => _audioPlayer.duration;
  Duration get position => _audioPlayer.position;
  LoopMode get currentLoopMode => _audioPlayer.loopMode; // Get current loop mode directly
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

    // Listen to the player's loop mode changes
    _audioPlayer.loopModeStream.listen((loopMode) {
      _loopModeController.add(loopMode); // Update our stream
      if (loopMode == LoopMode.off && _playbackMode.value == PlaybackMode.repeat) {
        // If player turned off loop (e.g., after LoopMode.one completed) and our mode was 'repeat', revert our mode.
        _playbackMode.add(PlaybackMode.normal);
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
    final isDifferentTrack = _currentTrack?.id != track.id;

    // If playing a new track and LoopMode.one was active for the previous track, turn it off.
    if (isDifferentTrack && _audioPlayer.loopMode == LoopMode.one) {
      await _audioPlayer.setLoopMode(LoopMode.off);
      // _loopModeController will be updated by the stream listener above
      if (_playbackMode.value == PlaybackMode.repeat) {
         _playbackMode.add(PlaybackMode.normal); // Our internal mode should also reset
      }
    }
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
    if (mode == PlaybackMode.shuffle) {
      if (_playbackMode.value == PlaybackMode.shuffle) {
        // Turn off shuffle
        _playbackMode.add(PlaybackMode.normal);
        _playlist.add(_originalPlaylist);
        // Consider if _audioPlayer.setShuffleModeEnabled(false) is needed if using ConcatenatingAudioSource with shuffleOrder
      } else {
        // Turn on shuffle
        _playbackMode.add(PlaybackMode.shuffle);
        _shuffledPlaylist = List.from(_originalPlaylist)..shuffle();
        _playlist.add(_shuffledPlaylist);
        await _audioPlayer.setLoopMode(LoopMode.off); // Shuffle overrides repeat track
        // _loopModeController updated by stream listener
      }
    } else if (mode == PlaybackMode.repeat) {
      if (_audioPlayer.loopMode == LoopMode.one) {
        // Turn off repeat track
        await _audioPlayer.setLoopMode(LoopMode.off);
        _playbackMode.add(PlaybackMode.normal); // Our internal mode also reverts
      } else {
        // Turn on repeat track (once)
        await _audioPlayer.setLoopMode(LoopMode.one);
        _playbackMode.add(PlaybackMode.repeat); // Set our internal mode
        // If shuffle was on, turn it off as repeat track takes precedence
        if (_playbackMode.value == PlaybackMode.shuffle) _playlist.add(_originalPlaylist);
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

    if (_audioPlayer.loopMode != LoopMode.one) { 
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
    await _loopModeController.close();
    _sleepTimerInstance?.cancel();
  }
}
