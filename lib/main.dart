// main.dart
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    androidResumeOnClick: true,
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationChannelDescription: 'Audio playback controls',
    notificationColor: const Color(0xFF2196F3),
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidShowNotificationBadge: true,
    androidNotificationClickStartsActivity: true,
    // Fix: These two parameters need to be compatible
    androidNotificationOngoing: false, // Changed to false
    androidStopForegroundOnPause: true, // Changed to true
    preloadArtwork: true,
    artDownscaleWidth: 300,
    artDownscaleHeight: 300,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Player Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});
  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _player;
  final _playlist = ConcatenatingAudioSource(children: [
    AudioSource.uri(
      Uri.parse('https://songspk.com.se/files/download/id/105432'),
      tag: MediaItem(
        id: '1',
        album: "Album 1",
        title: "Song 1",
        artist: "Artist 1",
        artUri: Uri.parse(
            'https://img-cdn.pixlr.com/image-generator/history/65bb506dcb310754719cf81f/ede935de-1138-4f66-8ed7-44bd16efc709/medium.webp'),
      ),
    ),
    AudioSource.uri(
      Uri.parse('https://songspk.com.se/files/download/id/105432'),
      tag: MediaItem(
        id: '2',
        album: "Album 2",
        title: "Song 2",
        artist: "Artist 2",
        artUri: Uri.parse(
            'https://img-cdn.pixlr.com/image-generator/history/65bb506dcb310754719cf81f/ede935de-1138-4f66-8ed7-44bd16efc709/medium.webp'),
      ),
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Listen to errors
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace st) {
      print('A stream error occurred: $e');
    });
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<SequenceState?>(
            stream: _player.sequenceStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state?.sequence.isEmpty ?? true) {
                return const SizedBox();
              }
              final metadata = state!.currentSource!.tag as MediaItem;
              return Column(
                children: [
                  Text(
                    metadata.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    metadata.artist ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              );
            },
          ),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? Duration.zero;
              return Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  _player.seek(Duration(milliseconds: value.toInt()));
                },
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _player.hasPrevious ? _player.seekToPrevious : null,
              ),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      width: 64.0,
                      height: 64.0,
                      child: const CircularProgressIndicator(),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_arrow),
                      iconSize: 64.0,
                      onPressed: _player.play,
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.pause),
                      iconSize: 64.0,
                      onPressed: _player.pause,
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _player.hasNext ? _player.seekToNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
