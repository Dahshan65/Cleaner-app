import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

final ValueNotifier<ThemeMode> appThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.system);

// متحكم عام للغة التطبيق (العربية افتراضياً)
final ValueNotifier<Locale> appLocale = ValueNotifier<Locale>(const Locale('ar'));

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
        return ValueListenableBuilder<Locale>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: locale.languageCode == 'ar' ? 'منظف الهاتف' : 'Phone Cleaner',
              locale: locale,
              builder: (context, child) {
                return Directionality(
                  textDirection: locale.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
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
      },
    );
  }
}

String formatBytes(int bytes, String lang) {
  const gb = 1073741824;
  const mb = 1048576;
  if (bytes >= gb) {
    return '${(bytes / gb).toStringAsFixed(1)} ${lang == 'ar' ? 'غيغابايت' : 'GB'}';
  }
  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(1)} ${lang == 'ar' ? 'ميغابايت' : 'MB'}';
  }
  return '${(bytes / 1024).round()} ${lang == 'ar' ? 'كيلوبايت' : 'KB'}';
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
    final isAr = appLocale.value.languageCode == 'ar';
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: isAr ? 'الرئيسية' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.content_copy),
            label: isAr ? 'المكرر' : 'Duplicates',
          ),
          NavigationDestination(
            icon: const Icon(Icons.cleaning_services_outlined),
            label: isAr ? 'الكبيرة' : 'Large',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: isAr ? 'الإعدادات' : 'Settings',
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
      final isAr = appLocale.value.languageCode == 'ar';
      if (!perm.hasAccess) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'نحتاج إذن الوصول إلى الصور والفيديو' : 'Permission needed for photos & videos'),
            action: SnackBarAction(
              label: isAr ? 'الإعدادات' : 'Settings',
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
    final isAr = appLocale.value.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'منظف الهاتف' : 'Phone Cleaner'),
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
                        _scanning 
                            ? (isAr ? 'جارٍ الفحص…' : 'Scanning...') 
                            : (isAr ? 'افحص الآن' : 'Scan Now'),
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
                        title: isAr ? 'صور مكررة' : 'Duplicate Photos',
                        subtitle: isAr ? 'افتح للبحث' : 'Tap to search',
                        onTap: () {
                          widget.onOpenDuplicates(0);
                        },
                      ),
                      CategoryCard(
                        icon: Icons.photo_library_outlined,
                        title: isAr ? 'صور متشابهة' : 'Similar Photos',
                        subtitle: isAr ? 'افتح للبحث' : 'Tap to search',
                        onTap: widget.onOpenSimilar,
                      ),
                      CategoryCard(
                        icon: Icons.videocam_outlined,
                        title: isAr ? 'فيديوهات مكررة' : 'Duplicate Videos',
                        subtitle: isAr ? 'افتح للبحث' : 'Tap to search',
                        onTap: () {
                          widget.onOpenDuplicates(1);
                        },
                      ),
                      CategoryCard(
                        icon: Icons.sd_storage_outlined,
                        title: isAr ? 'ملفات كبيرة' : 'Large Files',
                        subtitle: isAr ? 'افتح للبحث' : 'Tap to search',
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
                isAr ? 'برمجة: وائل دهشان' : 'Developer: Wael Dahshan',
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
    final isAr = appLocale.value.languageCode == 'ar';
    final lang = isAr ? 'ar' : 'en';

    double ratio = 0;
    String percent = '—';
    String usedText = isAr ? 'جارٍ قراءة المساحة…' : 'Reading storage...';
    String detailText = '';

    if (known) {
      final usedMb = total - free;
      ratio = (usedMb / total).clamp(0.0, 1.0);
      percent = '${(ratio * 100).round()}%';
      usedText = '${formatBytes((usedMb * 1048576).round(), lang)} ${isAr ? 'مستخدمة' : 'used'}';
      detailText = isAr
          ? 'متبقي ${formatBytes((free * 1048576).round(), lang)} من ${formatBytes((total * 1048576).round(), lang)}'
          : '${formatBytes((free * 1048576).round(), lang)} free of ${formatBytes((total * 1048576).round(), lang)}';
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
    final isAr = appLocale.value.languageCode == 'ar';

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _stat(context, Icons.image_outlined, isAr ? 'صورة' : 'Photos', images),
                _stat(context, Icons.videocam_outlined, isAr ? 'فيديو' : 'Videos', videos),
              ],
            ),
            if (images == null || videos == null) const SizedBox(height: 12),
            if (images == null || videos == null)
              Text(
                isAr ? 'اضغط «افحص الآن» لمعرفة عدد ملفاتك' : 'Tap "Scan Now" to count files',
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
    if (_controller.index != widget.tab.value) {
      _controller.animateTo(widget.tab.value);
    }
  }

  void _syncToNotifier() {
    if (!_controller.indexIsChanging) {
      widget.tab.value = _controller.index;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
    widget.tab.addListener(_syncFromNotifier);
    _controller.addListener(_syncToNotifier);
  }

  @override
  void dispose() {
    widget.tab.removeListener(_syncFromNotifier);
    _controller.removeListener(_syncToNotifier);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = appLocale.value.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'المكرر' : 'Duplicates'),
        centerTitle: false,
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Tab(text: isAr ? 'الصور' : 'Photos'),
            Tab(text: isAr ? 'الفيديوهات' : 'Videos'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _controller,
          children: const [
            DuplicatesScreen(type: RequestType.image),
            DuplicatesScreen(type: RequestType.video),
          ],
        ),
      ),
    );
  }
}

class DuplicatesScreen extends StatefulWidget {
  const DuplicatesScreen({super.key, required this.type});

  final RequestType type;

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen>
    with AutomaticKeepAliveClientMixin {
  bool _scanning = false;
  bool _scanned = false;
  String _status = '';
  double? _progress;
  List<List<AssetEntity>> _groups = [];
  final Set<String> _selected = {};
  final Map<String, int> _sizes = {};

  @override
  bool get wantKeepAlive => true;

  bool get _isVideo {
    return widget.type == RequestType.video;
  }

  void _msg(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  int _selectedBytes() {
    var total = 0;
    for (final id in _selected) {
      total += _sizes[id] ?? 0;
    }
    return total;
  }

  Future<void> _scan() async {
    if (_scanning) {
      return;
    }
    final isAr = appLocale.value.languageCode == 'ar';
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      _msg(isAr ? 'نحتاج إذن الوصول إلى الصور والفيديو' : 'Permission needed');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _groups = [];
      _selected.clear();
      _sizes.clear();
      _progress = null;
      _status = isAr ? 'جارٍ تحميل القائمة…' : 'Loading list...';
    });

    try {
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: widget.type,
      );
      List<AssetEntity> assets = [];
      if (paths.isNotEmpty) {
        final count = await paths.first.assetCountAsync;
        assets = await paths.first.getAssetListRange(start: 0, end: count);
      }

      final byKey = <String, List<AssetEntity>>{};
      for (var i = 0; i < assets.length; i++) {
        try {
          final file = await assets[i].originFile;
          if (file != null) {
            final len = await file.length();
            _sizes[assets[i].id] = len;
            final key = '${len}_${assets[i].duration}';
            byKey.putIfAbsent(key, () => []).add(assets[i]);
          }
        } catch (_) {}
        if (i % 20 == 0 && mounted) {
          setState(() {
            _status = isAr
                ? 'فحص الملفات ${i + 1} من ${assets.length}'
                : 'Scanning files ${i + 1} of ${assets.length}';
            _progress = (i + 1) / assets.length * 0.5;
          });
        }
      }

      final candidates = byKey.values.where((l) => l.length > 1).toList();
      final groups = <List<AssetEntity>>[];
      for (var i = 0; i < candidates.length; i++) {
        final byHash = <String, List<AssetEntity>>{};
        for (final a in candidates[i]) {
          try {
            final file = await a.originFile;
            if (file == null) {
              continue;
            }
            final digest = await md5.bind(file.openRead()).first;
            byHash.putIfAbsent(digest.toString(), () => []).add(a);
          } catch (_) {}
        }
        for (final g in byHash.values) {
          if (g.length > 1) {
            g.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
            groups.add(g);
          }
        }
        if (mounted) {
          setState(() {
            _status = isAr
                ? 'مقارنة المحتوى ${i + 1} من ${candidates.length}'
                : 'Comparing content ${i + 1} of ${candidates.length}';
            _progress = 0.5 + (i + 1) / candidates.length * 0.5;
          });
        }
      }

      for (final g in groups) {
        for (var k = 1; k < g.length; k++) {
          _selected.add(g[k].id);
        }
      }
      _groups = groups;
    } catch (e) {
      _msg(isAr ? 'حدث خطأ أثناء الفحص' : 'Error during scan');
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanned = true;
        });
      }
    }
  }

  void _toggle(List<AssetEntity> group, AssetEntity asset) {
    final isAr = appLocale.value.languageCode == 'ar';
    if (_selected.contains(asset.id)) {
      setState(() {
        _selected.remove(asset.id);
      });
      return;
    }
    var remaining = 0;
    for (final x in group) {
      if (x.id != asset.id && !_selected.contains(x.id)) {
        remaining++;
      }
    }
    if (remaining == 0) {
      _msg(isAr ? 'احتفظ بنسخة واحدة على الأقل في كل مجموعة' : 'Keep at least one copy in each group');
      return;
    }
    setState(() {
      _selected.add(asset.id);
    });
  }

  Future<void> _delete() async {
    final isAr = appLocale.value.languageCode == 'ar';
    final lang = isAr ? 'ar' : 'en';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: Text(isAr ? 'حذف الملفات المحددة؟' : 'Delete selected files?'),
          content: Text(
            isAr
                ? 'عدد الملفات: ${_selected.length}\nسيطلب منك أندرويد تأكيد الحذف.'
                : 'Files count: ${_selected.length}\nAndroid will ask for deletion confirmation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(isAr ? 'متابعة' : 'Continue'),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      return;
    }

    final deleted = await PhotoManager.editor.deleteWithIds(
      _selected.toList(),
    );
    if (!mounted) {
      return;
    }
    final newGroups = <List<AssetEntity>>[];
    for (final g in _groups) {
      final rest = g.where((a) => !deleted.contains(a.id)).toList();
      if (rest.length > 1) {
        newGroups.add(rest);
      }
    }
    setState(() {
      _selected.removeAll(deleted);
      _groups = newGroups;
    });
    _msg(isAr ? 'تم حذف ${deleted.length} ملف' : '${deleted.length} files deleted');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final isAr = appLocale.value.languageCode == 'ar';
    final lang = isAr ? 'ar' : 'en';

    if (_scanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(_status),
            ],
          ),
        ),
      );
    }

    if (!_scanned) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isVideo ? Icons.videocam_outlined : Icons.content_copy,
                size: 56,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _isVideo
                    ? (isAr ? 'ابحث عن الفيديوهات المتطابقة تمامًا. قد يستغرق الفحص بعض الوقت.' : 'Find exact duplicate videos. Might take a moment.')
                    : (isAr ? 'ابحث عن الصور المتطابقة تمامًا ووفّر مساحة هاتفك.' : 'Find exact duplicate photos and free up space.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.search),
                label: Text(isAr ? 'ابدأ البحث' : 'Start Scan'),
              ),
            ],
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 56,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(_isVideo
                  ? (isAr ? 'لم نجد فيديوهات مكررة' : 'No duplicate videos found')
                  : (isAr ? 'لم نجد صورًا مكررة' : 'No duplicate photos found')),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _scan,
                child: Text(isAr ? 'فحص مرة أخرى' : 'Scan Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _groups.length,
            itemBuilder: (context, i) {
              final g = _groups[i];
              return Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'مجموعة ${i + 1} · ${g.length} ملفات'
                            : 'Group ${i + 1} · ${g.length} files',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in g)
                            DuplicateThumb(
                              key: ValueKey(a.id),
                              asset: a,
                              selected: _selected.contains(a.id),
                              onTap: () => _toggle(g, a),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr
                    ? 'تم تحديد ${_selected.length} ملفات · توفير ${formatBytes(_selectedBytes(), lang)}'
                    : '${_selected.length} files selected · Save ${formatBytes(_selectedBytes(), lang)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: _selected.isEmpty ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(isAr ? 'حذف المحدد' : 'Delete Selected'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DuplicateThumb extends StatefulWidget {
  const DuplicateThumb({
    super.key,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<DuplicateThumb> createState() => _DuplicateThumbState();
}

class _DuplicateThumbState extends State<DuplicateThumb> {
  late final Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
  }

  String _durationText() {
    final d = widget.asset.videoDuration;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    final isVideo = widget.asset.type == AssetType.video;
    final isAr = appLocale.value.languageCode == 'ar';

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: FutureBuilder<Uint8List?>(
                future: _future,
                builder: (context, snap) {
                  final data = snap.data;
                  if (data == null) {
                    return Container(color: scheme.surface);
                  }
                  return Image.memory(data, fit: BoxFit.cover);
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: widget.selected ? scheme.error : scheme.primary,
                  width: 2.5,
                ),
                color: widget.selected ? scheme.error.withAlpha(64) : null,
              ),
            ),
            if (isVideo)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _durationText(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            if (widget.selected)
              Positioned(
                top: 4,
                left: 4,
                child: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: scheme.error,
                ),
              ),
            if (!widget.selected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isAr ? 'احتفظ' : 'Keep',
                    style: TextStyle(fontSize: 10, color: scheme.onPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// الصور المتشابهة
// ---------------------------------------------------------------------------

class SimilarImagesScreen extends StatefulWidget {
  const SimilarImagesScreen({super.key});

  @override
  State<SimilarImagesScreen> createState() => _SimilarImagesScreenState();
}

class _SimilarImagesScreenState extends State<SimilarImagesScreen>
    with AutomaticKeepAliveClientMixin {
  bool _scanning = false;
  bool _scanned = false;
  String _status = '';
  double? _progress;
  List<List<AssetEntity>> _groups = [];
  final Set<String> _selected = {};
  final Map<String, int> _sizes = {};

  @override
  bool get wantKeepAlive => true;

  void _msg(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  int _selectedBytes() {
    var total = 0;
    for (final id in _selected) {
      total += _sizes[id] ?? 0;
    }
    return total;
  }

  Future<void> _scan() async {
    if (_scanning) {
      return;
    }
    final isAr = appLocale.value.languageCode == 'ar';
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      _msg(isAr ? 'نحتاج إذن الوصول إلى الصور' : 'Permission needed');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _groups = [];
      _selected.clear();
      _sizes.clear();
      _progress = null;
      _status = isAr ? 'جارٍ تحميل الصور…' : 'Loading images...';
    });

    try {
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );
      List<AssetEntity> assets = [];
      if (paths.isNotEmpty) {
        final count = await paths.first.assetCountAsync;
        assets = await paths.first.getAssetListRange(start: 0, end: count);
      }

      final byTimeGroup = <String, List<AssetEntity>>{};
      for (var i = 0; i < assets.length; i++) {
        final a = assets[i];
        try {
          final file = await a.originFile;
          if (file != null) {
            _sizes[a.id] = await file.length();
          }
        } catch (_) {}

        final d = a.createDateTime;
        final timeKey = '${d.year}-${d.month}-${d.day}-${d.hour}-${d.minute ~/ 2}';
        byTimeGroup.putIfAbsent(timeKey, () => []).add(a);

        if (i % 20 == 0 && mounted) {
          setState(() {
            _status = isAr
                ? 'تحليل الصور ${i + 1} من ${assets.length}'
                : 'Analyzing images ${i + 1} of ${assets.length}';
            _progress = (i + 1) / assets.length;
          });
        }
      }

      final groups = <List<AssetEntity>>[];
      for (final entry in byTimeGroup.entries) {
        if (entry.value.length > 1) {
          entry.value.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
          groups.add(entry.value);
        }
      }

      for (final g in groups) {
        for (var k = 1; k < g.length; k++) {
          _selected.add(g[k].id);
        }
      }

      _groups = groups;
    } catch (e) {
      _msg(isAr ? 'حدث خطأ أثناء الفحص' : 'Error during scan');
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanned = true;
        });
      }
    }
  }

  void _toggle(List<AssetEntity> group, AssetEntity asset) {
    final isAr = appLocale.value.languageCode == 'ar';
    if (_selected.contains(asset.id)) {
      setState(() {
        _selected.remove(asset.id);
      });
      return;
    }
    var remaining = 0;
    for (final x in group) {
      if (x.id != asset.id && !_selected.contains(x.id)) {
        remaining++;
      }
    }
    if (remaining == 0) {
      _msg(isAr ? 'احتفظ بنسخة واحدة على الأقل في كل مجموعة' : 'Keep at least one copy in each group');
      return;
    }
    setState(() {
      _selected.add(asset.id);
    });
  }

  Future<void> _delete() async {
    final isAr = appLocale.value.languageCode == 'ar';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: Text(isAr ? 'حذف الصور المحددة؟' : 'Delete selected images?'),
          content: Text(
            isAr
                ? 'عدد الصور: ${_selected.length}\nسيطلب منك أندرويد تأكيد الحذف.'
                : 'Images count: ${_selected.length}\nAndroid will ask for confirmation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(isAr ? 'متابعة' : 'Continue'),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      return;
    }

    final deleted = await PhotoManager.editor.deleteWithIds(
      _selected.toList(),
    );
    if (!mounted) {
      return;
    }
    final newGroups = <List<AssetEntity>>[];
    for (final g in _groups) {
      final rest = g.where((a) => !deleted.contains(a.id)).toList();
      if (rest.length > 1) {
        newGroups.add(rest);
      }
    }
    setState(() {
      _selected.removeAll(deleted);
      _groups = newGroups;
    });
    _msg(isAr ? 'تم حذف ${deleted.length} صورة' : '${deleted.length} images deleted');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final isAr = appLocale.value.languageCode == 'ar';
    final lang = isAr ? 'ar' : 'en';

    if (_scanning) {
      return Scaffold(
        appBar: AppBar(title: Text(isAr ? 'صور متشابهة' : 'Similar Photos')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 16),
                Text(_status),
              ],
            ),
          ),
        ),
      );
    }

    if (!_scanned) {
      return Scaffold(
        appBar: AppBar(title: Text(isAr ? 'صور متشابهة' : 'Similar Photos')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  isAr
                      ? 'ابحث عن الصور المتقاربة والمتشابهة في التوقيت والمحتوى لتنظيفها.'
                      : 'Find similar and close-timed photos to clean up.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.search),
                  label: Text(isAr ? 'ابدأ البحث' : 'Start Scan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(isAr ? 'صور متشابهة' : 'Similar Photos')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                Text(isAr ? 'لم نجد صورًا متشابهة' : 'No similar photos found'),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _scan,
                  child: Text(isAr ? 'فحص مرة أخرى' : 'Scan Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'صور متشابهة' : 'Similar Photos')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groups.length,
              itemBuilder: (context, i) {
                final g = _groups[i];
                return Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? 'مجموعة تقارب ${i + 1} · ${g.length} صور'
                              : 'Similar group ${i + 1} · ${g.length} photos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in g)
                              DuplicateThumb(
                                key: ValueKey(a.id),
                                asset: a,
                                selected: _selected.contains(a.id),
                                onTap: () => _toggle(g, a),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr
                      ? 'تم تحديد ${_selected.length} صور · توفير ${formatBytes(_selectedBytes(), lang)}'
                      : '${_selected.length} photos selected · Save ${formatBytes(_selectedBytes(), lang)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    onPressed: _selected.isEmpty ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(isAr ? 'حذف المحدد' : 'Delete Selected'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// الملفات الكبيرة
// ---------------------------------------------------------------------------

class LargeFilesScreen extends StatefulWidget {
  const LargeFilesScreen({super.key});

  @override
  State<LargeFilesScreen> createState() => _LargeFilesScreenState();
}

class _LargeFilesScreenState extends State<LargeFilesScreen> {
  static const int maxItems = 100;

  bool _videos = true;
  bool _scanning = false;
  bool _scanned = false;
  String _status = '';
  double? _progress;
  List<AssetEntity> _items = [];
  final Map<String, int> _sizes = {};
  final Set<String> _selected = {};

  void _msg(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  int _selectedBytes() {
    var total = 0;
    for (final id in _selected) {
      total += _sizes[id] ?? 0;
    }
    return total;
  }

  void _switchType(bool videos) {
    if (_scanning || _videos == videos) {
      return;
    }
    setState(() {
      _videos = videos;
      _scanned = false;
      _items = [];
      _sizes.clear();
      _selected.clear();
    });
  }

  Future<void> _scan() async {
    if (_scanning) {
      return;
    }
    final isAr = appLocale.value.languageCode == 'ar';
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      _msg(isAr ? 'نحتاج إذن الوصول إلى الصور والفيديو' : 'Permission needed');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _items = [];
      _sizes.clear();
      _selected.clear();
      _progress = null;
      _status = isAr ? 'جارٍ تحميل القائمة…' : 'Loading list...';
    });

    try {
      final type = _videos ? RequestType.video : RequestType.image;
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: type,
      );
      List<AssetEntity> assets = [];
      if (paths.isNotEmpty) {
        final count = await paths.first.assetCountAsync;
        assets = await paths.first.getAssetListRange(start: 0, end: count);
      }

      final sizes = <String, int>{};
      for (var i = 0; i < assets.length; i++) {
        try {
          final file = await assets[i].originFile;
          if (file != null) {
            sizes[assets[i].id] = await file.length();
          }
        } catch (_) {}
        if (i % 20 == 0 && mounted) {
          setState(() {
            _status = isAr
                ? 'فحص الملفات ${i + 1} من ${assets.length}'
                : 'Scanning files ${i + 1} of ${assets.length}';
            _progress = (i + 1) / assets.length;
          });
        }
      }

      final withSize = assets.where((a) => sizes.containsKey(a.id)).toList();
      withSize.sort((a, b) => (sizes[b.id] ?? 0).compareTo(sizes[a.id] ?? 0));
      final top = withSize.take(maxItems).toList();

      _sizes.addAll(sizes);
      _items = top;
    } catch (e) {
      _msg(isAr ? 'حدث خطأ أثناء الفحص' : 'Error during scan');
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanned = true;
        });
      }
    }
  }

  void _toggle(AssetEntity a) {
    setState(() {
      if (_selected.contains(a.id)) {
        _selected.remove(a.id);
      } else {
        _selected.add(a.id);
      }
    });
  }

  Future<void> _delete() async {
    final isAr = appLocale.value.languageCode == 'ar';
    final lang = isAr ? 'ar' : 'en';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: Text(isAr ? 'حذف الملفات المحددة؟' : 'Delete selected files?'),
          content: Text(
            isAr
                ? 'عدد الملفات: ${_selected.length}\nالمساحة: ${formatBytes(_selectedBytes(), lang)}\nسيطلب منك أندرويد تأكيد الحذف.'
                : 'Files: ${_selected.length}\nSize: ${formatBytes(_selectedBytes(), lang)}\nAndroid will ask for confirmation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(isAr ? 'متابعة' : 'Continue'),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      return;
    }

    final deleted = await PhotoManager.editor.deleteWithIds(
      _selected.toList(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _items = _items.where((a) => !deleted.contains(a.id)).toList();
      _selected.removeAll(deleted);
    });
    _msg(isAr ? 'تم حذف ${deleted.length} ملف' : '${deleted.length} files deleted');
  }

  Widget _typeSwitch() {
    final isAr = appLocale.value.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment<bool>(
            value: true,
            icon: const Icon(Icons.videocam_outlined),
            label: Text(isAr ? 'فيديوهات' : 'Videos'),
          ),
          ButtonSegment<bool>(
            value: false,
            icon: const Icon(Icons.image_outlined),
            label: Text(isAr ? 'صور' : 'Photos'),
          ),
        ],
        selected: {_videos},
        onSelectionChanged: (s) {
          _switchType(s.first);
        },
      ),
    );
  }

  Widget _body(ColorScheme scheme) {
    final isAr = appLocale.value.languageCode == 'ar';
    final lang = isAr ? 'ar' : 'en';

    if (_scanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(_status),
            ],
          ),
        ),
      );
    }

    if (!_scanned) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sd_storage_outlined, size: 56, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                _videos
                    ? (isAr ? 'اعرض أكبر الفيديوهات حجمًا لتحذف ما لا تحتاجه.' : 'View largest videos to clean up space.')
                    : (isAr ? 'اعرض أكبر الصور حجمًا لتحذف ما لا تحتاجه.' : 'View largest photos to clean up space.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.search),
                label: Text(isAr ? 'ابدأ البحث' : 'Start Scan'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 56,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(isAr ? 'لا توجد ملفات' : 'No files found'),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _scan,
                child: Text(isAr ? 'فحص مرة أخرى' : 'Scan Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final a = _items[i];
              final picked = _selected.contains(a.id);
              return Card(
                elevation: 0,
                color: picked
                    ? scheme.errorContainer
                    : scheme.surfaceContainerHighest,
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _toggle(a),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ThumbBox(key: ValueKey(a.id), asset: a, size: 64),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatBytes(_sizes[a.id] ?? 0, lang),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatDate(a.createDateTime),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: picked,
                          onChanged: (_) => _toggle(a),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr
                    ? 'تم تحديد ${_selected.length} ملفات · توفير ${formatBytes(_selectedBytes(), lang)}'
                    : '${_selected.length} files selected · Save ${formatBytes(_selectedBytes(), lang)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: _selected.isEmpty ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(isAr ? 'حذف المحدد' : 'Delete Selected'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAr = appLocale.value.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الملفات الكبيرة' : 'Large Files'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _typeSwitch(),
            Expanded(child: _body(scheme)),
          ],
        ),
      ),
    );
  }
}

class ThumbBox extends StatefulWidget {
  const ThumbBox({super.key, required this.asset, this.size = 64});

  final AssetEntity asset;
  final double size;

  @override
  State<ThumbBox> createState() => _ThumbBoxState();
}

class _ThumbBoxState extends State<ThumbBox> {
  late final Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.asset.thumbnailDataWithSize(const ThumbnailSize(160, 160));
  }

  String _durationText() {
    final d = widget.asset.videoDuration;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVideo = widget.asset.type == AssetType.video;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Uint8List?>(
              future: _future,
              builder: (context, snap) {
                final data = snap.data;
                if (data == null) {
                  return Container(color: scheme.surface);
                }
                return Image.memory(data, fit: BoxFit.cover);
              },
            ),
          ),
          if (isVideo)
            Positioned(
              bottom: 3,
              left: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _durationText(),
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// الإعدادات (مع زر تبديل اللغة)
// ---------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAr = appLocale.value.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات' : 'Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // قسم اللغة
            Text(isAr ? 'لغة التطبيق' : 'App Language', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            ValueListenableBuilder<Locale>(
              valueListenable: appLocale,
              builder: (context, locale, _) {
                return SegmentedButton<Locale>(
                  segments: const [
                    ButtonSegment<Locale>(
                      value: Locale('ar'),
                      label: Text('العربية'),
                    ),
                    ButtonSegment<Locale>(
                      value: Locale('en'),
                      label: Text('English'),
                    ),
                  ],
                  selected: {locale},
                  onSelectionChanged: (s) {
                    appLocale.value = s.first;
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            // قسم المظهر
            Text(isAr ? 'المظهر' : 'Theme', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: appThemeMode,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text(isAr ? 'تلقائي' : 'System'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(isAr ? 'فاتح' : 'Light'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(isAr ? 'داكن' : 'Dark'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) {
                    appThemeMode.value = s.first;
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(isAr ? 'الأذونات' : 'Permissions', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(Icons.lock_open_outlined, color: scheme.primary),
                title: Text(isAr ? 'إذن الصور والفيديو' : 'Photos & Videos Permission'),
                subtitle: Text(isAr ? 'افتح إعدادات النظام لتغيير الإذن' : 'Open system settings to change'),
                onTap: () {
                  PhotoManager.openSetting();
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(isAr ? 'حول التطبيق' : 'About App', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(isAr ? 'منظف الهاتف' : 'Phone Cleaner'),
                subtitle: Text(isAr ? 'برمجة: وائل دهشان' : 'Developer: Wael Dahshan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
