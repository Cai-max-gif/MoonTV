import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/user_data_service.dart';
import '../utils/font_utils.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  bool _syncPlaybackProgress = true;
  bool _syncFavorites = true;
  bool _syncWatchHistory = true;
  bool _syncSettings = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final playbackProgress = await UserDataService.getSyncPlaybackProgress();
    final favorites = await UserDataService.getSyncFavorites();
    final watchHistory = await UserDataService.getSyncWatchHistory();
    final settings = await UserDataService.getSyncSettings();

    if (mounted) {
      setState(() {
        _syncPlaybackProgress = playbackProgress;
        _syncFavorites = favorites;
        _syncWatchHistory = watchHistory;
        _syncSettings = settings;
      });
    }
  }

  Future<void> _handleSyncNow() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '同步完成',
            style: FontUtils.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF000000) : const Color(0xFFf5f5f5),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '同步设置',
          style: FontUtils.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSyncPlaybackProgressCard(isDarkMode),
          const SizedBox(height: 12),
          _buildSyncFavoritesCard(isDarkMode),
          const SizedBox(height: 12),
          _buildSyncWatchHistoryCard(isDarkMode),
          const SizedBox(height: 12),
          _buildSyncSettingsCard(isDarkMode),
          const SizedBox(height: 16),
          _buildSyncNowButton(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSyncPlaybackProgressCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.play,
                size: 24,
                color: Color(0xFF3b82f6),
              ),
              const SizedBox(width: 12),
              Text(
                '播放进度同步',
                style: FontUtils.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          Switch(
            value: _syncPlaybackProgress,
            onChanged: (value) {
              setState(() {
                _syncPlaybackProgress = value;
              });
              UserDataService.saveSyncPlaybackProgress(value);
            },
            activeThumbColor: const Color(0xFF3b82f6),
            inactiveTrackColor:
                isDarkMode ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncFavoritesCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.star,
                size: 24,
                color: Color(0xFFf59e0b),
              ),
              const SizedBox(width: 12),
              Text(
                '收藏同步',
                style: FontUtils.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          Switch(
            value: _syncFavorites,
            onChanged: (value) {
              setState(() {
                _syncFavorites = value;
              });
              UserDataService.saveSyncFavorites(value);
            },
            activeThumbColor: const Color(0xFFf59e0b),
            inactiveTrackColor:
                isDarkMode ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncWatchHistoryCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.history,
                size: 24,
                color: Color(0xFF10b981),
              ),
              const SizedBox(width: 12),
              Text(
                '观看历史同步',
                style: FontUtils.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          Switch(
            value: _syncWatchHistory,
            onChanged: (value) {
              setState(() {
                _syncWatchHistory = value;
              });
              UserDataService.saveSyncWatchHistory(value);
            },
            activeThumbColor: const Color(0xFF10b981),
            inactiveTrackColor:
                isDarkMode ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSettingsCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.settings2,
                size: 24,
                color: Color(0xFF8b5cf6),
              ),
              const SizedBox(width: 12),
              Text(
                '设置同步',
                style: FontUtils.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          Switch(
            value: _syncSettings,
            onChanged: (value) {
              setState(() {
                _syncSettings = value;
              });
              UserDataService.saveSyncSettings(value);
            },
            activeThumbColor: const Color(0xFF8b5cf6),
            inactiveTrackColor:
                isDarkMode ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncNowButton(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.cloudUpload,
                size: 24,
                color: Color(0xFF27AE60),
              ),
              const SizedBox(width: 12),
              Text(
                '立即同步',
                style: FontUtils.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _handleSyncNow,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      LucideIcons.refreshCw,
                      size: 20,
                      color: Colors.white,
                    ),
              label: Text(
                _isSyncing ? '同步中...' : '立即同步',
                style: FontUtils.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                disabledBackgroundColor: const Color(0xFF27AE60).withAlpha(128),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
