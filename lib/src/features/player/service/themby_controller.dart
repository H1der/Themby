
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:themby/src/common/data/player_setting.dart';

part 'themby_controller.g.dart';

class ThembyController{

  ThembyController({required this.mpvBufferSize, required this.mpvHardDecoding});

  int mpvBufferSize;

  bool mpvHardDecoding;

  VideoController? _videoController;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initError;

  VideoController? get controller => _videoController;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get initError => _initError;


  Future<VideoController?> init() async {
    if (_isInitialized && _videoController != null) {
      return _videoController;
    }
    
    if (_isInitializing) {
      // 等待当前初始化完成
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _videoController;
    }

    _isInitializing = true;
    _initError = null;

    try {
      Player player = Player(
          configuration: PlayerConfiguration(
              bufferSize: 1024 * 1024 * mpvBufferSize,
              libass: true,
              logLevel: MPVLogLevel.debug
          )
      );
      
      if (Platform.isAndroid) {
        NativePlayer nativePlayer = player.platform as NativePlayer;
        final ByteData data = await rootBundle.load("assets/fonts/subfont.ttf");
        final Uint8List buffer = data.buffer.asUint8List();
        final Directory directory = await getApplicationSupportDirectory();
        final String fontsDir = "${directory.path}/fonts";
        final File file = File("$fontsDir/subfont.ttf");
        await file.create(recursive: true);
        await file.writeAsBytes(buffer);
        nativePlayer.setProperty("sub-fonts-dir", fontsDir);
        nativePlayer.setProperty("sub-font", "Droid Sans Fallback");
      }

      _videoController = VideoController(
        player,
        configuration: VideoControllerConfiguration(
          enableHardwareAcceleration: mpvHardDecoding,
          androidAttachSurfaceAfterVideoParameters: false,
        ),
      );

      _isInitialized = true;
      return _videoController;
    } catch (e) {
      _initError = e.toString();
      return null;
    } finally {
      _isInitializing = false;
    }
  }

  void dispose() {
    _videoController?.player.dispose();
    _videoController = null;
    _isInitialized = false;
    _isInitializing = false;
    _initError = null;
  }
}

@riverpod
ThembyController thembyController(ThembyControllerRef ref){
  return ThembyController(
    mpvBufferSize: ref.watch(playerSettingProvider).mpvBufferSize,
    mpvHardDecoding: ref.watch(playerSettingProvider).mpvHardDecoding
  );
}

@riverpod
class VideoControllerNotifier extends _$VideoControllerNotifier {
  @override
  Future<VideoController> build() async {
    final thembyController = ref.watch(thembyControllerProvider);
    final controller = await thembyController.init();
    
    if (controller == null) {
      throw Exception(thembyController.initError ?? '视频控制器初始化失败');
    }
    
    return controller;
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final thembyController = ref.read(thembyControllerProvider);
      final controller = await thembyController.init();
      
      if (controller == null) {
        throw Exception(thembyController.initError ?? '视频控制器初始化失败');
      }
      
      return controller;
    });
  }
}

// 为了向后兼容，提供一个同步访问的 Provider
// 注意：这个 Provider 只应该在确保初始化完成后使用
@riverpod
VideoController? videoController(VideoControllerRef ref) {
  final asyncController = ref.watch(videoControllerNotifierProvider);
  return asyncController.when(
    data: (controller) => controller,
    loading: () => null,
    error: (_, __) => null,
  );
}

