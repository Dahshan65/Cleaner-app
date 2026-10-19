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
  final ValueNotifier<int> _dupTab = ValueNotifier<int>(0);

  @override
  void dispose() {
    _dupTab.dispose();
    super.dispose();
  }

  void _openDuplicates(int tab) {
    _dupTab.value = tab;
    setState(() => _index = 1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onOpenDuplicates: _openDuplicates),
      DuplicatesHub(tab: _dupTab),
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

  final ValueChanged<int> onOpenDuplicates;

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
                        onTap: () => widget.onOpenDuplicates(0),
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
                        size: 'افتح للبحث',
                        onTap: () => widget.onOpenDuplicates(1),
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

class DuplicatesHub extends StatefulWidget {
  const DuplicatesHub({super.key, required this.tab});

  final ValueNotifier<int> tab;

  @override
  State<DuplicatesHub> createState() => _DuplicatesHubState();
}

class _DuplicatesHubState extends State<DuplicatesHub>
    with SingleTickerProviderStateMixin {
  late final TabController _controller =
      TabController(length: 2, vsync: this);

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

  bool get _isVideo => widget.type == RequestType.video;

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
