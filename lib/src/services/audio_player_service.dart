import 'dart:async';
import 'package:flutter_audio_playlist/src/enums/repeat_mode.dart'; // Updated import
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../models/audio_track.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BehaviorSubject<List<AudioTrack>> _playlist =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<RepeatMode> _repeatModeController =
      BehaviorSubject.seeded(RepeatMode.off);
  final BehaviorSubject<bool> _shuffleModeController =
      BehaviorSubject.seeded(false);
  final BehaviorSubject<Duration?> _sleepTimer = BehaviorSubject.seeded(null);
  Timer? _sleepTimerInstance;
  bool _hasCompletedOneRepeatForRepeatOnce = false; // Flag for RepeatMode.repeatOnce logic

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<RepeatMode> get repeatModeStream => _repeatModeController.stream;
  Stream<bool> get shuffleModeStream => _shuffleModeController.stream;
  Stream<List<AudioTrack>> get playlistStream => _playlist.stream;
  Stream<Duration?> get sleepTimerStream => _sleepTimer.stream;

  bool get isPlaying => _audioPlayer.playing;
  Duration? get duration => _audioPlayer.duration;
  Duration get position => _audioPlayer.position;
  AudioTrack? get currentTrack => _currentTrack;
  RepeatMode get currentRepeatMode => _repeatModeController.value;
  bool get isShuffling => _shuffleModeController.value;

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
    _playlist.add(_shuffleModeController.value
        ? _shuffledPlaylist
        : _originalPlaylist);
  }

  Future<void> play(AudioTrack track, {bool isInternalRepeatOnceContinuation = false}) async {
    final bool isDifferentTrack = _currentTrack?.id != track.id;
    _currentTrack = track;

    if (isDifferentTrack) {
      _hasCompletedOneRepeatForRepeatOnce = false; // Reset for new track
      // If user manually changed track (not an internal repeatOnce call)
      // and mode was repeatOnce, revert repeat to off.
      if (!isInternalRepeatOnceContinuation && _repeatModeController.value == RepeatMode.repeatOnce) {
        _repeatModeController.add(RepeatMode.off);
      }
      // Note: RepeatMode.repeatCurrent persists for the new track if it was active.
    }

    // Set just_audio's loopMode based on our RepeatMode
    if (_repeatModeController.value == RepeatMode.repeatCurrent) {
      await _audioPlayer.setLoopMode(LoopMode.one);
    } else { 
      // For RepeatMode.off or the initial play of RepeatMode.repeatOnce,
      // or the second play of RepeatMode.repeatOnce (where it then transitions to off).
      // The _onTrackComplete logic handles the transition for repeatOnce.
      await _audioPlayer.setLoopMode(LoopMode.off);
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
    _repeatModeController.add(RepeatMode.off);
    _hasCompletedOneRepeatForRepeatOnce = false;
    await _audioPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> cycleRepeatMode() async {
    RepeatMode currentMode = _repeatModeController.value;
    RepeatMode nextMode;

    _hasCompletedOneRepeatForRepeatOnce = false; // Reset this flag on any manual mode change

    if (currentMode == RepeatMode.off) {
      nextMode = RepeatMode.repeatOnce;
      // LoopMode.off is appropriate for the first play of repeatOnce.
      // _onTrackComplete will handle the repeat.
      if (_currentTrack != null) await _audioPlayer.setLoopMode(LoopMode.off);
    } else if (currentMode == RepeatMode.repeatOnce) {
      nextMode = RepeatMode.repeatCurrent;
      if (_currentTrack != null) await _audioPlayer.setLoopMode(LoopMode.one);
    } else { // RepeatMode.repeatCurrent
      nextMode = RepeatMode.off;
      if (_currentTrack != null) await _audioPlayer.setLoopMode(LoopMode.off);
    }
    _repeatModeController.add(nextMode);
  }

  Future<void> toggleShuffleMode() async {
    final newShuffleState = !_shuffleModeController.value;
    _shuffleModeController.add(newShuffleState);
    _playlist.add(newShuffleState ? _shuffledPlaylist : _originalPlaylist);
    // If a track is currently playing, its playback continues.
    // The change affects the "next" track selection.
  }

  Future<void> playNext() async {
    if (_currentTrack == null) return;

    // If user manually skips next while in repeatOnce, cancel the repeatOnce behavior
    if (_repeatModeController.value == RepeatMode.repeatOnce) {
      _repeatModeController.add(RepeatMode.off);
    }
    _hasCompletedOneRepeatForRepeatOnce = false; // Reset flag for any new track

    final currentList = _shuffleModeController.value
        ? _shuffledPlaylist
        : _originalPlaylist;
    final currentIndex =
        currentList.indexWhere((track) => track.id == _currentTrack!.id);
    
    if (currentList.isEmpty) return;

    if (currentIndex < currentList.length - 1) {
      await play(currentList[currentIndex + 1]);
    } else {
      await play(currentList[0]); // Loop to start of playlist
    }
  }

  Future<void> playPrevious() async {
    if (_currentTrack == null) return;

    // If user manually skips previous while in repeatOnce, cancel the repeatOnce behavior
    if (_repeatModeController.value == RepeatMode.repeatOnce) {
      _repeatModeController.add(RepeatMode.off);
    }
    _hasCompletedOneRepeatForRepeatOnce = false; // Reset flag for any new track

    final currentList = _shuffleModeController.value
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

    if (_repeatModeController.value == RepeatMode.repeatOnce) {
      if (!_hasCompletedOneRepeatForRepeatOnce) {
        _hasCompletedOneRepeatForRepeatOnce = true;
        // Replay current track. LoopMode should be off for this play.
        await play(_currentTrack!, isInternalRepeatOnceContinuation: true);
      } else {
        // Finished the single repeat
        _hasCompletedOneRepeatForRepeatOnce = false;
        _repeatModeController.add(RepeatMode.off); // Revert to normal mode
        await playNext(); // Proceed to next track
      }
    } else if (_repeatModeController.value == RepeatMode.repeatCurrent) {
      // just_audio with LoopMode.one handles this. Player loops automatically.
      // No explicit action needed here.
    } else { // RepeatMode.off
      await playNext();
    }
  }

  List<AudioTrack> getUpNextTracks() {
    if (_currentTrack == null) return [];
   final currentList =
        _shuffleModeController.value // Use the new shuffle controller
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
    await _repeatModeController.close();
    await _shuffleModeController.close();
    await _sleepTimer.close();
    _sleepTimerInstance?.cancel();
  }
}
