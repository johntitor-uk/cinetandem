import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/favorites_manager.dart';
import '../screens/home_page.dart';
import '../screens/sync_chat_screen.dart';
import '../widgets/custom_button.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String movieTitle;
  final String category;

  const VideoPlayerScreen({super.key, required this.movieTitle, this.category = 'Película'});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool isWatched = false;
  bool isFlipped = false;
  bool isLiked = false;
  bool isDisliked = false;
  bool isMuted = false;
  bool isPlaying = true;
  bool showControls = false;
  bool isFullScreen = false;
  bool isInfoExpanded = false;
  double progress = 0.0;
  double bufferedProgress = 0.0; // Nuevo: Progreso del búfer
  int viewerCount = Random().nextInt(100) + 1;
  int releaseYear = 0;
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _videoLoadError = false;
  bool _isFavorite = false;
  String? _sliderTime; // Nuevo: Tiempo para la burbuja del slider
  bool _showRetryButton = false; // Nuevo: Botón de reintentos
  bool _showRewindAnimation = false; // Nuevo: Animación para retroceso
  bool _showForwardAnimation = false; // Nuevo: Animación para avance
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<String> recommendedMovies = [
    'Her',
    'Smile',
    'Soy Leyenda',
    'Joker',
    'Sueños de Libertad',
  ];
  final List<Map<String, String>> chatMessages = [
    {'user': 'User1', 'message': '¡Gran película!'},
    {'user': 'User2', 'message': '¡Me encantó la trama!'},
  ];
  int _rewindCount = 0;
  Timer? _rewindTimer;
  Timer? _controlsTimer;
  Timer? _progressTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    releaseYear = DateTime.now().year - Random().nextInt(10);
    _initializeVideoController();
    _loadFavoriteStatus();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          viewerCount = Random().nextInt(100) + 1;
        });
      }
    });
    _startProgressTimer();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    if (isPlaying && !_videoLoadError && _videoController.value.isInitialized) {
      _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted && isPlaying && !_videoLoadError && _videoController.value.isInitialized) {
          _updateProgress();
        }
      });
    }
  }

  void _initializeVideoController() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://hdfull.monster/pelicula/leolo'),
    )..initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFFFF3C38),
            handleColor: Colors.white,
            backgroundColor: Colors.grey.shade600,
            bufferedColor: Colors.grey.shade400,
          ),
          errorBuilder: (context, errorMessage) {
            setState(() {
              _videoLoadError = true;
              _showRetryButton = true;
            });
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No se pudo cargar el video: $errorMessage',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retryVideoLoad,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3C38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        _videoController.addListener(_updateProgress);
        _loadProgress();
      });
    }).catchError((error) {
      setState(() {
        _videoLoadError = true;
        _showRetryButton = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el video. Verifica la URL (MP4).')),
      );
    });
    _loadWatchedStatus();
  }

  Future<void> _retryVideoLoad() async {
    setState(() {
      _videoLoadError = false;
      _showRetryButton = false;
    });
    await _videoController.dispose();
    _initializeVideoController();
  }

  Future<void> _loadWatchedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final watched = prefs.getBool('watched_${widget.movieTitle}') ?? false;
    setState(() => isWatched = watched);
  }

  Future<void> _loadFavoriteStatus() async {
    final isFavorite = await FavoritesManager.isFavorite(widget.movieTitle);
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProgress = prefs.getDouble('progress_${widget.movieTitle}') ?? 0.0;
    if (_videoController.value.isInitialized && savedProgress > 0) {
      setState(() => progress = savedProgress);
      _videoController.seekTo(Duration(seconds: (savedProgress * _videoController.value.duration.inSeconds).toInt()));
    }
  }

  Future<void> _saveWatchedStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watched_${widget.movieTitle}', value);
    if (value) {
      await prefs.setString('completion_date_${widget.movieTitle}', DateTime.now().toIso8601String());
      await prefs.setString('category_${widget.movieTitle}', widget.category);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.movieTitle} marcada como vista')),
      );
    }
    setState(() => isWatched = value);
  }

  Future<void> _saveProgress(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('progress_${widget.movieTitle}', value);
    await prefs.setString('category_${widget.movieTitle}', widget.category);
    await prefs.setString('image_${widget.movieTitle}', 'https://image.tmdb.org/t/p/w500/8riWcADI1ekEiBguVB9vkilhiQm.jpg');
    await prefs.setString('last_played_${widget.movieTitle}', DateTime.now().toIso8601String());
    if (value >= 0.99 && !isWatched) {
      await _saveWatchedStatus(true);
    }
  }

  void _updateProgress() {
    if (_videoController.value.isInitialized) {
      final position = _videoController.value.position.inSeconds;
      final duration = _videoController.value.duration.inSeconds;
      if (duration > 0) {
        final newProgress = position / duration;
        final buffered = _videoController.value.buffered;
        double newBufferedProgress = 0.0;
        if (buffered.isNotEmpty) {
          newBufferedProgress = buffered.last.end.inSeconds / duration;
        }
        setState(() {
          progress = newProgress.clamp(0.0, 1.0);
          bufferedProgress = newBufferedProgress.clamp(0.0, 1.0);
        });
        _saveProgress(progress);
        if (kDebugMode) {
          print('Progress updated: $newProgress (position: $position, duration: $duration, buffered: $newBufferedProgress)');
        }
      } else {
        if (kDebugMode) {
          print('Duration is 0, cannot update progress');
        }
      }
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final orientation = MediaQuery.of(context).orientation;
    if (isPlaying && _videoController.value.isInitialized && !isFullScreen) {
      setState(() {
        if (orientation == Orientation.landscape) {
          isFullScreen = true;
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        }
      });
    } else if (orientation == Orientation.portrait && isFullScreen) {
      setState(() {
        isFullScreen = false;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController.removeListener(_updateProgress);
    _videoController.dispose();
    _chewieController?.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _rewindTimer?.cancel();
    _controlsTimer?.cancel();
    _progressTimer?.cancel();
    if (isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    super.dispose();
  }

  void toggleFlip() {
    setState(() {
      isFlipped = !isFlipped;
      if (isFlipped) {
        isLiked = false;
        isDisliked = false;
      }
    });
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) isDisliked = false;
    });
  }

  void toggleDislike() {
    setState(() {
      isDisliked = !isDisliked;
      if (isDisliked) isLiked = false;
    });
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying && !_videoLoadError) {
        _videoController.play();
        _startProgressTimer();
      } else {
        _videoController.pause();
        _progressTimer?.cancel();
      }
    });
    _showControlsTemporarily();
  }

  void toggleMute() async {
    if (!_videoLoadError) {
      setState(() {
        isMuted = !isMuted;
        _chewieController?.setVolume(isMuted ? 0.0 : 1.0);
      });
      await FlutterVolumeController.setMute(isMuted);
    }
    _showControlsTemporarily();
  }

  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
      if (isFullScreen) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      }
    });
    _showControlsTemporarily();
  }

  void rewindVideo() {
    if (!_videoLoadError && _videoController.value.isInitialized) {
      _rewindCount++;
      final rewindSeconds = 10 * pow(2, _rewindCount - 1).toInt();
      final currentPosition = _videoController.value.position.inSeconds;
      final newPosition = (currentPosition - rewindSeconds).clamp(0, _videoController.value.duration.inSeconds);

      _videoController.seekTo(Duration(seconds: newPosition));
      setState(() {
        progress = newPosition / _videoController.value.duration.inSeconds;
        _showRewindAnimation = true;
      });
      _saveProgress(progress);

      _rewindTimer?.cancel();
      _rewindTimer = Timer(const Duration(seconds: 2), () {
        _rewindCount = 0;
      });
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showRewindAnimation = false);
        }
      });
    }
    _showControlsTemporarily();
  }

  void forwardVideo() {
    if (!_videoLoadError && _videoController.value.isInitialized) {
      _rewindCount++;
      final forwardSeconds = 10 * pow(2, _rewindCount - 1).toInt();
      final currentPosition = _videoController.value.position.inSeconds;
      final newPosition = (currentPosition + forwardSeconds).clamp(0, _videoController.value.duration.inSeconds);

      _videoController.seekTo(Duration(seconds: newPosition));
      setState(() {
        progress = newPosition / _videoController.value.duration.inSeconds;
        _showForwardAnimation = true;
      });
      _saveProgress(progress);

      _rewindTimer?.cancel();
      _rewindTimer = Timer(const Duration(seconds: 2), () {
        _rewindCount = 0;
      });
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showForwardAnimation = false);
        }
      });
    }
    _showControlsTemporarily();
  }

  void toggleControls() {
    setState(() {
      showControls = !showControls;
    });
    if (showControls) {
      _showControlsTemporarily();
    }
  }

  void _showControlsTemporarily() {
    setState(() {
      showControls = true;
    });
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && isPlaying) {
        setState(() {
          showControls = false;
        });
      }
    });
  }

  void updateProgress(double value) {
    if (!_videoLoadError) {
      setState(() {
        progress = value.clamp(0.0, 1.0);
        _sliderTime = _formatDuration(value * (_videoController.value.isInitialized ? _videoController.value.duration.inSeconds : 7200));
      });
      if (_videoController.value.isInitialized) {
        _videoController.seekTo(Duration(seconds: (progress * _videoController.value.duration.inSeconds).toInt()));
      }
      _saveProgress(progress);
    }
    _showControlsTemporarily();
  }

  void _sendMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      setState(() {
        chatMessages.add({
          'user': 'Tú',
          'message': _chatController.text.trim(),
        });
        _chatController.clear();
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isTabletOrTV = MediaQuery.of(context).size.width > 600;

    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A1F),
          appBar: isFullScreen
              ? null
              : AppBar(
            backgroundColor: const Color(0xFF0A0A1F),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Volver',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false,
                  );
                },
                tooltip: 'Inicio',
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SyncChatScreen()),
                  );
                },
                tooltip: 'Chat global',
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 28),
                onPressed: () {
                  final currentTime = _formatDuration(progress * (_videoController.value.isInitialized ? _videoController.value.duration.inSeconds : 7200));
                  Share.share('Mira ${widget.movieTitle} en Cinetandem desde $currentTime: https://cinetandem.app/${widget.movieTitle}?t=${(progress * _videoController.value.duration.inSeconds).toInt()}');
                },
                tooltip: 'Compartir',
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reproductor de video estilo YouTube
                    GestureDetector(
                      onTap: toggleControls,
                      onDoubleTapDown: (details) {
                        final tapPosition = details.localPosition.dx / constraints.maxWidth;
                        if (tapPosition < 0.4) {
                          rewindVideo();
                        } else if (tapPosition > 0.6) {
                          forwardVideo();
                        }
                      },
                      child: Container(
                        color: Colors.black,
                        child: AspectRatio(
                          aspectRatio: isFullScreen ? constraints.maxWidth / constraints.maxHeight : 16 / 9,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _videoLoadError
                                  ? Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'No se pudo cargar el video.',
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_showRetryButton)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 16),
                                          child: ElevatedButton(
                                            onPressed: _retryVideoLoad,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF3C38),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                                  : _chewieController != null && _videoController.value.isInitialized
                                  ? Chewie(controller: _chewieController!)
                                  : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                              ),
                              if (_showRewindAnimation)
                                AnimatedOpacity(
                                  opacity: _showRewindAnimation ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: const Icon(Icons.replay_10, color: Colors.white, size: 40),
                                  ),
                                ),
                              if (_showForwardAnimation)
                                AnimatedOpacity(
                                  opacity: _showForwardAnimation ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: const Icon(Icons.forward_10, color: Colors.white, size: 40),
                                  ),
                                ),
                              AnimatedOpacity(
                                opacity: showControls ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.4)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              widget.movieTitle,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                                color: Colors.white,
                                                size: isTabletOrTV ? 32 : 28,
                                              ),
                                              onPressed: toggleFullScreen,
                                              tooltip: isFullScreen ? 'Salir de pantalla completa' : 'Pantalla completa',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Stack(
                                              alignment: Alignment.centerLeft,
                                              children: [
                                                SliderTheme(
                                                  data: SliderTheme.of(context).copyWith(
                                                    trackHeight: 4,
                                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                                    activeTrackColor: const Color(0xFFFF3C38),
                                                    inactiveTrackColor: Colors.grey.shade600,
                                                    thumbColor: Colors.white,
                                                    overlayColor: Colors.white.withOpacity(0.3),
                                                  ),
                                                  child: Slider(
                                                    value: bufferedProgress,
                                                    min: 0.0,
                                                    max: 1.0,
                                                    onChanged: null,
                                                    activeColor: Colors.grey.shade400,
                                                  ),
                                                ),
                                                SliderTheme(
                                                  data: SliderTheme.of(context).copyWith(
                                                    trackHeight: 4,
                                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                                    activeTrackColor: const Color(0xFFFF3C38),
                                                    inactiveTrackColor: Colors.transparent,
                                                    thumbColor: Colors.white,
                                                    overlayColor: Colors.white.withOpacity(0.3),
                                                  ),
                                                  child: Slider(
                                                    value: progress,
                                                    min: 0.0,
                                                    max: 1.0,
                                                    onChanged: _videoLoadError ? null : updateProgress,
                                                    onChangeStart: (value) {
                                                      setState(() {
                                                        _sliderTime = _formatDuration(value * (_videoController.value.isInitialized ? _videoController.value.duration.inSeconds : 7200));
                                                      });
                                                    },
                                                    onChangeEnd: (value) {
                                                      setState(() {
                                                        _sliderTime = null;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_sliderTime != null)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.8),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _sliderTime!,
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDuration(progress * (_videoController.value.isInitialized ? _videoController.value.duration.inSeconds : 7200)),
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                                Text(
                                                  _formatDuration(_videoController.value.isInitialized ? _videoController.value.duration.inSeconds.toDouble() : 7200),
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.replay_10,
                                                  color: Colors.white,
                                                  size: isTabletOrTV ? 32 : 28,
                                                ),
                                                onPressed: _videoLoadError ? null : rewindVideo,
                                                tooltip: 'Retroceder 10s',
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: isTabletOrTV ? 40 : 36,
                                                ),
                                                onPressed: _videoLoadError ? null : togglePlayPause,
                                                tooltip: isPlaying ? 'Pausa' : 'Reproducir',
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.forward_10,
                                                  color: Colors.white,
                                                  size: isTabletOrTV ? 32 : 28,
                                                ),
                                                onPressed: _videoLoadError ? null : forwardVideo,
                                                tooltip: 'Avanzar 10s',
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isMuted ? Icons.volume_off : Icons.volume_up,
                                                  color: Colors.white,
                                                  size: isTabletOrTV ? 32 : 28,
                                                ),
                                                onPressed: _videoLoadError ? null : toggleMute,
                                                tooltip: isMuted ? 'Activar sonido' : 'Silenciar',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isFullScreen) ...[
                      Padding(
                        padding: EdgeInsets.all(isTabletOrTV ? 24 : 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: toggleFlip,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: isTabletOrTV ? 100 : 70,
                                height: isTabletOrTV ? 140 : 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFF3C38), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: isFlipped
                                    ? Container(
                                  color: const Color(0xFF0A0A1F),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.thumb_up,
                                          color: isLiked ? Colors.blue : Colors.grey[400],
                                          size: isTabletOrTV ? 28 : 24,
                                        ),
                                        onPressed: toggleLike,
                                        tooltip: 'Me gusta',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.thumb_down,
                                          color: isDisliked ? Colors.red : Colors.grey[400],
                                          size: isTabletOrTV ? 28 : 24,
                                        ),
                                        onPressed: toggleDislike,
                                        tooltip: 'No me gusta',
                                      ),
                                    ],
                                  ),
                                )
                                    : CachedNetworkImage(
                                  imageUrl: 'https://image.tmdb.org/t/p/w500/8riWcADI1ekEiBguVB9vkilhiQm.jpg',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.movieTitle,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTabletOrTV ? 24 : 20,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Estreno: $releaseYear',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.white70,
                                      fontSize: isTabletOrTV ? 14 : 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Una trama intrigante que captura al espectador.',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white70,
                                      fontSize: isTabletOrTV ? 16 : 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  ExpansionTile(
                                    title: Text(
                                      isInfoExpanded ? 'Ver menos' : 'Ver más',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFFFF3C38),
                                        fontSize: isTabletOrTV ? 14 : 12,
                                      ),
                                    ),
                                    tilePadding: EdgeInsets.zero,
                                    childrenPadding: const EdgeInsets.only(top: 4),
                                    iconColor: const Color(0xFFFF3C38),
                                    collapsedIconColor: Colors.white70,
                                    onExpansionChanged: (expanded) {
                                      setState(() => isInfoExpanded = expanded);
                                    },
                                    children: [
                                      Text(
                                        'Descripción completa: Esta película presenta una trama intrigante que captura al espectador desde el primer momento, con giros inesperados y un final emocionante.',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white70,
                                          fontSize: isTabletOrTV ? 16 : 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Actores: Actor Principal, Actriz Secundaria | Director: Nombre Director',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white54,
                                          fontSize: isTabletOrTV ? 14 : 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Switch(
                                  value: isWatched,
                                  onChanged: _saveWatchedStatus,
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.grey,
                                  activeTrackColor: Colors.green[200],
                                  inactiveTrackColor: Colors.grey[400],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.favorite,
                                    color: _isFavorite ? const Color(0xFFFF3C38) : Colors.grey[400],
                                    size: isTabletOrTV ? 28 : 24,
                                  ),
                                  onPressed: () async {
                                    if (_isFavorite) {
                                      await FavoritesManager.removeFavorite(widget.movieTitle);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Eliminado de favoritos: ${widget.movieTitle}')),
                                      );
                                    } else {
                                      await FavoritesManager.addFavorite(widget.movieTitle);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Agregado a favoritos: ${widget.movieTitle}')),
                                      );
                                    }
                                    setState(() {
                                      _isFavorite = !_isFavorite;
                                    });
                                  },
                                  tooltip: _isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '$viewerCount personas viendo ahora',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isTabletOrTV ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: isTabletOrTV ? MediaQuery.of(context).size.height * 0.6 : MediaQuery.of(context).size.height * 0.5,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A1F),
                                  border: Border.all(color: const Color(0xFFFF3C38), width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recomendadas',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTabletOrTV ? 16 : 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: recommendedMovies.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => VideoPlayerScreen(
                                                      movieTitle: recommendedMovies[index],
                                                      category: 'Película',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Column(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: CachedNetworkImage(
                                                      imageUrl: 'https://image.tmdb.org/t/p/w500/8riWcADI1ekEiBguVB9vkilhiQm.jpg',
                                                      height: isTabletOrTV ? 120 : 80,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                                                      errorWidget: (context, url, error) => Container(
                                                        height: isTabletOrTV ? 120 : 80,
                                                        color: Colors.grey[900],
                                                        child: const Center(
                                                          child: Icon(Icons.broken_image, color: Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    recommendedMovies[index],
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      color: Colors.white,
                                                      fontSize: isTabletOrTV ? 14 : 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A1F),
                                  border: Border.all(color: const Color(0xFFFF3C38), width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chat en tiempo real',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTabletOrTV ? 16 : 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: _chatScrollController,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: chatMessages.length,
                                        itemBuilder: (context, index) {
                                          final message = chatMessages[index];
                                          final isMe = message['user'] == 'Tú';
                                          return Align(
                                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isMe ? Colors.deepOrangeAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    message['user']!,
                                                    style: TextStyle(
                                                      color: isMe ? Colors.deepOrangeAccent : Colors.white70,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: isTabletOrTV ? 14 : 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    message['message']!,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: isTabletOrTV ? 16 : 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _chatController,
                                            decoration: InputDecoration(
                                              hintText: 'Escribe tu mensaje...',
                                              filled: true,
                                              fillColor: Colors.white.withOpacity(0.1),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(30),
                                                borderSide: BorderSide.none,
                                              ),
                                              hintStyle: const TextStyle(color: Colors.white54),
                                            ),
                                            style: TextStyle(color: Colors.white, fontSize: isTabletOrTV ? 16 : 14),
                                            onSubmitted: (_) => _sendMessage(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.send, color: Colors.deepOrangeAccent, size: 28),
                                          onPressed: _sendMessage,
                                          tooltip: 'Enviar mensaje',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}