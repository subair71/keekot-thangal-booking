import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Widget youtubePlayer(
  String id, {
  bool autoplay = true,
  bool controls = true,
  bool loop = false,
  bool mute = false,
}) => HtmlElementView.fromTagName(
  tagName: 'iframe',
  onElementCreated: (element) {
    final frame = element as web.HTMLIFrameElement;
    final params = <String>[
      if (autoplay) 'autoplay=1',
      if (mute || (!controls && autoplay)) 'mute=1',
      if (!controls) ...['controls=0', 'disablekb=1', 'fs=0'],
      if (loop) ...['loop=1', 'playlist=$id'],
      'rel=0',
      'modestbranding=1',
      'playsinline=1',
      'iv_load_policy=3',
    ];
    frame.src =
        'https://www.youtube-nocookie.com/embed/$id?${params.join('&')}';
    frame.title = 'Keekkott Bungalow video player';
    frame.allow =
        'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen';
    frame.referrerPolicy = 'strict-origin-when-cross-origin';
    frame.setAttribute('allowfullscreen', '');
    frame.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%';
  },
);
