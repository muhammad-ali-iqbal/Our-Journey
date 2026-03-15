import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory.dart';

class MemoryService {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal();

  final _rng = math.Random();
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Memory>> fetchMemories() async {
    try {
      final rows = await _client
          .from('memories')
          .select()
          .order('date', ascending: false)
          .limit(500);
      if (rows == null) return [];
      return List<Map<String, dynamic>>.from(rows as List)
          .map(Memory.fromMap)
          .toList();
    } catch (e) {
      debugPrint('fetchMemories error: $e');
      return [];
    }
  }

  Stream<List<Memory>> watchMemories() async* {
    yield await fetchMemories();
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      yield await fetchMemories();
    }
  }

  Future<Memory> saveMemory({
    required Memory memory,
    required List<File> localImages,
    List<File> localVideos = const [],
  }) async {
    final canvasX = memory.lng ?? (0.10 + _rng.nextDouble() * 0.80);
    final canvasY = memory.lat ?? (0.12 + _rng.nextDouble() * 0.76);

    // Upload images
    final imageUrls = <String>[];
    for (final file in localImages) {
      final ext = p.extension(file.path);
      final fileName = '${memory.id}/img_${DateTime.now().millisecondsSinceEpoch}$ext';
      await _client.storage.from('memories').upload(fileName, file);
      imageUrls.add(_client.storage.from('memories').getPublicUrl(fileName));
    }

    // Upload videos
    final videoUrls = <String>[];
    for (final file in localVideos) {
      final ext = p.extension(file.path);
      final fileName = '${memory.id}/vid_${DateTime.now().millisecondsSinceEpoch}$ext';
      await _client.storage.from('memories').upload(
        fileName, file,
        fileOptions: const FileOptions(contentType: 'video/mp4'),
      );
      videoUrls.add(_client.storage.from('memories').getPublicUrl(fileName));
    }

    final withMedia = memory.copyWith(
      imagePaths: imageUrls,
      videoPaths: videoUrls,
      lat: canvasY,
      lng: canvasX,
    );

    await _client.from('memories').insert(withMedia.toMap());
    return withMedia;
  }

  Future<void> updateMemory(Memory memory) async {
    await _client.from('memories').update(memory.toMap()).eq('id', memory.id);
  }

  Future<void> unlockMemory(String id) async {
    await _client.from('memories').update({'is_unlocked': true}).eq('id', id);
  }

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
