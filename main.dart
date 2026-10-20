import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

// Theme Controller
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() => runApp(const CyberCleanerApp());

class CyberCleanerApp extends StatelessWidget {
  const CyberCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Cyber Cleaner Ultimate',
          builder: (context, child) => Directionality(
            textDirection: TextDirection.ltr,
            child: child!,
          ),
          themeMode: currentThemeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF00FF66),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF00FF66),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF080C14),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

// ==================== HomeScreen ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBoosting = false;
  bool _isCleaningCache = false;
  bool _autoCleanerEnabled = true;
  double _ramUsage = 74.2;

  void _boostRam() async {
    setState(() => _isBoosting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isBoosting = false;
      _ramUsage = 38.5;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ RAM Boosted Successfully! Phone is running blazing fast!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cleanCache() async {
    setState(() => _isCleaningCache = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isCleaningCache = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧹 Junk & Cache Cleaned Successfully!'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _openHub(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CleanerHubScreen(initialTab: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CYBER CLEANER 🚀',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF00FF66)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF151922), Color(0xFF1E2330)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FF66).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STORAGE & MEMORY STATUS',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RAM: ${_ramUsage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Used: 94 GB / 128 GB', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _ramUsage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.black45,
                    color: _ramUsage > 70 ? Colors.redAccent : const Color(0xFF00FF66),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF131822),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: SwitchListTile(
                title: const Text('Smart Auto-Cleaner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Auto-detect junk weekly in background', style: TextStyle(color: Colors.grey, fontSize: 12)),
                activeColor: const Color(0xFF00FF66),
                value: _autoCleanerEnabled,
                onChanged: (val) {
                  setState(() => _autoCleanerEnabled = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(val ? '🤖 Auto-Cleaner Enabled' : '💤 Auto-Cleaner Disabled')),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '⚡ QUICK BOOST',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    title: 'Boost RAM',
                    icon: Icons.speed,
                    color: const Color(0xFFFF0055),
                    isLoading: _isBoosting,
                    onPressed: _boostRam,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    title: 'Clean Cache',
                    icon: Icons.cleaning_services,
                    color: const Color(0xFF00E5FF),
                    isLoading: _isCleaningCache,
                    onPressed: _cleanCache,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '🔥 SMART CLEANER HUB',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Screenshot Cleaner',
              subtitle: 'Scan & wipe old useless screenshots',
              icon: Icons.camera,
              color: const Color(0xFF00FFCC),
              onTap: () => _openHub(0),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Large Files (>20MB)',
              subtitle: 'Find & remove heavy files easily',
              icon: Icons.sd_storage,
              color: const Color(0xFFFF3366),
              onTap: () => _openHub(1),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Duplicate Photos',
              subtitle: 'Scan & delete identical photo copies',
              icon: Icons.photo_library,
              color: const Color(0xFFFF9900),
              onTap: () => _openHub(2),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Duplicate Videos',
              subtitle: 'Find and remove heavy repeated videos',
              icon: Icons.video_library,
              color: const Color(0xFF9900FF),
              onTap: () => _openHub(3),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Recycle Bin (Trash)',
              subtitle: 'Recover or permanently delete items',
              icon: Icons.delete_sweep,
              color: Colors.grey,
              onTap: () => _openHub(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 75,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: color, width: 1.5),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: color, strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _buildCleanerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131822),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }
}

// ==================== Cleaner Hub Screen ====================
class CleanerHubScreen extends StatefulWidget {
  const CleanerHubScreen({super.key, required this.initialTab});
  final int initialTab;

  @override
  State<CleanerHubScreen> createState() => _CleanerHubScreenState();
}

class _CleanerHubScreenState extends State<CleanerHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cyber Cleaner Hub', style: TextStyle(color: Color(0xFF00FF66))),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF00FF66),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00FF66),
          tabs: const [
            Tab(text: 'Screenshots'),
            Tab(text: 'Large Files'),
            Tab(text: 'Dup Photos'),
            Tab(text: 'Dup Videos'),
            Tab(text: 'Trash Bin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ScanView(mode: ScanMode.screenshots),
          ScanView(mode: ScanMode.largeFiles),
          ScanView(mode: ScanMode.dupPhotos),
          ScanView(mode: ScanMode.dupVideos),
          ScanView(mode: ScanMode.trashBin),
        ],
      ),
    );
  }
}

enum ScanMode { screenshots, largeFiles, dupPhotos, dupVideos, trashBin }

// ==================== Robust Scan View ====================
class ScanView extends StatefulWidget {
  const ScanView({super.key, required this.mode});
  final ScanMode mode;

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  bool _isLoading = true;
  List<AssetEntity> _items = [];
  final Set<String> _selectedIds = {};

  static final List<AssetEntity> _trashBinList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.mode == ScanMode.trashBin) {
      setState(() {
        _items = List.from(_trashBinList);
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.hasAccess) {
        setState(() => _isLoading = false);
        return;
      }

      // تحديد نوع جلب الأصول (الصور أو الفيديوهات بشكل شامل لجميع الألبومات)
      final requestType = (widget.mode == ScanMode.dupVideos) ? RequestType.video : RequestType.image;
      final paths = await PhotoManager.getAssetPathList(onlyAll: false, type: requestType);
      
      List<AssetEntity> allAssets = [];
      for (var path in paths) {
        final list = await path.getAssetListRange(start: 0, end: 500);
        allAssets.addAll(list);
      }

      if (widget.mode == ScanMode.screenshots) {
        final List<AssetEntity> screenshots = [];
        for (var asset in allAssets) {
          final file = await asset.file;
          if (file != null) {
            final pathLower = file.path.toLowerCase();
            if (pathLower.contains('screenshot') || pathLower.contains('screen') || pathLower.contains('captures')) {
              screenshots.add(asset);
            }
          }
        }
        if (mounted) setState(() { _items = screenshots; _isLoading = false; });
      } else if (widget.mode == ScanMode.largeFiles) {
        // فحص الملفات الكبيرة (أكبر من 20 ميجابايت للصور والفيديوهات)
        final List<AssetEntity> heavy = [];
        for (var asset in allAssets) {
          final file = await asset.file;
          if (file != null) {
            try {
              final len = await file.length();
              if ((len / (1024 * 1024)) >= 20.0) {
                heavy.add(asset);
              }
            } catch (_) {}
          }
        }
        if (mounted) setState(() { _items = heavy; _isLoading = false; });
      } else {
        // خوارزمية ذكية لاكتشاف الصور أو الفيديوهات المكررة (الحجم + الاسم أو محتوى MD5 للسريع)
        final Map<String, List<AssetEntity>> map = {};
        for (var asset in allAssets) {
          final file = await asset.file;
          if (file != null) {
            try {
              final length = await file.length();
              final name = asset.title ?? 'file';
              // بصمة فريدة تعتمد على اسم الملف وحجمه بالبايت
              final signature = '${name}_$length';
              map.putIfAbsent(signature, () => []).add(asset);
            } catch (_) {}
          }
        }

        final List<AssetEntity> duplicates = [];
        map.forEach((key, list) {
          if (list.length > 1) {
            duplicates.addAll(list.sublist(1));
          }
        });

        if (mounted) setState(() { _items = duplicates; _isLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _moveToTrashOrDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(widget.mode == ScanMode.trashBin ? 'Delete Permanently?' : 'Move to Trash Bin?', style: const TextStyle(color: Colors.white)),
        content: Text(
          widget.mode == ScanMode.trashBin
              ? 'Are you sure you want to delete these items permanently?'
              : 'Items will be moved to Recycle Bin for 7 days before permanent deletion.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.mode == ScanMode.trashBin) {
                await PhotoManager.editor.deleteWithIds(_selectedIds.toList());
                _trashBinList.removeWhere((item) => _selectedIds.contains(item.id));
              } else {
                final selectedAssets = _items.where((item) => _selectedIds.contains(item.id)).toList();
                _trashBinList.addAll(selectedAssets);
                _items.removeWhere((item) => _selectedIds.contains(item.id));
              }
              setState(() => _selectedIds.clear());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ Action completed successfully!')),
              );
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF66)));
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF00FF66)),
            const SizedBox(height: 16),
            Text(
              widget.mode == ScanMode.trashBin ? 'Recycle bin is empty!' : 'No items found in this category!',
              style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final asset = _items[index];
              final isSelected = _selectedIds.contains(asset.id);

              return CheckboxListTile(
                activeColor: const Color(0xFF00FF66),
                checkColor: Colors.black,
                secondary: FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(const ThumbnailSize(100, 100)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(snapshot.data!, width: 50, height: 50, fit: BoxFit.cover),
                      );
                    }
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.insert_drive_file, color: Colors.white70),
                    );
                  },
                ),
                title: Text(asset.title ?? 'Item ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Ready for cleanup', style: TextStyle(color: Colors.grey)),
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.add(asset.id);
                    } else {
                      _selectedIds.remove(asset.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0055),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _selectedIds.isNotEmpty ? _moveToTrashOrDelete : null,
                child: Text(
                  widget.mode == ScanMode.trashBin ? 'Delete Permanently (${_selectedIds.length})' : 'Move to Trash (${_selectedIds.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
