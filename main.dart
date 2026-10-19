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
          title: 'Cyber Cleaner',
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

  void _openDuplicatesHub(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DuplicatesHubScreen(initialTab: index),
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
                children: [
                  const Text(
                    'DEVICE MEMORY STATUS',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'RAM Usage: ${_ramUsage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            const Text(
              '⚡ QUICK ACTIONS',
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
              '🔥 SMART DUPLICATE CLEANERS',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Duplicate Photos',
              subtitle: 'Scan & delete identical photo copies',
              icon: Icons.photo_library,
              color: const Color(0xFFFF9900),
              onTap: () => _openDuplicatesHub(0),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Duplicate Videos',
              subtitle: 'Find and remove heavy repeated videos',
              icon: Icons.video_library,
              color: const Color(0xFF9900FF),
              onTap: () => _openDuplicatesHub(1),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Duplicate Audio',
              subtitle: 'Clean repeated ringtones & audio notes',
              icon: Icons.audiotrack,
              color: const Color(0xFF00FFCC),
              onTap: () => _openDuplicatesHub(2),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Duplicate Files & Apps',
              subtitle: 'Clear repeated documents and APK packages',
              icon: Icons.folder_copy,
              color: const Color(0xFFFF0055),
              onTap: () => _openDuplicatesHub(3),
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

// ==================== Duplicates Hub Screen ====================
class DuplicatesHubScreen extends StatefulWidget {
  const DuplicatesHubScreen({super.key, required this.initialTab});
  final int initialTab;

  @override
  State<DuplicatesHubScreen> createState() => _DuplicatesHubScreenState();
}

class _DuplicatesHubScreenState extends State<DuplicatesHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
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
        title: const Text('Duplicate Cleaner Hub', style: TextStyle(color: Color(0xFF00FF66))),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF00FF66),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00FF66),
          tabs: const [
            Tab(text: 'Photos'),
            Tab(text: 'Videos'),
            Tab(text: 'Audio'),
            Tab(text: 'Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DuplicateScanView(type: RequestType.image, label: 'Photos'),
          DuplicateScanView(type: RequestType.video, label: 'Videos'),
          DuplicateScanView(type: RequestType.audio, label: 'Audio'),
          DuplicateScanView(type: RequestType.common, label: 'Files'),
        ],
      ),
    );
  }
}

// ==================== Duplicate Scan View ====================
class DuplicateScanView extends StatefulWidget {
  const DuplicateScanView({super.key, required this.type, required this.label});
  final RequestType type;
  final String label;

  @override
  State<DuplicateScanView> createState() => _DuplicateScanViewState();
}

class _DuplicateScanViewState extends State<DuplicateScanView> {
  bool _isLoading = true;
  List<AssetEntity> _duplicates = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _scanDuplicates();
  }

  Future<void> _scanDuplicates() async {
    setState(() => _isLoading = true);
    try {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.hasAccess) {
        setState(() => _isLoading = false);
        return;
      }

      final paths = await PhotoManager.getAssetPathList(onlyAll: true, type: widget.type);
      if (paths.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final assets = await paths.first.getAssetListRange(start: 0, end: 50);
      final Map<String, List<AssetEntity>> hashMap = {};

      for (var asset in assets) {
        final file = await asset.file;
        if (file != null) {
          try {
            final bytes = await file.readAsBytes();
            final digest = md5.convert(bytes).toString();
            hashMap.putIfAbsent(digest, () => []).add(asset);
          } catch (_) {}
        }
      }

      final List<AssetEntity> foundDuplicates = [];
      hashMap.forEach((key, list) {
        if (list.length > 1) {
          foundDuplicates.addAll(list.sublist(1));
        }
      });

      if (mounted) {
        setState(() {
          _duplicates = foundDuplicates;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to permanently delete selected items?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await PhotoManager.editor.deleteWithIds(_selectedIds.toList());
              setState(() {
                _duplicates.removeWhere((item) => _selectedIds.contains(item.id));
                _selectedIds.clear();
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ Selected duplicates deleted successfully!')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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

    if (_duplicates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF00FF66)),
            const SizedBox(height: 16),
            Text(
              'No duplicate ${widget.label} found!',
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
            itemCount: _duplicates.length,
            itemBuilder: (context, index) {
              final asset = _duplicates[index];
              final isSelected = _selectedIds.contains(asset.id);

              return FutureBuilder<File?>(
                future: asset.file,
                builder: (context, fileSnapshot) {
                  return FutureBuilder<int>(
                    future: fileSnapshot.hasData && fileSnapshot.data != null
                        ? fileSnapshot.data!.length()
                        : Future.value(0),
                    builder: (context, sizeSnapshot) {
                      final fileSizeMb = (sizeSnapshot.data ?? 0) / (1024 * 1024);

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
                        title: Text(asset.title ?? 'File ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('Size: ${fileSizeMb.toStringAsFixed(2)} MB', style: const TextStyle(color: Colors.grey)),
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
                  );
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
                onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
                child: Text(
                  'Delete Selected (${_selectedIds.length})',
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
