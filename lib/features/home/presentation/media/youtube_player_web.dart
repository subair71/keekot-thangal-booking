import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Widget youtubePlayer(String id) => HtmlElementView.fromTagName(
  tagName: 'iframe',
  onElementCreated: (element) {
    final frame = element as web.HTMLIFrameElement;
    frame.src = 'https://www.youtube-nocookie.com/embed/$id?autoplay=1&rel=0';
    frame.title = 'Keekkott Bungalow video player';
    frame.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';
    frame.referrerPolicy = 'strict-origin-when-cross-origin';
    frame.setAttribute('allowfullscreen', '');
    frame.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%';
  },
);
