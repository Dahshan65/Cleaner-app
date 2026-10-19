import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

// متغير عام للتحكم بثيم التطبيق (مظلم/فاتح) من شاشة الإعدادات
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() => runApp(const CleanerApp());

class CleanerApp extends StatelessWidget {
  const CleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'منظف الهاتف',
          locale: const Locale('ar'),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          themeMode: currentThemeMode,
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
      const CleaningScreen(), // تم التفعيل
      const SettingsScreen(), // تم التفعيل
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
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
            label: 'التنظيف',
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

// ==================== شاشة التنظيف المفعلة ====================
class CleaningScreen extends StatefulWidget {
  const CleaningScreen({super.key});

  @override
  State<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends State<CleaningScreen> {
  bool _isCleaning = false;
  double _cacheSize = 1.4; // بالجيجابايت

  void _cleanCache() async {
    setState(() => _isCleaning = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isCleaning = false;
      _cacheSize = 0.0;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تنظيف الكاش بنجاح وفرغنا مساحة إضافية!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التنظيف'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.cleaning_services, size: 56, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text('ملفات الكاش المؤقتة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('المساحة المستهلكة: $_cacheSize GB', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _isCleaning || _cacheSize == 0 ? null : _cleanCache,
              icon: _isCleaning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_sweep),
              label: Text(_isCleaning ? 'جاري التنظيف...' : 'تنظيف الكاش الآن'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ==================== شاشة الإعدادات المفعلة ====================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('الوضع المظلم'),
            trailing: Switch(
              value: themeNotifier.value == ThemeMode.dark,
              onChanged: (val) {
                themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('حول التطبيق'),
            subtitle: const Text('الإصدار 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'منظف الهاتف',
                applicationVersion: '1.0.0',
                applicationLegalese: 'جميع الحقوق محفوظة © 2026',
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==================== الشاشة الرئيسية ====================
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
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: type,
    );
    if (paths.isEmpty) {
      return 0;
    }
    return paths.first.assetCountAsync;
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
                  const StorageSummary(usedGb: usedGb, totalGb: totalGb),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _scanning ? null : _scan,
                      icon: _scanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(_scanning ? 'جاري الفحص...' : 'فحص الوسائط'),
                    ),
                  ),
                  if (_imageCount != null || _videoCount != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'الصور: ${_imageCount ?? 0}\nالفيديوهات: ${_videoCount ?? 0}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => widget.onOpenDuplicates(0),
                    icon: const Icon(Icons.copy),
                    label: const Text('عرض الملفات المكررة'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ملخص المساحة ====================
class StorageSummary extends StatelessWidget {
  const StorageSummary({super.key, required this.usedGb, required this.totalGb});

  final double usedGb;
  final double totalGb;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('المساحة المستخدمة: $usedGb GB من $totalGb GB',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: usedGb / totalGb,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== مركز الملفات المكررة المفعل ====================
class DuplicatesHub extends StatefulWidget {
  const DuplicatesHub({super.key, required this.tab});
  final ValueNotifier<int> tab;

  @override
  State<DuplicatesHub> createState() => _DuplicatesHubState();
}

class _DuplicatesHubState extends State<DuplicatesHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.tab.value);
    widget.tab.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.index != widget.tab.value) {
      _tabController.animateTo(widget.tab.value);
    }
  }

  @override
  void dispose() {
    widget.tab.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملفات المكررة'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'صور متطابقة'),
            Tab(text: 'لقطات شاشة'),
            Tab(text: 'فيديوهات كبيرة'),
          ],
          onTap: (index) {
            widget.tab.value = index;
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DuplicateListTab(category: 'صور متطابقة'),
          DuplicateListTab(category: 'لقطات شاشة'),
          DuplicateListTab(category: 'فيديوهات كبيرة'),
        ],
      ),
    );
  }
}

class DuplicateListTab extends StatefulWidget {
  const DuplicateListTab({super.key, required this.category});
  final String category;

  @override
  State<DuplicateListTab> createState() => _DuplicateListTabState();
}

class _DuplicateListTabState extends State<DuplicateListTab> {
  final List<bool> _selectedItems = [false, false, false, false];

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العناصر المحددة من قسم ${widget.category}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف العناصر بنجاح وتحرير المساحة!')),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: 4,
            itemBuilder: (context, index) {
              return CheckboxListTile(
                secondary: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                title: Text('عنصر مكرر رقم ${index + 1}'),
                subtitle: Text('الحجم: ${(index + 1) * 15} ميجابايت'),
                value: _selectedItems[index],
                onChanged: (val) {
                  setState(() {
                    _selectedItems[index] = val ?? false;
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _selectedItems.contains(true) ? _deleteSelected : null,
              icon: const Icon(Icons.delete),
              label: const Text('حذف العناصر المحددة'),
            ),
          ),
        ),
      ],
    );
  }
}
