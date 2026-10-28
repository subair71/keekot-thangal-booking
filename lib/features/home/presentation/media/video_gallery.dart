import 'dart:async';

import 'package:keekot_thangal/core/localization/app_language.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import 'video_catalog.dart';
import '../../../../core/widgets/components.dart';
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
  Widget build(BuildContext context) => Column(
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
      const SizedBox(height: 32),
      _heading(context, 'Videos', 'Watch, reflect and reconnect'),
      const SizedBox(height: 16),
      if (SanctuaryLayout.mobile(context))
        for (final video in maqamVideos.where((video) => !video.isShort))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SurfaceCard(child: _VideoCard(video)),
          )
      else
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
      const SizedBox(height: 32),
      const _ShortsSection(),
    ],
  );

  Widget _heading(BuildContext context, String title, String subtitle) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(title, style: Theme.of(context).textTheme.headlineSmall),
          AppText(subtitle, style: const TextStyle(color: AppColors.ink)),
        ],
      );
}

class _ShortsSection extends StatelessWidget {
  const _ShortsSection();

  @override
  Widget build(BuildContext context) {
    final videos = maqamVideos.where((video) => video.isShort).toList();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                'Shorts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onSelected: (_) => _openYouTube(context, '$_channel/shorts'),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'shorts',
                  child: AppText('All Shorts'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaQuery.sizeOf(context).width >= 1024 ? 4 : 2;
            final gap = constraints.maxWidth < 600 ? 12.0 : 20.0;
            final width =
                (constraints.maxWidth - gap * columns) / (columns + 0.25);
            return SizedBox(
              height: width * 1.5,
              child: ListView.separated(
                primary: false,
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                separatorBuilder: (_, _) => SizedBox(width: gap),
                itemBuilder: (_, index) =>
                    SizedBox(width: width, child: _VideoCard(videos[index])),
              ),
            );
          },
        ),
      ],
    );
  }
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
      (widget.width - _gap * widget.columns) / (widget.columns + 0.25);
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
    final scaler = MediaQuery.textScalerOf(context);
    final titleHeight = math.max(32, scaler.scale(12) * 2.8);
    final channelHeight = scaler.scale(11) * 2.8;
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
            height: _cardWidth * 9 / 16 + titleHeight + channelHeight + 28,
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
                          video.localizedTitle(AppLanguage.of(context)),
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

  Widget _longVideoCard(BuildContext context) => Material(
    color: SanctuaryLayout.mobile(context)
        ? AppColors.cream
        : Colors.transparent,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label:
              '${tr(context, 'Play video')}: ${video.localizedTitle(AppLanguage.of(context))}',
          child: InkWell(
            onTap: () => _play(context),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  'https://i.ytimg.com/vi/${video.id}/hqdefault.jpg',
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: AppColors.emerald,
                    child: Center(
                      child: Icon(
                        Icons.smart_display_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _play(context),
                child: AppText(
                  video.localizedTitle(AppLanguage.of(context)),
                  maxLines: SanctuaryLayout.mobile(context) ? null : 2,
                  overflow: SanctuaryLayout.mobile(context)
                      ? null
                      : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz, size: 20),
                onSelected: (action) {
                  if (action == 'play') {
                    _play(context);
                  } else {
                    _openYouTube(
                      context,
                      'https://www.youtube.com/watch?v=${video.id}',
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'play',
                    child: AppText('Play video'),
                  ),
                  const PopupMenuItem(
                    value: 'youtube',
                    child: AppText('Watch on YouTube'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Keekkott Bungalow Online',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Color(0xFF606060), fontSize: 11, height: 1.4),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) =>
      video.isShort ? _shortVideoCard(context) : _longVideoCard(context);

  Widget _shortVideoCard(BuildContext context) => Material(
    color: AppColors.emerald,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _play(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://i.ytimg.com/vi/${video.id}/oar2.jpg',
            fit: BoxFit.cover,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.smart_display_outlined, color: Colors.white),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.5, 1],
                colors: [
                  Color(0x22000000),
                  Colors.transparent,
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_horiz,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
              onSelected: (action) {
                if (action == 'play') {
                  _play(context);
                } else {
                  _openYouTube(
                    context,
                    'https://www.youtube.com/shorts/${video.id}',
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'play',
                  child: AppText('Play video'),
                ),
                const PopupMenuItem(
                  value: 'youtube',
                  child: AppText('Watch on YouTube'),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: AppText(
              video.localizedTitle(AppLanguage.of(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
