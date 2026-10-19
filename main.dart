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
          title: 'Phone Cleaner',
          locale: const Locale('en'),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: child!,
            );
          },
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              primary: const Color(0xFF6C63FF),
              secondary: const Color(0xFF00F5D4),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              primary: const Color(0xFF8A84FF),
              secondary: const Color(0xFF00F5D4),
              brightness: Brightness.dark,
            ),
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
    return '${(bytes / gb).toStringAsFixed(1)} GB';
  }
  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).round()} KB';
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
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_copy_outlined),
            selectedIcon: Icon(Icons.content_copy),
            label: 'Duplicates',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Large Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HomeScreen
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
            content: const Text('Permission needed to access media'),
            action: SnackBarAction(
              label: 'Settings',
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
        title: const Text('Phone Cleaner Pro', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _scan,
                      icon: _scanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bolt, size: 24),
                      label: Text(
                        _scanning ? 'Scanning Device...' : 'Scan Now',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.3,
                    children: [
                      CategoryCard(
                        icon: Icons.copy_all_rounded,
                        title: 'Duplicate Photos',
                        subtitle: 'Tap to clean',
                        color: const Color(0xFF6C63FF),
                        onTap: () => widget.onOpenDuplicates(0),
                      ),
                      CategoryCard(
                        icon: Icons.auto_awesome_mosaic_rounded,
                        title: 'Similar Photos',
                        subtitle: 'Smart clean',
                        color: const Color(0xFF00F5D4),
                        onTap: widget.onOpenSimilar,
                      ),
                      CategoryCard(
                        icon: Icons.video_collection_rounded,
                        title: 'Duplicate Videos',
                        subtitle: 'Tap to clean',
                        color: const Color(0xFFFF6584),
                        onTap: () => widget.onOpenDuplicates(1),
                      ),
                      CategoryCard(
                        icon: Icons.sd_storage_rounded,
                        title: 'Large Files',
                        subtitle: 'Free up space',
                        color: const Color(0xFFFFBE0B),
                        onTap: widget.onOpenLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Developer: Wael Dahshan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                  letterSpacing: 0.5,
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
    String usedText = 'Analyzing storage...';
    String detailText = '';

    if (known) {
      final usedMb = total - free;
      ratio = (usedMb / total).clamp(0.0, 1.0);
      percent = '${(ratio * 100).round()}%';
      usedText = '${formatBytes((usedMb * 1048576).round())} Used';
      detailText = '${formatBytes((free * 1048576).round())} Free of ${formatBytes((total * 1048576).round())}';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: known ? ratio : null,
                      strokeWidth: 8,
                      backgroundColor: scheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                  Text(percent, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usedText, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (detailText.isNotEmpty) const SizedBox(height: 6),
                  if (detailText.isNotEmpty)
                    Text(detailText, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
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
          Icon(icon, color: scheme.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            value == null ? '—' : '$value',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _stat(context, Icons.image, 'Photos', images),
                _stat(context, Icons.videocam, 'Videos', videos),
              ],
            ),
            if (images == null || videos == null) const SizedBox(height: 10),
            if (images == null || videos == null)
              Text(
                'Tap "Scan Now" to check media count',
                style: textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w500),
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
// DuplicatesHub
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
        title: const Text('Duplicates Cleaner', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: 'Photos'),
            Tab(text: 'Videos'),
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
      _msg('Permission needed');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _groups = [];
      _selected.clear();
      _sizes.clear();
      _progress = null;
      _status = 'Loading media list...';
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
            _status = 'Scanning files ${i + 1} of ${assets.length}';
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
            _status = 'Comparing content ${i + 1} of ${candidates.length}';
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
      _msg('Error during scanning');
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
      _msg('Keep at least one copy in each group');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete selected files?'),
          content: Text(
            'Files count: ${_selected.length}\nAndroid will prompt for confirmation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete'),
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
    _msg('${deleted.length} files deleted successfully');
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
              LinearProgressIndicator(value: _progress, borderRadius: BorderRadius.circular(10)),
              const SizedBox(height: 16),
              Text(_status, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                _isVideo ? Icons.video_collection_rounded : Icons.copy_all_rounded,
                size: 64,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _isVideo
                    ? 'Scan to find exact duplicate videos and reclaim your storage.'
                    : 'Scan to find exact duplicate photos and clean your device.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _scan,
                icon: const Icon(Icons.search),
                label: const Text('Start Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: Color(0xFF00F5D4),
              ),
              const SizedBox(height: 16),
              Text(_isVideo ? 'No duplicate videos found!' : 'No duplicate photos found!'),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _scan,
                child: const Text('Scan Again'),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group ${i + 1} · ${g.length} items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
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
            border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selected: ${_selected.length} items · Save ${formatBytes(_selectedBytes())}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _selected.isEmpty ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Selected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final radius = BorderRadius.circular(12);
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
                  color: widget.selected ? Colors.redAccent : scheme.primary,
                  width: 3,
                ),
                color: widget.selected ? Colors.redAccent.withValues(alpha: 0.3) : null,
              ),
            ),
            if (isVideo)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _durationText(),
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (widget.selected)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: Colors.redAccent,
                ),
              ),
            if (!widget.selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Keep',
                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
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
// SimilarImagesScreen
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
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      _msg('Permission needed');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _groups = [];
      _selected.clear();
      _sizes.clear();
      _progress = null;
      _status = 'Loading images...';
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
            _status = 'Analyzing images ${i + 1} of ${assets.length}';
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
      _msg('Error during scanning');
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
      _msg('Keep at least one photo in each group');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete selected photos?'),
          content: Text(
            'Photos count: ${_selected.length}\nAndroid will prompt for confirmation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete'),
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
    _msg('${deleted.length} photos deleted successfully');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    if (_scanning) {
      return Scaffold(
        appBar: AppBar(title: const Text('Similar Photos')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _progress, borderRadius: BorderRadius.circular(10)),
                const SizedBox(height: 16),
                Text(_status, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    if (!_scanned) {
      return Scaffold(
        appBar: AppBar(title: const Text('Similar Photos')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_mosaic_rounded,
                  size: 64,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan to find similar and burst shots taken around the same time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _scan,
                  icon: const Icon(Icons.search),
                  label: const Text('Start Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Similar Photos')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Color(0xFF00F5D4),
                ),
                const SizedBox(height: 16),
                const Text('No similar photos found!'),
                const SizedBox(height: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _scan,
                  child: const Text('Scan Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Similar Photos')),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Similar Group ${i + 1} · ${g.length} photos',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
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
              border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selected: ${_selected.length} photos · Save ${formatBytes(_selectedBytes())}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _selected.isEmpty ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Selected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
// LargeFilesScreen
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
      _msg('Permission needed');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = false;
      _items = [];
      _sizes.clear();
      _selected.clear();
      _progress = null;
      _status = 'Loading list...';
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
            _status = 'Scanning files ${i + 1} of ${assets.length}';
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
      _msg('Error during scan');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete selected files?'),
          content: Text(
            'Files: ${_selected.length}\nSize: ${formatBytes(_selectedBytes())}\nAndroid will prompt for confirmation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete'),
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
    _msg('${deleted.length} files deleted successfully');
  }

  Widget _typeSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: true,
            icon: Icon(Icons.videocam_rounded),
            label: Text('Videos'),
          ),
          ButtonSegment<bool>(
            value: false,
            icon: Icon(Icons.image_rounded),
            label: Text('Photos'),
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
              LinearProgressIndicator(value: _progress, borderRadius: BorderRadius.circular(10)),
              const SizedBox(height: 16),
              Text(_status, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              Icon(Icons.sd_storage_rounded, size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                _videos
                    ? 'Find and remove large videos taking up space.'
                    : 'Find and remove large photos taking up space.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _scan,
                icon: const Icon(Icons.search),
                label: const Text('Start Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: Color(0xFF00F5D4),
              ),
              const SizedBox(height: 16),
              const Text('No large files found!'),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _scan,
                child: const Text('Scan Again'),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: picked
                    ? Colors.redAccent.withValues(alpha: 0.15)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                          activeColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
            border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selected: ${_selected.length} files · Save ${formatBytes(_selectedBytes())}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _selected.isEmpty ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Selected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        title: const Text('Large Files', style: TextStyle(fontWeight: FontWeight.bold)),
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
            borderRadius: BorderRadius.circular(10),
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
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _durationText(),
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('App Theme', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary)),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: appThemeMode,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
