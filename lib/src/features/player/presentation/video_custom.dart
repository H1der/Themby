

import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:themby/src/common/constants.dart';
import 'package:themby/src/common/data/subtitle_setting.dart';
import 'package:themby/src/features/emby/data/view_repository.dart';
import 'package:themby/src/features/emby/domain/selected_media.dart';
import 'package:themby/src/features/player/presentation/play_control.dart';
import 'package:themby/src/features/player/service/controls_service.dart';
import 'package:themby/src/features/player/service/fit_type_service.dart';
import 'package:themby/src/features/player/service/themby_controller.dart';
import 'package:themby/src/features/player/service/volume_brightness_service.dart';
import 'package:themby/src/features/player/utils/fullscreen.dart';


class VideoCustom extends ConsumerStatefulWidget{
  const VideoCustom({super.key, required this.media});

  final SelectedMedia media;

  @override
  ConsumerState<VideoCustom> createState() => _VideoCustom();
}

class _VideoCustom extends ConsumerState<VideoCustom>{
  bool _hasStartedPlay = false;

  @override
  void initState(){
    super.initState();
    enterFullScreen();
    ref.read(volumeBrightnessServiceProvider.notifier).update();
  }


  @override
  void deactivate(){
    /// 记录播放结束
    ref.read(controlsServiceProvider.notifier).recordPosition(type: "stop");
    final controller = ref.read(videoControllerProvider);
    if (controller != null) {
      controller.player.stop();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    exitFull();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fitType = ref.watch(fitTypeServiceProvider);
    final asyncController = ref.watch(videoControllerNotifierProvider);

    return Container(
        padding: const EdgeInsets.all(0),
        margin: const EdgeInsets.all(0),
        child: asyncController.when(
          data: (controller) {
            // 当控制器准备好后，开始播放（只执行一次）
            if (!_hasStartedPlay) {
              _hasStartedPlay = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(controlsServiceProvider.notifier).startPlay(widget.media);
              });
            }
            
            return Stack(
              fit: StackFit.passthrough,
              children: [
                Video(
                  key: ValueKey(fitType),
                  controller: controller,
                  pauseUponEnteringBackgroundMode: true,
                  resumeUponEnteringForegroundMode: false,
                  alignment: Alignment.center,
                  fit: videoFitType[fitType]['attr'],
                  subtitleViewConfiguration: SubtitleViewConfiguration(
                    style: ref.watch(subtitleSettingProvider).subtitleStyle,
                    padding: const EdgeInsets.all(24.0),
                  ),
                  controls: NoVideoControls,
                ),
                PlayControl(media: widget.media)
              ],
            );
          },
          loading: () => Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '正在初始化视频播放器...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          error: (error, stackTrace) => Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '视频播放器初始化失败',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(videoControllerNotifierProvider.notifier).retry();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}