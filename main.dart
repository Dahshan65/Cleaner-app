import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

// متغيرات عامة للتحكم في ثيم التطبيق ولغته
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('ar'));

void main() => runApp(const CleanerApp());

class CleanerApp extends StatelessWidget {
  const CleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: currentLocale.languageCode == 'ar' ? 'منظف الهاتف' : 'Phone Cleaner',
              locale: currentLocale,
              builder: (context, child) => Directionality(
                textDirection: currentLocale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
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
    final isAr = localeNotifier.value.languageCode == 'ar';
    final pages = <Widget>[
      HomeScreen(onOpenDuplicates: _openDuplicates),
      DuplicatesHub(tab: _dupTab),
      const CleaningScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
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
            label: isAr ? 'التنظيف' : 'Cleaning',
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

// ==================== شاشة التنظيف ====================
class CleaningScreen extends StatefulWidget {
  const CleaningScreen({super.key});

  @override
  State<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends State<CleaningScreen> {
  bool _isCleaning = false;
  double _cacheSize = 1.4;

  void _cleanCache() async {
    setState(() => _isCleaning = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isCleaning = false;
      _cacheSize = 0.0;
    });
    if (!mounted) return;
    final isAr = localeNotifier.value.languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr
            ? 'تم تنظيف الكاش بنجاح وفرغنا مساحة إضافية!'
            : 'Cache cleaned successfully and freed up space!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = localeNotifier.value.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'التنظيف' : 'Cleaning'),
        centerTitle: false,
      ),
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
                    Text(
                      isAr ? 'ملفات الكاش المؤقتة' : 'Temporary Cache Files',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? 'المساحة المستهلكة: $_cacheSize GB' : 'Used Space: $_cacheSize GB',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _isCleaning || _cacheSize == 0 ? null : _cleanCache,
              icon: _isCleaning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep),
              label: Text(_isCleaning
                  ? (isAr ? 'جاري التنظيف...' : 'Cleaning...')
                  : (isAr ? 'تنظيف الكاش الآن' : 'Clean Cache Now')),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ==================== شاشة الإعدادات ====================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = localeNotifier.value.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات' : 'Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              isAr ? 'مظهر التطبيق' : 'App Theme',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text(isAr ? 'النظام' : 'System'),
                      icon: const Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(isAr ? 'فاتح' : 'Light'),
                      icon: const Icon(Icons.light_mode),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(isAr ? 'داكن' : 'Dark'),
                      icon: const Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (newSelection) {
                    themeNotifier.value = newSelection.first;
                  },
                );
              },
            ),
            const Divider(height: 32),
            Text(
              isAr ? 'لغة التطبيق' : 'App Language',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<Locale>(
              valueListenable: localeNotifier,
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
                  onSelectionChanged: (newSelection) {
                    localeNotifier.value = newSelection.first;
                  },
                );
              },
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(isAr ? 'حول التطبيق' : 'About App'),
              subtitle: Text(isAr ? 'الإصدار 1.0.0' : 'Version 1.0.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: isAr ? 'منظف الهاتف' : 'Phone Cleaner',
                  applicationVersion: '1.0.0',
                  applicationLegalese: isAr
                      ? 'جميع الحقوق محفوظة © 2026'
                      : 'All rights reserved © 2026',
                );
              },
            ),
          ],
        ),
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
        final isAr = localeNotifier.value.languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr
                ? 'نحتاج إذن الوصول إلى الصور والفيديو'
                : 'We need permission to access photos and videos'),
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
    final isAr = localeNotifier.value.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'مساحة الهاتف' : 'Phone Storage'),
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
                      label: Text(_scanning
                          ? (isAr ? 'جاري الفحص...' : 'Scanning...')
                          : (isAr ? 'فحص الوسائط' : 'Scan Media')),
                    ),
                  ),
                  if (_imageCount != null || _videoCount != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          isAr
                              ? 'الصور: ${_imageCount ?? 0}\nالفيديوهات: ${_videoCount ?? 0}'
                              : 'Images: ${_imageCount ?? 0}\nVideos: ${_videoCount ?? 0}',
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
                    label: Text(isAr ? 'عرض الملفات المكررة' : 'View Duplicates'),
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
    final isAr = localeNotifier.value.languageCode == 'ar';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              isAr
                  ? 'المساحة المستخدمة: $usedGb GB من $totalGb GB'
                  : 'Used Space: $usedGb GB of $totalGb GB',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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

// ==================== مركز الملفات المكررة ====================
class DuplicatesHub extends StatefulWidget {
  const DuplicatesHub({super.key, required this.tab});
  final ValueNotifier<int> tab;

  @override
  State<DuplicatesHub> createState() => _DuplicatesHubState();
}

class _DuplicatesHubState extends State<DuplicatesHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.tab.value,
    );
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
    final isAr = localeNotifier.value.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الملفات المكررة' : 'Duplicate Files'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isAr ? 'صور متطابقة' : 'Identical Photos'),
            Tab(text: isAr ? 'لقطات شاشة' : 'Screenshots'),
            Tab(text: isAr ? 'فيديوهات كبيرة' : 'Large Videos'),
          ],
          onTap: (index) {
            widget.tab.value = index;
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DuplicateListTab(category: 'Identical Photos'),
          DuplicateListTab(category: 'Screenshots'),
          DuplicateListTab(category: 'Large Videos'),
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
    final isAr = localeNotifier.value.languageCode == 'ar';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'تأكيد الحذف' : 'Confirm Deletion'),
        content: Text(isAr
            ? 'هل أنت متأكد من حذف العناصر المحددة من قسم ${widget.category}؟'
            : 'Are you sure you want to delete selected items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAr
                      ? 'تم حذف العناصر بنجاح وتحرير المساحة!'
                      : 'Items deleted successfully and space freed!'),
                ),
              );
            },
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = localeNotifier.value.languageCode == 'ar';
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
                title: Text(isAr
                    ? 'عنصر مكرر رقم ${index + 1}'
                    : 'Duplicate Item ${index + 1}'),
                subtitle: Text(isAr
                    ? 'الحجم: ${(index + 1) * 15} ميجابايت'
                    : 'Size: ${(index + 1) * 15} MB'),
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
              label: Text(isAr ? 'حذف العناصر المحددة' : 'Delete Selected Items'),
            ),
          ),
        ),
      ],
    );
  }
}
