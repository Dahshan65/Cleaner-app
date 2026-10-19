import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

final ValueNotifier<ThemeMode> appThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.system);

void main() {
  runApp(const CleanerApp());
}

class CleanerApp extends StatelessWidget {
  const CleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'منظف الهاتف',
          locale: const Locale('ar'),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF2F6FED),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF2F6FED),
            brightness: Brightness.dark,
          ),
          home: const RootScreen(),
        );
      },
    );
  }
}

String formatBytes(int bytes) {
  const gb = 1073741824;
  const mb = 1048576;
  if (bytes >= gb) {
    return '${(bytes / gb).toStringAsFixed(1)} غيغابايت';
  }
  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(1)} ميغابايت';
  }
  return '${(bytes / 1024).round()} كيلوبايت';
}

String formatDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}/$m/$day';
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;
  final ValueNotifier<int> _dupTab = ValueNotifier<int>(0);

  @override
  void dispose() {
    _dupTab.dispose();
    super.dispose();
  }

  void _openDuplicates(int tab) {
    _dupTab.value = tab;
    setState(() {
      _index = 1;
    });
  }

  void _openLarge() {
    setState(() {
      _index = 2;
    });
  }

  void _openSimilar() {
    setState(() {
      _index = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onOpenDuplicates: _openDuplicates,
        onOpenLarge: _openLarge,
        onOpenSimilar: _openSimilar,
      ),
      DuplicatesHub(tab: _dupTab),
      const LargeFilesScreen(),
      const SimilarImagesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index > 3 ? 3 : _index,
        onDestinationSelected: (i) {
          setState(() {
            _index = i == 3 ? 4 : i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_copy),
            label: 'المكرر',
          ),
          NavigationDestination(
            icon: Icon(Icons.cleaning_services_outlined),
            label: 'الكبيرة',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// الرئيسية
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenDuplicates,
    required this.onOpenLarge,
    required this.onOpenSimilar,
  });

  final ValueChanged<int> onOpenDuplicates;
  final VoidCallback onOpenLarge;
  final VoidCallback onOpenSimilar;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _imageCount;
  int? _videoCount;
  bool _scanning = false;
  double? _freeMb;
  double? _totalMb;

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    try {
      final plugin = DiskSpacePlus();
      final free = await plugin.getFreeDiskSpace;
      final total = await plugin.getTotalDiskSpace;
      if (!mounted) {
        return;
      }
      setState(() {
        _freeMb = free;
        _totalMb = total;
      });
    } catch (_) {}
  }

  Future<int> _count(RequestType type) async {
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: type,
    );
    if (paths.isEmpty) {
      return 0;
    }
    return await paths.first.assetCountAsync;
  }

  Future<void> _scan() async {
    if (_scanning) {
      return;
    }
    setState(() {
      _scanning = true;
    });
    try {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.hasAccess) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('نحتاج إذن الوصول إلى الصور والفيديو'),
            action: SnackBarAction(
              label: 'الإعدادات',
              onPressed: PhotoManager.openSetting,
            ),
          ),
        );
        return;
      }
      final images = await _count(RequestType.image);
      final videos = await _count(RequestType.video);
      if (!mounted) {
        return;
      }
      setState(() {
        _imageCount = images;
        _videoCount = videos;
      });
      await _loadStorage();
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('منظف الهاتف'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StorageSummary(freeMb: _freeMb, totalMb: _totalMb),
                  const SizedBox(height: 12),
                  MediaSummary(images: _imageCount, videos: _videoCount),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _scan,
                      icon: _scanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        _scanning ? 'جارٍ الفحص…' : 'افحص الآن',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      CategoryCard(
                        icon: Icons.content_copy,
                        title: 'صور مكررة',
                        subtitle: 'افتح للبحث',
                        onTap: () {
                          widget.onOpenDuplicates(0);
                        },
                      ),
                      CategoryCard(
                        icon: Icons.photo_library_outlined,
                        title: 'صور متشابهة',
                        subtitle: 'افتح للبحث',
                        onTap: widget.onOpenSimilar,
                      ),
                      CategoryCard(
                        icon: Icons.videocam_outlined,
                        title: 'فيديوهات مكررة',
                        subtitle: 'افتح للبحث',
                        onTap: () {
                          widget.onOpenDuplicates(1);
                        },
                      ),
                      CategoryCard(
                        icon: Icons.sd_storage_outlined,
                        title: 'ملفات كبيرة',
                        subtitle: 'افتح للبحث',
                        onTap: widget.onOpenLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'برمجة: وائل دهشان',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StorageSummary extends StatelessWidget {
  const StorageSummary({
    super.key,
    required this.freeMb,
    required this.totalMb,
  });

  final double? freeMb;
  final double? totalMb;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final free = freeMb;
    final total = totalMb;
    final known = free != null && total != null && total > 0;

    double ratio = 0;
    String percent = '—';
    String usedText = 'جارٍ قراءة المساحة…';
    String detailText = '';

    if (known) {
      final usedMb = total - free;
      ratio = (usedMb / total).clamp(0.0, 1.0);
      percent = '${(ratio * 100).round()}%';
      usedText = '${formatBytes((usedMb * 1048576).round())} مستخدمة';
      detailText =
          'متبقي ${formatBytes((free * 1048576).round())} من ${formatBytes((total * 1048576).round())}';
    }

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: known ? ratio : null,
                      strokeWidth: 9,
                      backgroundColor: scheme.surface,
                    ),
                  ),
                  Text(percent, style: textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usedText, style: textTheme.titleSmall),
                  if (detailText.isNotEmpty) const SizedBox(height: 4),
                  if (detailText.isNotEmpty)
                    Text(detailText, style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MediaSummary extends StatelessWidget {
  const MediaSummary({super.key, required this.images, required this.videos});

  final int? images;
  final int? videos;

  Widget _stat(BuildContext context, IconData icon, String label, int? value) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: scheme.primary, size: 30),
          const SizedBox(height: 8),
          Text(
            value == null ? '—' : '$value',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _stat(context, Icons.image_outlined, 'صورة', images),
                _stat(context, Icons.videocam_outlined, 'فيديو', videos),
              ],
            ),
            if (images == null || videos == null) const SizedBox(height: 12),
            if (images == null || videos == null)
              Text(
                'اضغط «افحص الآن» لمعرفة عدد ملفاتك',
                style: textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: scheme.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodySmall),
                  Text(subtitle, style: textTheme.titleSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// المكرر
// ---------------------------------------------------------------------------

class DuplicatesHub extends StatefulWidget {
  const DuplicatesHub({super.key, required this.tab});

  final ValueNotifier<int> tab;

  @override
  State<DuplicatesHub> createState() => _DuplicatesHubState();
}

class _DuplicatesHubState extends State<DuplicatesHub>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  void _syncFromNotifier() {
    if (_controller.index != widget.tab.value
