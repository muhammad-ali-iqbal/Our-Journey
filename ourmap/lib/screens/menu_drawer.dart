import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../services/memory_service.dart';
import '../utils/app_theme.dart';
import 'add_memory_screen.dart';

class MenuDrawer extends StatelessWidget {
  final VoidCallback onClose;
  final void Function(Memory) onMemorySelected;

  const MenuDrawer({
    super.key,
    required this.onClose,
    required this.onMemorySelected,
  });

  void _close(BuildContext context) {
    Navigator.of(context).pop();
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Our Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'MEMORY LIST MENU',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _close(context),
                  child: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),

          // ── Nav Items ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Column(
              children: [
                // View Map (active)
                _NavItem(
                  icon: Icons.map_outlined,
                  label: 'View Map',
                  isActive: true,
                  onTap: () => _close(context),
                ),
                const SizedBox(height: 6),
                // Add New Memory
                _NavItem(
                  icon: Icons.add_location_outlined,
                  label: 'Add New Memory',
                  isActive: false,
                  onTap: () {
                    _close(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AddMemoryScreen(),
                    ));
                  },
                ),
                const SizedBox(height: 6),
                // Edit / Delete Memories
                _NavItem(
                  icon: Icons.edit_note_outlined,
                  label: 'Edit / Delete Memories',
                  isActive: false,
                  onTap: () {
                    // Show edit mode — handled by long press on list items below
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Long press any memory below to edit or delete it'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Recent Memories ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Text(
              'RECENT MEMORIES',
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Memory>>(
              stream: MemoryService().watchMemories(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No memories yet.\nAdd your first one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                final memories = snap.data!;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: memories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = memories[i];
                    return _MemoryListItem(
                      memory: m,
                      onTap: () => onMemorySelected(m),
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF1E293B),
                            title: const Text('Delete Memory',
                                style: TextStyle(color: Colors.white)),
                            content: Text(
                              'Delete "${m.title}"? This cannot be undone.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red.shade400)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await MemoryService().deleteMemory(m.id);
                        }
                      },
                      onEdit: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AddMemoryScreen(existingMemory: m),
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),

          // ── Footer profile ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
              color: AppColors.bgDark.withOpacity(0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Loving You',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Since Dec"22',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFFCBD5E1),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryListItem extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MemoryListItem({
    required this.memory,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1E293B),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  memory.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.edit, color: AppColors.primary),
                  title: const Text('Edit Memory',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  title: Text('Delete Memory',
                      style: TextStyle(color: Colors.red.shade400)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: memory.imagePaths.isNotEmpty
                        ? _buildThumb(memory.imagePaths.first)
                        : Container(
                            color: AppColors.bgDarkSurface,
                            child: Icon(Icons.favorite,
                                color: AppColors.gold.withOpacity(0.4),
                                size: 24),
                          ),
                  ),
                ),
                // Lock badge
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: memory.isUnlocked || memory.quiz == null
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(
                      memory.isUnlocked || memory.quiz == null
                          ? Icons.lock_open
                          : Icons.lock,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    memory.locationName,
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(memory.date).toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right,
                color: Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(String path) {
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                color: AppColors.bgDarkSurface,
              ));
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(color: AppColors.bgDarkSurface);
  }
}
