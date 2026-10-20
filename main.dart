import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.dark);

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

    if (!mounted) return;

    setState(() {
      _isBoosting = false;
      _ramUsage = 38.5;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('RAM Boosted Successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cleanCache() async {
    setState(() => _isCleaningCache = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isCleaningCache = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleaning simulation completed.'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _openHub(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CleanerHubScreen(initialTab: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CYBER CLEANER 🚀',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Color(0xFF00FF66),
          ),
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
                  colors: [
                    Color(0xFF151922),
                    Color(0xFF1E2330),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00FF66).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STORAGE & MEMORY STATUS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RAM: ${_ramUsage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Used: 94 GB / 128 GB',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _ramUsage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.black45,
                    color: _ramUsage > 70
                        ? Colors.redAccent
                        : const Color(0xFF00FF66),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF131822),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Smart Auto-Cleaner',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Auto-detect junk weekly in background',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                activeColor: const Color(0xFF00FF66),
                value: _autoCleanerEnabled,
                onChanged: (value) {
                  setState(() => _autoCleanerEnabled = value);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Auto-Cleaner Enabled'
                            : 'Auto-Cleaner Disabled',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '⚡ QUICK BOOST',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Screenshot Cleaner',
              subtitle: 'Scan screenshots',
              icon: Icons.camera,
              color: const Color(0xFF00FFCC),
              onTap: () => _openHub(0),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Large Files (>10MB)',
              subtitle: 'Find large media files',
              icon: Icons.sd_storage,
              color: const Color(0xFFFF3366),
              onTap: () => _openHub(1),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Duplicate Photos',
              subtitle: 'Find identical photos',
              icon: Icons.photo_library,
              color: const Color(0xFFFF9900),
              onTap: () => _openHub(2),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Duplicate Videos',
              subtitle: 'Find identical videos',
              icon: Icons.video_library,
              color: const Color(0xFF9900FF),
              onTap: () => _openHub(3),
            ),
            const SizedBox(height: 12),
            _buildCleanerCard(
              title: 'Recycle Bin (Trash)',
              subtitle: 'View items marked for deletion',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: color, width: 1.5),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
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
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: color,
        ),
        onTap: onTap,
      ),
    );
  }
}
