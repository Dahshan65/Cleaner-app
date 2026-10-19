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
    } catch (_) {
      // تعذّرت قراءة المساحة، تبقى البطاقة بدون أرقام
    }
  }

  Future<int> _count(RequestType type) async {
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: type,
    );
    if (paths.isEmpty) {
      return 0;
    }
    return paths.first.assetCountAsync;
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
        } catch (_) {
          // تجاهل الملف الذي لا يمكن قراءته
        }
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
          } catch (_) {
            // تجاهل الملف الذي لا يمكن قراءته
          }
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
          title: const Text('حذف الملفات المحددة؟'),
          content: Text(
            'عدد الملفات: ${_selected.length}\nسيطلب منك أندرويد تأكيد الحذف.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('متابعة'),
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
    _msg('تم حذف ${deleted.length} ملف');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

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
                    ? 'ابحث عن الفيديوهات المتطابقة تمامًا. قد يستغرق الفحص بعض الوقت.'
                    : 'ابحث عن الصور المتطابقة تمامًا ووفّر مساحة هاتفك.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.search),
                label: const Text('ابدأ البحث'),
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
              Text(_isVideo ? 'لم نجد فيديوهات مكررة' : 'لم نجد صورًا مكررة'),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _scan,
                child: const Text('فحص مرة أخرى'),
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
                        'مجموعة ${i + 1} · ${g.length} ملفات',
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
                'تم تحديد ${_selected.length} ملفات · توفير ${formatBytes(_selectedBytes())}',
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
                  label: const Text('حذف المحدد'),
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
                    'احتفظ',
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
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      _msg('نحتاج إذن الوصول إلى الصور والفيديو');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _items = [];
      _sizes.clear();
      _selected.clear();
      _progress = null;
      _status = 'جارٍ تحميل القائمة…';
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
        } catch (_) {
          // تجاهل الملف الذي لا يمكن قراءته
        }
        if (i % 20 == 0 && mounted) {
          setState(() {
            _status = 'فحص الملفات ${i + 1} من ${assets.length}';
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('حذف الملفات المحددة؟'),
          content: Text(
            'عدد الملفات: ${_selected.length}\n'
            'المساحة: ${formatBytes(_selectedBytes())}\n'
            'سيطلب منك أندرويد تأكيد الحذف.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('متابعة'),
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
    _msg('تم حذف ${deleted.length} ملف');
  }

  Widget _typeSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: true,
            icon: Icon(Icons.videocam_outlined),
            label: Text('فيديوهات'),
          ),
          ButtonSegment<bool>(
            value: false,
            icon: Icon(Icons.image_outlined),
            label: Text('صور'),
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
                    ? 'اعرض أكبر الفيديوهات حجمًا لتحذف ما لا تحتاجه.'
                    : 'اعرض أكبر الصور حجمًا لتحذف ما لا تحتاجه.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.search),
                label: const Text('ابدأ البحث'),
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
              const Text('لا توجد ملفات'),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _scan,
                child: const Text('فحص مرة أخرى'),
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
                                formatBytes(_sizes[a.id] ?? 0),
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
                'تم تحديد ${_selected.length} ملفات · توفير ${formatBytes(_selectedBytes())}',
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
                  label: const Text('حذف المحدد'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملفات الكبيرة'),
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
// الإعدادات
// ---------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('المظهر', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: appThemeMode,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('تلقائي'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('فاتح'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('داكن'),
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
            Text('الأذونات', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(Icons.lock_open_outlined, color: scheme.primary),
                title: const Text('إذن الصور والفيديو'),
                subtitle: const Text('افتح إعدادات النظام لتغيير الإذن'),
                onTap: () {
                  PhotoManager.openSetting();
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('حول التطبيق', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('منظف الهاتف'),
                subtitle: Text('برمجة: وائل دهشان'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
