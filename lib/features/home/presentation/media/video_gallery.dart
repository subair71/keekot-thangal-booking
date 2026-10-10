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
        content: Text('Unable to open YouTube. Please try again.'),
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
        const Text(
          'KEEKKOTT BUNGALOW ONLINE',
          style: TextStyle(
            color: AppColors.emerald,
            letterSpacing: 2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Moments of faith.\nStories that bring us together.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 14),
        const Text(
          'Watch glimpses of the Maqam, gatherings and moments of remembrance from our YouTube channel.',
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => _openYouTube(context, _channel),
          icon: const Icon(Icons.smart_display_outlined),
          label: const Text('Explore our YouTube channel'),
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
            final columns = constraints.maxWidth > 950
                ? 3
                : constraints.maxWidth > 560
                ? 2
                : 1;
            final width = (constraints.maxWidth - 20 * (columns - 1)) / columns;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (final video in maqamVideos.where((v) => !v.isShort))
                  SizedBox(width: width, child: _VideoCard(video)),
              ],
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
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          Text(subtitle, style: const TextStyle(color: AppColors.ink)),
        ],
      ),
      TextButton.icon(
        onPressed: () => _openYouTube(context, '$_channel/$tab'),
        label: Text('All $title'),
        icon: const Icon(Icons.arrow_outward, size: 17),
      ),
    ],
  );
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
                        child: Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close video',
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
                    label: const Text('Watch on YouTube'),
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
                    child: Text(
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
            child: Text(
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
