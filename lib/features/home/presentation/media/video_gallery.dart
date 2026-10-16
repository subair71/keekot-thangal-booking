import 'dart:async';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import 'video_catalog.dart';
import 'youtube_player.dart';

const _channel = 'https://www.youtube.com/@keekkott_bungalow_online';

Future<void> _openYouTube(BuildContext context, String url) async {
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: AppText('Unable to open YouTube. Please try again.'),
      ),
    );
  }
}

class VideoGallery extends StatelessWidget {
  const VideoGallery({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 36),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'KEEKKOTT BUNGALOW ONLINE',
          style: TextStyle(
            color: AppColors.emerald,
            letterSpacing: 2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        AppText(
          'Moments of faith.\nStories that bring us together.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 14),
        const AppText(
          'Watch glimpses of the Maqam, gatherings and moments of remembrance from our YouTube channel.',
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => _openYouTube(context, _channel),
          icon: const Icon(Icons.smart_display_outlined),
          label: const AppText('Explore our YouTube channel'),
        ),
        const SizedBox(height: 32),
        _heading(
          context,
          'Shorts',
          'Little moments, lasting meaning',
          'shorts',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 374,
          child: Scrollbar(
            child: ListView.separated(
              primary: false,
              scrollDirection: Axis.horizontal,
              itemCount: maqamVideos.where((v) => v.isShort).length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, i) => SizedBox(
                width: 182,
                child: _VideoCard(
                  maqamVideos.where((v) => v.isShort).elementAt(i),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _heading(context, 'Videos', 'Watch, reflect and reconnect', 'videos'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaQuery.sizeOf(context).width >= 1024 ? 4 : 2;
            return _LongVideoCarousel(
              key: ValueKey(columns),
              columns: columns,
              width: constraints.maxWidth,
            );
          },
        ),
      ],
    ),
  );

  Widget _heading(
    BuildContext context,
    String title,
    String subtitle,
    String tab,
  ) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 20,
    runSpacing: 8,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(title, style: Theme.of(context).textTheme.headlineSmall),
          AppText(subtitle, style: const TextStyle(color: AppColors.ink)),
        ],
      ),
      TextButton.icon(
        onPressed: () => _openYouTube(context, '$_channel/$tab'),
        label: AppText('All $title'),
        icon: const Icon(Icons.arrow_outward, size: 17),
      ),
    ],
  );
}

class _LongVideoCarousel extends StatefulWidget {
  const _LongVideoCarousel({
    super.key,
    required this.columns,
    required this.width,
  });

  final int columns;
  final double width;

  @override
  State<_LongVideoCarousel> createState() => _LongVideoCarouselState();
}

class _LongVideoCarouselState extends State<_LongVideoCarousel> {
  final _controller = ScrollController();
  final _videos = maqamVideos.where((video) => !video.isShort).toList();
  Timer? _timer;
  bool _hovered = false;
  bool _focused = false;
  bool _touching = false;

  double get _gap => widget.width < 600 ? 12.0 : 20.0;
  double get _cardWidth =>
      (widget.width - _gap * (widget.columns - 1)) / widget.columns;
  double get _stride => _cardWidth + _gap;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
  }

  void _advance() {
    if (!mounted ||
        !_controller.hasClients ||
        _videos.length <= widget.columns ||
        _hovered ||
        _focused ||
        _touching ||
        _controller.position.isScrollingNotifier.value ||
        MediaQuery.disableAnimationsOf(context) ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final index = (_controller.offset / _stride).round();
    _controller.animateTo(
      (index + 1) * _stride,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) return const SizedBox.shrink();
    final titleHeight = MediaQuery.textScalerOf(context).scale(12) * 2.8;
    return MouseRegion(
      onEnter: (_) => _hovered = true,
      onExit: (_) => _hovered = false,
      child: Focus(
        onFocusChange: (focused) => _focused = focused,
        child: Listener(
          onPointerDown: (_) => _touching = true,
          onPointerUp: (_) => _touching = false,
          onPointerCancel: (_) => _touching = false,
          child: SizedBox(
            height: _cardWidth * 9 / 16 + math.max(48, titleHeight) + 20,
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                final cycle = _stride * _videos.length;
                if (_controller.offset >= cycle) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _controller.hasClients) {
                      _controller.jumpTo(_controller.offset % cycle);
                    }
                  });
                }
                return false;
              },
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemExtent: _stride,
                itemCount: _videos.length <= widget.columns
                    ? _videos.length
                    : null,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(right: _gap),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _VideoCard(_videos[index % _videos.length]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard(this.video);
  final MaqamVideo video;

  void _play(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: video.isShort ? 420 : 960),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: tr(context, 'Close video'),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (_, constraints) => SizedBox(
                      height: math.min(
                        constraints.maxWidth /
                            (video.isShort ? 9 / 16 : 16 / 9),
                        MediaQuery.sizeOf(context).height * .62,
                      ),
                      child: ColoredBox(
                        color: Colors.black,
                        child: youtubePlayer(video.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _openYouTube(
                      context,
                      'https://www.youtube.com/watch?v=${video.id}',
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const AppText('Watch on YouTube'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _play(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: video.isShort ? 9 / 14 : 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://i.ytimg.com/vi/${video.id}/${video.isShort ? 'oar2' : 'hqdefault'}.jpg',
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: AppColors.emerald,
                    child: Center(
                      child: Icon(
                        Icons.smart_display_outlined,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x66000000)],
                    ),
                  ),
                ),
                if (video.isShort)
                  const Positioned(
                    left: 12,
                    bottom: 12,
                    child: AppText(
                      'SHORTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr(context, 'Play video'),
                  onPressed: () => _play(context),
                  color: AppColors.emerald,
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
