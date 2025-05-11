import 'package:flutter/material.dart';
import 'package:flutter_audio_playlist/flutter_video_playlist.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlaylistProvider(),
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          iconTheme: const IconThemeData(
            color: Colors.blue,
            size: 24.0,
          ),
          fontFamily: 'Roboto',
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => const PlaylistScreen(),
          '/player': (context) => const AudioPlayerScreen(),
        },
      ),
    );
  }
}

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioPlaylistProvider>(context, listen: false);

    // Simulate API call
    final tracks = [
      AudioTrack(
        id: '1',
        title: 'Sample Track 1',
        subtitle: '2:30',
        audioUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music/om+namah+shivaya+final+MASTER+2.wav',
        imageUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/om+namah+shivay.jpg',
        duration: const Duration(minutes: 2, seconds: 30),
      ),
      AudioTrack(
        id: '2',
        title: 'Sample Track 2',
        subtitle: '1:45',
        audioUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music/hare+krishna+hare+rama+FINAL+MASTER+4.wav',
        imageUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/hare+krishna+hare+rama.jpg',
        duration: const Duration(minutes: 3),
      ),
      AudioTrack(
        id: '3',
        title: 'Sample Track 3',
        subtitle: '2:57',
        audioUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music/lingashtakam+final+1.wav',
        imageUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/Lingastkam.jpg',
        duration: const Duration(minutes: 3),
      ),
         AudioTrack(
        id: '4',
        title: 'Sample Track 4',
        subtitle: '2:57',
        audioUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music/nemastasya+namoh+nmaah+final+mater+2.wav',
        imageUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/namastasya+namo+namah.jpg',
        duration: const Duration(minutes: 3),
      ),
       AudioTrack(
        id: '5',
        title: 'Sample Track 4',
        subtitle: '2:57',
        audioUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music/Daridrya+Dukh+dahana+shiva+stotram+final+master.wav',
        imageUrl:
            'https://d1ass895x5m7xs.cloudfront.net/Test/music-pic/Daridra+Dahana+Shiva+Stotram.jpg',
        duration: const Duration(minutes: 3),
      ),
    ];

    provider.setTracks(tracks);

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Playlist')),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AudioPlaylistProvider>(
              builder: (context, provider, child) {
                return ListView.builder(
                  itemCount: provider.tracks.length,
                  itemBuilder: (context, index) {
                    final track = provider.tracks[index];
                    return AudioTile(
                      track: track,
                      isPlaying: provider.currentTrack?.id == track.id &&
                          provider.isPlaying,
                      progress: provider.currentTrack?.id == track.id
                          ? provider.position.inMilliseconds /
                              (provider.totalDuration?.inMilliseconds ?? 1)
                          : 0,
                      onTap: () => provider.playTrack(track),
                    );
                  },
                );
              },
            ),
          ),
          const CurrentTrackBanner(playerScreenRoute: '/player'),
        ],
      ),
    );
  }
}
