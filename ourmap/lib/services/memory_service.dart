import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory.dart';

class MemoryService {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal();

  final _rng = math.Random();
  SupabaseClient get _client => Supabase.instance.client;

  // ── One-shot fetch ──────────────────────────────────────────────────────────
  Future<List<Memory>> fetchMemories() async {
    final rows = await _client
        .from('memories')
        .select()
        .order('date', ascending: false);
    return (rows as List).map((r) => Memory.fromMap(r as Map<String, dynamic>)).toList();
  }

  // ── Real-time stream using polling fallback ─────────────────────────────────
  // Polls every 3 seconds so new memories appear without hot restart
  Stream<List<Memory>> watchMemories() async* {
    // Emit immediately
    yield await fetchMemories();
    // Then poll every 3 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      yield await fetchMemories();
    }
  }

  // ── Save a new memory ───────────────────────────────────────────────────────
  Future<Memory> saveMemory({
    required Memory memory,
    required List<File> localImages,
  }) async {
    final canvasX = memory.lng ?? (0.10 + _rng.nextDouble() * 0.80);
    final canvasY = memory.lat ?? (0.12 + _rng.nextDouble() * 0.76);

    final urls = <String>[];
    for (final file in localImages) {
      final ext = p.extension(file.path);
      final fileName = '${memory.id}/${DateTime.now().millisecondsSinceEpoch}$ext';
      await _client.storage.from('memories').upload(fileName, file);
      final url = _client.storage.from('memories').getPublicUrl(fileName);
      urls.add(url);
    }

    final withImages = memory.copyWith(
      imagePaths: urls,
      lat: canvasY,
      lng: canvasX,
    );

    await _client.from('memories').insert(withImages.toMap());
    return withImages;
  }

  // ── Update a memory ─────────────────────────────────────────────────────────
  Future<void> updateMemory(Memory memory) async {
    await _client
        .from('memories')
        .update(memory.toMap())
        .eq('id', memory.id);
  }

  // ── Unlock a memory ─────────────────────────────────────────────────────────
  Future<void> unlockMemory(String id) async {
    await _client.from('memories').update({'is_unlocked': true}).eq('id', id);
  }

  // ── Delete a memory ─────────────────────────────────────────────────────────
  Future<void> deleteMemory(String id) async {
    try {
      final files = await _client.storage.from('memories').list(path: id);
      final paths = files.map((f) => '$id/${f.name}').toList();
      if (paths.isNotEmpty) {
        await _client.storage.from('memories').remove(paths);
      }
    } catch (_) {}
    await _client.from('memories').delete().eq('id', id);
  }
}
