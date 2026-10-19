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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onOpenDuplicates: _openDuplicates,
        onOpenLarge: _openLarge,
      ),
      DuplicatesHub(tab: _dupTab),
      const LargeFilesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() {
            _index = i;
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
  });

  final ValueChanged<int> onOpenDuplicates;
  final VoidCallback onOpenLarge;

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

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة ستُضاف قريبًا')),
    );
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
                        subtitle: 'قريبًا',
                        onTap: _soon,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('المكرر'),
        centerTitle: false,
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: 'الصور'),
            Tab(text: 'الفيديوهات'),
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
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      _msg('نحتاج إذن الوصول إلى الصور والفيديو');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _groups = [];
      _selected.clear();
      _sizes.clear();
      _progress = null;
      _status = 'جارٍ تحميل القائمة…';
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
            _status = 'فحص الملفات ${i + 1} من ${assets.length}';
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
            _status = 'مقارنة المحتوى ${i + 1} من ${candidates.length}';
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
      _msg('حدث خطأ أثناء الفحص');
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
      _msg('احتفظ بنسخة واحدة على الأقل في كل مجموعة');
      return;
    }
    setState(() {
      _selected.add(asset.id);
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('حذف الملفات المحددة
