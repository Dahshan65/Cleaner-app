import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() => runApp(const CleanerApp());

class CleanerApp extends StatelessWidget {
  const CleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'منظف الهاتف',
      locale: const Locale('ar'),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
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
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onOpenDuplicates: () => setState(() => _index = 1)),
      const DuplicatesScreen(),
      const _ComingSoon(
        icon: Icons.cleaning_services_outlined,
        title: 'التنظيف',
        text: 'تنظيف الكاش والملفات الكبيرة سيُضاف قريبًا.',
      ),
      const _ComingSoon(
        icon: Icons.settings_outlined,
        title: 'الإعدادات',
        text: 'إعدادات التطبيق ستُضاف قريبًا.',
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.content_copy), label: 'المكرر'),
          NavigationDestination(
              icon: Icon(Icons.cleaning_services_outlined), label: 'التنظيف'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: scheme.primary),
              const SizedBox(height: 16),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenDuplicates});

  final VoidCallback onOpenDuplicates;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double usedGb = 94;
  static const double totalGb = 128;

  int? _imageCount;
  int? _videoCount;
  bool _scanning = false;

  Future<int> _count(RequestType type) async {
    final paths =
        await PhotoManager.getAssetPathList(onlyAll: true, type: type);
    if (paths.isEmpty) return 0;
    return paths.first.assetCountAsync;
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة ستُضاف قريبًا')),
    );
  }

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.hasAccess) {
        if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _imageCount = images;
        _videoCount = videos;
      });
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مساحة الهاتف'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StorageSummary(usedGb: usedGb, totalGb: totalGb),
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
                  if (_imageCount != null && _videoCount != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: scheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: scheme.onPrimaryContainer),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'تم العثور على $_imageCount صورة و $_videoCount فيديو',
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _CategoryCard(
                        icon: Icons.content_copy,
                        title: 'صور مكررة',
                        size: 'افتح للبحث',
                        onTap: widget.onOpenDuplicates,
                      ),
                      _CategoryCard(
                        icon: Icons.photo_library_outlined,
                        title: 'صور متشابهة',
                        size: 'قريبًا',
                        onTap: _soon,
                      ),
                      _CategoryCard(
                        icon: Icons.videocam_outlined,
                        title: 'فيديوهات مكررة',
                        size: 'قريبًا',
                        onTap: _soon,
                      ),
                      _CategoryCard(
                        icon: Icons.cleaning_services_outlined,
                        title: 'الكاش والملفات',
                        size: 'قريبًا',
                        onTap: _soon,
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

class _StorageSummary extends StatelessWidget {
  const _StorageSummary({required this.usedGb, required this.totalGb});

  final double usedGb;
  final double totalGb;

  @override
  Widget build(BuildContext context) {
    final ratio = usedGb / totalGb;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      value: ratio,
                      strokeWidth: 9,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${usedGb.round()} غيغابايت مستخدمة',
                    style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('من أصل ${totalGb.round()} غيغابايت',
                    style: textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String size;
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
                  Text(size, style: textTheme.titleSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DuplicatesScreen extends StatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> {
  bool _scanning = false;
  bool _scanned = false;
  String _status = '';
  double? _progress;
  List<List<AssetEntity>> _groups = [];
  final Set<String> _selected = {};
  final Map<String, int> _sizes = {};

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _fmt(int bytes) {
    if (bytes >= (1 << 30)) {
      return '${(bytes / (1 << 30)).toStringAsFixed(1)} غيغابايت';
    }
    if (bytes >= (1 << 20)) {
      return '${(bytes / (1 << 20)).toStringAsFixed(1)} ميغابايت';
    }
    return '${(bytes / 1024).round()} كيلوبايت';
  }

  int get _selectedBytes =>
      _selected.fold<int>(0, (sum, id) => sum + (_sizes[id] ?? 0));

  Future<void> _scan() async {
    if (_scanning) return;
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      _msg('نحتاج إذن الوصول إلى الصور');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _groups = [];
      _selected.clear();
      _sizes.clear();
      _progress = null;
      _status = 'جارٍ تحميل قائمة الصور…';
    });

    try {
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );
      final List<AssetEntity> assets;
      if (paths.isEmpty) {
        assets = [];
      } else {
        final count = await paths.first.assetCountAsync;
        assets = await paths.first.getAssetListRange(start: 0, end: count);
      }

      final bySize = <int, List<AssetEntity>>{};
      for (var i = 0; i < assets.length; i++) {
        final file = await assets[i].originFile;
        if (file != null) {
          final len = await file.length();
          _sizes[assets[i].id] = len;
          bySize.putIfAbsent(len, () => []).add(assets[i]);
        }
        if (i % 20 == 0 && mounted) {
          setState(() {
            _status = 'فحص الملفات ${i + 1} من ${assets.length}';
            _progress = (i + 1) / assets.length * 0.5;
          });
        }
      }

      final candidates = bySize.values.where((l) => l.length > 1).toList();
      final groups = <List<AssetEntity>>[];
      for (var i = 0; i < candidates.length; i++) {
        final byHash = <String, List<AssetEntity>>{};
        for (final a in candidates[i]) {
          final file = await a.originFile;
          if (file == null) continue;
          final digest = md5.convert(await file.readAsBytes()).toString();
          byHash.putIfAbsent(digest, () => []).add(a);
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
      setState(() => _selected.remove(asset.id));
      return;
    }
    final remaining = group
        .where((x) => x.id != asset.id && !_selected.contains(x.id))
        .length;
    if (remaining == 0) {
      _msg('احتفظ بصورة واحدة على الأقل في كل مجموعة');
      return;
    }
    setState(() => _selected.add(asset.id));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف الصور المحددة؟'),
        content: Text(
          'عدد الصور: ${_selected.length}\nسيطلب منك أندرويد تأكيد الحذف.',
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
      ),
    );
    if (ok != true) return;

    final deleted = await PhotoManager.editor.deleteWithIds(_selected.toList());
    if (!mounted) return;
    setState(() {
      _selected.removeAll(deleted);
      _groups = _groups
          .map((g) => g.where((a) => !deleted.contains(a.id)).toList())
          .where((g) => g.length > 1)
          .toList();
    });
    _msg('تم حذف ${deleted.length} ملف');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصور المكررة'), centerTitle: false),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
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
              Icon(Icons.content_copy, size: 56, color: scheme.primary),
              const SizedBox(height: 16),
              const Text(
                'ابحث عن الصور المتطابقة تمامًا ووفّر مساحة هاتفك.',
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
              Icon(Icons.check_circle_outline, size: 56, color: scheme.primary),
              const SizedBox(height: 16),
              const Text('لم نجد صورًا مكررة'),
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
                      Text('مجموعة ${i + 1} · ${g.length} صور',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: g
                            .map((a) => _Thumb(
                                  key: ValueKey(a.id),
                                  asset: a,
                                  selected: _selected.contains(a.id),
                                  onTap: () => _toggle(g, a),
                                ))
                            .toList(),
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
                'تم تحديد ${_selected.length} ملفات · توفير ${_fmt(_selectedBytes)}',
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

class _Thumb extends StatefulWidget {
  const _Thumb({
    super.key,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  late final Future<Uint8List?> _future =
      widget.asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);

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
            if (widget.selected)
              Positioned(
                top: 4,
                left: 4,
                child: Icon(Icons.check_circle, size: 20, color: scheme.error),
              )
            else
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
