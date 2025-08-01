

import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:themby/src/common/constants.dart';
import 'package:themby/src/features/player/service/controls_service.dart';
import 'package:themby/src/features/player/service/themby_controller.dart';
import 'package:themby/src/features/player/widgets/progress/draging_time.dart';
import 'package:themby/src/features/player/widgets/progress/progress_toast.dart';


class MediaProgressBar extends ConsumerStatefulWidget{

  const MediaProgressBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MediaProgressBar();

}

class _MediaProgressBar extends ConsumerState<MediaProgressBar>{
  //播放位置时间
  Duration position = const Duration(seconds: 0);

  //视频时长
  Duration duration = const Duration(seconds: 0);

  //缓冲时长
  Duration buffer = const Duration(seconds: 0);

  bool isPlaying = false;

  bool isBuffering = true;

  // bool isBuffering = false;

  List<StreamSubscription> subscriptions = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    final controller = ref.read(videoControllerProvider);
    if (controller != null) {
      subscriptions.addAll(
          [
            controller.player.stream.duration.listen((event) {
              duration = event;

              final media = ref.read(controlsServiceProvider);

              if(media.position > Duration.zero){
                position = media.position;
                // controller.player.seek(media.position);
                ref.read(controlsServiceProvider.notifier).startRecordPosition(position: position.inMicroseconds);
              }

            }),
            controller.player.stream.position.listen((event) {
              if(event - position > const Duration(seconds: 1) || event - position < const Duration(seconds: -1)){
                position = event;

                if(duration != controller.player.state.duration){
                  duration = controller.player.state.duration;
                }
                setState(() {
                });
              }
            }),
            controller.player.stream.buffer.listen((event) {
              setState(() {
                buffer = event;
              });
            }),
            controller.player.stream.playing.listen((event) {
              isPlaying = event;
            }),
            controller.player.stream.buffering.listen((event) {
              isBuffering = event;
              if(isBuffering && isPlaying) {
                SmartDialog.show(
                    tag: "loading",
                    clickMaskDismiss: false,
                    builder: (_) {
                      return Image.asset("assets/loading/loading-2.gif",height: 50);
                    }
                );
              }else{
                SmartDialog.dismiss(tag: "loading");
              }
            }),
            controller.player.stream.completed.listen((event) {
              if(event){
                ref.read(controlsServiceProvider.notifier).recordPosition(type: "stop");
                controller.player.pause();
                ref.read(controlsServiceProvider.notifier).playNext();
              }
            }),
            controller.player.stream.log.listen((event) {
              print(event.text);
            }),
          ]
      );
    }

    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if(isPlaying && !isBuffering){
        ref.read(controlsServiceProvider.notifier).recordPosition();
      }
    });
  }

  @override
  void dispose(){
    for (var element in subscriptions) {
      element.cancel();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return ProgressBar(
      progress: position,
      total: duration,
      buffered: buffer,
      bufferedBarColor: Colors.white.withOpacity(0.5),
      progressBarColor: Colors.white,
      thumbColor: Colors.white,
      baseBarColor: Colors.white.withOpacity(0.2),
      timeLabelLocation: TimeLabelLocation.sides,
      timeLabelTextStyle: StyleString.subtitleStyle.copyWith(color: Colors.white),
      barHeight: 6,
      thumbRadius: 10,
      onDragStart: (duration) {
        ///打开toast
        SmartDialog.show(
            tag: "progress_toast",
            alignment: Alignment.topCenter,
            maskColor: Colors.transparent,
            builder: (_) => const ProgressToast()
        );
      },
      onDragUpdate: (duration){
        ///更新toast 显示时间
        ref.read(dragingTimeProvider.notifier).update(duration.timeStamp);
      },
      onSeek: (duration) {
        ref.read(controlsServiceProvider.notifier).seekTo(duration);
        SmartDialog.dismiss(tag: "progress_toast");
      },
    );
  }
}