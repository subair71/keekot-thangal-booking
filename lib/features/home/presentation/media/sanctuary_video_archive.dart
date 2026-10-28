import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/widgets/components.dart';
import 'video_catalog.dart';
import 'video_gallery.dart';
import 'youtube_player.dart';

/// Uses the same curated long-form catalogue as the existing video gallery.
/// No sample walkthrough titles, durations or chapter timestamps are attached
/// to unrelated recordings. Every player has a direct YouTube fallback link.
class SanctuaryVideoArchive extends StatefulWidget {
  const SanctuaryVideoArchive({super.key});

  @override
  State<SanctuaryVideoArchive> createState() => _SanctuaryVideoArchiveState();
}

class _SanctuaryVideoArchiveState extends State<SanctuaryVideoArchive> {
  final videos = maqamVideos.where((video) => !video.isShort).toList();
  int selected = 0;
  bool playing = false;

  String title(BuildContext context, MaqamVideo video) =>
      AppLanguage.of(context) == 'ml'
      ? video.title
      : video.englishTitle ?? video.title;

  Future<void> openYouTube(MaqamVideo video) async {
    try {
      final opened = await launchUrl(
        video.watchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        showMessage(context, 'Unable to open YouTube. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Unable to open YouTube. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const EmptyState(title: 'No recordings available yet.');
    }
    final video = videos[selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppText(
          'MEDIA SANCTUARY ARCHIVE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        const AppText(
          'Sanctified Visual Archive',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 26,
            height: 1.3,
            color: AppColors.primary,
          ),
        ),
        const AppText(
          'Full-length videos from Keekkott Bungalow Online',
          style: TextStyle(fontSize: 12, height: 1.65, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: playing
                    ? KeyedSubtree(
                        key: ValueKey('youtube-player-${video.id}'),
                        child: youtubePlayer(video.id),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          _YouTubeThumbnail(video),
                          const ColoredBox(color: Color(0x33000000)),
                          Center(
                            child: IconButton.filled(
                              key: const ValueKey('featured-video-play'),
                              tooltip:
                                  '${tr(context, 'Play video')}: ${title(context, video)}',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.ivory,
                                foregroundColor: AppColors.emerald,
                                minimumSize: const Size(56, 56),
                              ),
                              onPressed: () => setState(() => playing = true),
                              icon: const Icon(Icons.play_arrow, size: 32),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.forest.withValues(alpha: .8),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const AppText(
                                'YouTube · Full video',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.ivory,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      title(context, video),
                      key: const ValueKey('featured-video-title'),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.ivory,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('watch-featured-youtube'),
                      onPressed: () => openYouTube(video),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ivory,
                        side: const BorderSide(color: AppColors.mintStrong),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const AppText('Watch on YouTube'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: AppText(
                'Full-length recordings',
                style: TextStyle(fontSize: 12),
              ),
            ),
            AppText(
              '${videos.length} ${tr(context, 'Videos')}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < videos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 155,
                    child: Semantics(
                      selected: selected == i,
                      label:
                          '${tr(context, 'Play video')}: ${title(context, videos[i])}',
                      button: true,
                      child: Material(
                        color: selected == i
                            ? AppColors.cream
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('long-video-${videos[i].id}'),
                          onTap: () => setState(() {
                            selected = i;
                            playing = true;
                          }),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _YouTubeThumbnail(videos[i]),
                                    const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: AppColors.ivory,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: AppText(
                                  title(context, videos[i]),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.55,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const AppText('Videos'),
                  actions: const [HeaderLanguageToggle()],
                ),
                body: const PageContainer(child: VideoGallery()),
              ),
            ),
          ),
          icon: const Icon(Icons.video_library_outlined, size: 18),
          label: const AppText('Browse sanctuary recordings'),
        ),
      ],
    );
  }
}

class _YouTubeThumbnail extends StatelessWidget {
  const _YouTubeThumbnail(this.video);
  final MaqamVideo video;
  @override
  Widget build(BuildContext context) => Image.network(
    video.thumbnailUrl,
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: AppColors.forest,
      child: Center(
        child: Icon(
          Icons.video_library_outlined,
          color: AppColors.mintStrong,
          size: 32,
        ),
      ),
    ),
  );
}
