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
  final _controller = PageController();
  final _videos = maqamVideos.where((video) => !video.isShort).toList();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) return const SizedBox.shrink();
    final columns = widget.columns;
    final pages = (_videos.length / columns).ceil();
    final gap = widget.width < 600 ? 12.0 : 20.0;
    final cardWidth = (widget.width - gap * (columns - 1)) / columns;
    final fontSize = DefaultTextStyle.of(context).style.fontSize ?? 14;
    final titleHeight = MediaQuery.textScalerOf(context).scale(fontSize) * 3;
    return Column(
      children: [
        SizedBox(
          height: cardWidth * 9 / 16 + titleHeight + 36,
          child: PageView.builder(
            controller: _controller,
            itemCount: pages,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, page) {
              // Keep the final page full when the count is not a multiple.
              final start = math.min(
                page * columns,
                math.max(0, _videos.length - columns),
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    SizedBox(
                      width: cardWidth,
                      child: start + i < _videos.length
                          ? _VideoCard(_videos[start + i])
                          : null,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        if (pages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: tr(context, 'Previous videos'),
                onPressed: _page > 0 ? () => _move(_page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: tr(context, 'Next videos'),
                onPressed: _page < pages - 1 ? () => _move(_page + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
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
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xEFFFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.emerald,
                      size: 28,
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
            padding: const EdgeInsets.all(14),
            child: AppText(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}
