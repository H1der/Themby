

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:themby/src/features/player/service/themby_controller.dart';

class PlayOrPauseButton extends ConsumerStatefulWidget{
  const PlayOrPauseButton({super.key});


  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PlayOrPauseButtonState();
}

class _PlayOrPauseButtonState extends ConsumerState<PlayOrPauseButton>{
  bool isPlaying = false;

  late StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(thembyControllerProvider).controller;
    if (controller != null) {
      subscription = controller.player.stream.playing.listen((event) {
        setState(() {
          isPlaying = event;
        });
      });
    }
  }


  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: Colors.white,
        size: 30,
      ),
      onPressed: (){
        final controller = ref.read(videoControllerProvider);
        if (controller != null) {
          controller.player.playOrPause();
        }
      },
    );
  }
}