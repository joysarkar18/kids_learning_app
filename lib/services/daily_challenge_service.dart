import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/challenge_progress_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/daily_challenge_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/daily_mission_model.dart';
import 'package:kids_learning/services/auth_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyChallengeService extends ChangeNotifier {
  static final DailyChallengeService _instance =
      DailyChallengeService._internal();
  factory DailyChallengeService() => _instance;
  DailyChallengeService._internal();

  static DailyChallengeService get instance => _instance;

  static const _prefKeyChallenge = 'daily_challenge';
  static const _prefKeyProgress = 'challenge_progress';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for mission completion events (emits mission title)
  final StreamController<String> _missionCompleteController =
      StreamController<String>.broadcast();
  Stream<String> get onMissionCompleted => _missionCompleteController.stream;

  DailyChallenge? _todayChallenge;
  ChallengeProgress _progress = const ChallengeProgress();

  DailyChallenge? get todayChallenge => _todayChallenge;
  ChallengeProgress get progress => _progress;
  
  /// Get completed dates for calendar display
  List<String> get completedDates => List.unmodifiable(_progress.completedDates);

  // Pending launch indices — set before navigation, consumed by wrappers.
  // This bypasses GoRouter's extra param which can be unreliable.
  final Map<String, int> _pendingStartIndices = {};

  /// Call before navigating to a module from Daily Challenge.
  /// Stores the resume index so the wrapper can pick it up.
  void prepareLaunch(String moduleKey) {
    LoggerService.logInfo('prepareLaunch($moduleKey) called');
    final idx = getResumeIndex(moduleKey);
    if (idx != null) {
      _pendingStartIndices[moduleKey] = idx;
      LoggerService.logInfo('prepareLaunch($moduleKey) → stored index=$idx');
    } else {
      LoggerService.logWarning(
        'prepareLaunch($moduleKey) → getResumeIndex returned NULL',
      );
    }
  }

  /// Called by module wrappers to get (and clear) the pending start index.
  /// Returns null when navigating from home screen (no pending index).
  int? consumeStartIndex(String moduleKey) {
    final idx = _pendingStartIndices.remove(moduleKey);
    LoggerService.logInfo(
      'consumeStartIndex($moduleKey) → ${idx ?? "NULL (from home screen)"}',
    );
    return idx;
  }

  // Module list sizes for index-based modules
  static const _moduleListSizes = {
    'bornomala': 51,
    'alphabate': 26,
    'bangla_sonkha': 100,
    'english_sonkha': 100,
  };

  // ─── Mission Pool (24 missions: 3 variants per module) ───────────
  static final List<DailyMission> _missionPool = [
    // Bornomala (Bengali letters)
    DailyMission(
      id: 'practice_bengali_2',
      moduleKey: 'bornomala',
      titleEn: 'Practice 2 Bengali letters',
      titleBn: '২টি বাংলা অক্ষর অনুশীলন করো',
      targetCount: 2,
    ),
    DailyMission(
      id: 'practice_bengali_5',
      moduleKey: 'bornomala',
      titleEn: 'Practice 5 Bengali letters',
      titleBn: '৫টি বাংলা অক্ষর অনুশীলন করো',
      targetCount: 5,
    ),
    DailyMission(
      id: 'practice_bengali_8',
      moduleKey: 'bornomala',
      titleEn: 'Practice 8 Bengali letters',
      titleBn: '৮টি বাংলা অক্ষর অনুশীলন করো',
      targetCount: 8,
    ),

    // Alphabate (English letters)
    DailyMission(
      id: 'practice_english_2',
      moduleKey: 'alphabate',
      titleEn: 'Practice 2 English letters',
      titleBn: '২টি ইংরেজি অক্ষর অনুশীলন করো',
      targetCount: 2,
    ),
    DailyMission(
      id: 'practice_english_5',
      moduleKey: 'alphabate',
      titleEn: 'Practice 5 English letters',
      titleBn: '৫টি ইংরেজি অক্ষর অনুশীলন করো',
      targetCount: 5,
    ),
    DailyMission(
      id: 'practice_english_8',
      moduleKey: 'alphabate',
      titleEn: 'Practice 8 English letters',
      titleBn: '৮টি ইংরেজি অক্ষর অনুশীলন করো',
      targetCount: 8,
    ),

    // Sothik Uttor (GK questions)
    DailyMission(
      id: 'answer_gk_1',
      moduleKey: 'sothik_uttor',
      titleEn: 'Answer 1 GK question',
      titleBn: '১টি সাধারণ জ্ঞানের প্রশ্নের উত্তর দাও',
      targetCount: 1,
    ),
    DailyMission(
      id: 'answer_gk_3',
      moduleKey: 'sothik_uttor',
      titleEn: 'Answer 3 GK questions',
      titleBn: '৩টি সাধারণ জ্ঞানের প্রশ্নের উত্তর দাও',
      targetCount: 3,
    ),
    DailyMission(
      id: 'answer_gk_5',
      moduleKey: 'sothik_uttor',
      titleEn: 'Answer 5 GK questions',
      titleBn: '৫টি সাধারণ জ্ঞানের প্রশ্নের উত্তর দাও',
      targetCount: 5,
    ),

    // Gonit (Math problems)
    DailyMission(
      id: 'solve_math_1',
      moduleKey: 'gonit',
      titleEn: 'Solve 1 math problem',
      titleBn: '১টি গণিতের সমস্যা সমাধান করো',
      targetCount: 1,
    ),
    DailyMission(
      id: 'solve_math_3',
      moduleKey: 'gonit',
      titleEn: 'Solve 3 math problems',
      titleBn: '৩টি গণিতের সমস্যা সমাধান করো',
      targetCount: 3,
    ),
    DailyMission(
      id: 'solve_math_5',
      moduleKey: 'gonit',
      titleEn: 'Solve 5 math problems',
      titleBn: '৫টি গণিতের সমস্যা সমাধান করো',
      targetCount: 5,
    ),

    // Bangla Sonkha (Bengali numbers)
    DailyMission(
      id: 'count_bengali_3',
      moduleKey: 'bangla_sonkha',
      titleEn: 'Count 3 Bengali numbers',
      titleBn: '৩টি বাংলা সংখ্যা গোনো',
      targetCount: 3,
    ),
    DailyMission(
      id: 'count_bengali_5',
      moduleKey: 'bangla_sonkha',
      titleEn: 'Count 5 Bengali numbers',
      titleBn: '৫টি বাংলা সংখ্যা গোনো',
      targetCount: 5,
    ),
    DailyMission(
      id: 'count_bengali_8',
      moduleKey: 'bangla_sonkha',
      titleEn: 'Count 8 Bengali numbers',
      titleBn: '৮টি বাংলা সংখ্যা গোনো',
      targetCount: 8,
    ),

    // English Sonkha (English numbers)
    DailyMission(
      id: 'count_english_3',
      moduleKey: 'english_sonkha',
      titleEn: 'Count 3 English numbers',
      titleBn: '৩টি ইংরেজি সংখ্যা গোনো',
      targetCount: 3,
    ),
    DailyMission(
      id: 'count_english_5',
      moduleKey: 'english_sonkha',
      titleEn: 'Count 5 English numbers',
      titleBn: '৫টি ইংরেজি সংখ্যা গোনো',
      targetCount: 5,
    ),
    DailyMission(
      id: 'count_english_8',
      moduleKey: 'english_sonkha',
      titleEn: 'Count 8 English numbers',
      titleBn: '৮টি ইংরেজি সংখ্যা গোনো',
      targetCount: 8,
    ),

    // Drawing
    DailyMission(
      id: 'color_drawing_1',
      moduleKey: 'drawing',
      titleEn: 'Color 1 drawing',
      titleBn: '১টি ছবি রং করো',
      targetCount: 1,
    ),
    DailyMission(
      id: 'color_drawing_2',
      moduleKey: 'drawing',
      titleEn: 'Color 2 drawings',
      titleBn: '২টি ছবি রং করো',
      targetCount: 2,
    ),
    DailyMission(
      id: 'color_drawing_3',
      moduleKey: 'drawing',
      titleEn: 'Color 3 drawings',
      titleBn: '৩টি ছবি রং করো',
      targetCount: 3,
    ),

    // Namota (Multiplication tables)
    DailyMission(
      id: 'practice_namota_1',
      moduleKey: 'namota',
      titleEn: 'Practice 1 multiplication table',
      titleBn: '১টি নামতা অনুশীলন করো',
      targetCount: 1,
    ),
    DailyMission(
      id: 'practice_namota_3',
      moduleKey: 'namota',
      titleEn: 'Practice 3 multiplication tables',
      titleBn: '৩টি নামতা অনুশীলন করো',
      targetCount: 3,
    ),
    DailyMission(
      id: 'practice_namota_5',
      moduleKey: 'namota',
      titleEn: 'Practice 5 multiplication tables',
      titleBn: '৫টি নামতা অনুশীলন করো',
      targetCount: 5,
    ),

    // Banan (Word spelling)
    DailyMission(
      id: 'spell_banan_1',
      moduleKey: 'banan',
      titleEn: 'Spell 1 word',
      titleBn: '১টি শব্দ বানানো শেখো',
      targetCount: 1,
    ),
    DailyMission(
      id: 'spell_banan_3',
      moduleKey: 'banan',
      titleEn: 'Spell 3 words',
      titleBn: '৩টি শব্দ বানানো শেখো',
      targetCount: 3,
    ),
    DailyMission(
      id: 'spell_banan_5',
      moduleKey: 'banan',
      titleEn: 'Spell 5 words',
      titleBn: '৫টি শব্দ বানানো শেখো',
      targetCount: 5,
    ),

    // Chora (Nursery rhymes)
    DailyMission(
      id: 'watch_chora_1',
      moduleKey: 'chora',
      titleEn: 'Watch 1 nursery rhyme',
      titleBn: '১টি ছড়ার ভিডিও দেখো',
      targetCount: 1,
    ),
    DailyMission(
      id: 'watch_chora_2',
      moduleKey: 'chora',
      titleEn: 'Watch 2 nursery rhymes',
      titleBn: '২টি ছড়ার ভিডিও দেখো',
      targetCount: 2,
    ),
    DailyMission(
      id: 'watch_chora_3',
      moduleKey: 'chora',
      titleEn: 'Watch 3 nursery rhymes',
      titleBn: '৩টি ছড়ার ভিডিও দেখো',
      targetCount: 3,
    ),
  ];

  // ─── Initialization ────────────────────────────────────────────────
  Future<void> initialize() async {
    LoggerService.logInfo('DailyChallengeService.initialize() started');
    await _loadFromLocal();
    LoggerService.logInfo(
      'After _loadFromLocal: challenge=${_todayChallenge?.date}, stars=${_progress.totalStars}',
    );

    // If no local data (e.g. after uninstall), restore from Firestore
    if (_todayChallenge == null && _progress.totalStars == 0) {
      LoggerService.logInfo('No local data found, restoring from Firestore...');
      await _restoreFromFirestore();
    }

    final today = _todayString();

    if (_todayChallenge == null || _todayChallenge!.date != today) {
      LoggerService.logInfo('Generating new challenge for $today');
      _todayChallenge = _generateChallenge(today);
      _updateStreakOnNewDay(today);
      await _saveToLocal();
    }

    LoggerService.logInfo(
      'initialize() done: ${_todayChallenge!.missions.length} missions → ${_todayChallenge!.missions.map((m) => "${m.moduleKey}(${m.currentCount}/${m.targetCount})").toList()}',
    );
    notifyListeners();
  }

  // ─── Mission Generation (deterministic by date, 5 unique modules) ─
  DailyChallenge _generateChallenge(String date) {
    final seed = date.hashCode;
    final rng = Random(seed);
    final shuffled = List<DailyMission>.from(_missionPool)..shuffle(rng);

    // Pick 5 missions, no duplicate moduleKeys
    final picked = <DailyMission>[];
    final usedModules = <String>{};
    for (final m in shuffled) {
      if (!usedModules.contains(m.moduleKey)) {
        picked.add(m.copyWith(currentCount: 0));
        usedModules.add(m.moduleKey);
        if (picked.length >= 5) break;
      }
    }

    return DailyChallenge(date: date, missions: picked);
  }

  // ─── Resume Index (persisted per-mission, continues from last position) ─
  int? getResumeIndex(String moduleKey) {
    if (_todayChallenge == null) {
      LoggerService.logWarning(
        'getResumeIndex($moduleKey): _todayChallenge is NULL',
      );
      return null;
    }
    final listSize = _moduleListSizes[moduleKey];
    if (listSize == null) {
      LoggerService.logInfo(
        'getResumeIndex($moduleKey): not an index-based module, skipping',
      );
      return null;
    }

    LoggerService.logInfo(
      'getResumeIndex($moduleKey): today has ${_todayChallenge!.missions.length} missions: ${_todayChallenge!.missions.map((m) => m.moduleKey).toList()}',
    );

    final mission = _todayChallenge!.missions
        .where((m) => m.moduleKey == moduleKey)
        .firstOrNull;
    if (mission == null) {
      LoggerService.logWarning(
        'getResumeIndex($moduleKey): NO mission found for this module in today\'s challenge',
      );
      return null;
    }
    if (mission.isCompleted) {
      LoggerService.logInfo(
        'getResumeIndex($moduleKey): mission already completed (${mission.currentCount}/${mission.targetCount})',
      );
      return null;
    }

    LoggerService.logInfo(
      'getResumeIndex($moduleKey): mission found → id=${mission.id}, count=${mission.currentCount}/${mission.targetCount}, startingIndex=${mission.startingIndex}',
    );

    // First access: assign a random starting index and persist it
    if (mission.startingIndex == null) {
      final rng = Random();
      final startIdx = rng.nextInt(listSize);
      LoggerService.logInfo(
        'getResumeIndex($moduleKey): FIRST ACCESS → random startIdx=$startIdx (listSize=$listSize)',
      );
      final updatedMissions = _todayChallenge!.missions.map((m) {
        if (m.id == mission.id) return m.copyWith(startingIndex: startIdx);
        return m;
      }).toList();
      _todayChallenge = _todayChallenge!.copyWith(missions: updatedMissions);
      _saveToLocal();
      return startIdx;
    }

    // Subsequent access: resume from startingIndex + currentCount
    final resumeIdx =
        (mission.startingIndex! + mission.currentCount) % listSize;
    LoggerService.logInfo(
      'getResumeIndex($moduleKey): RESUME → startingIndex=${mission.startingIndex} + count=${mission.currentCount} = index=$resumeIdx',
    );
    return resumeIdx;
  }

  // ─── Report Progress from Modules (immutable updates) ─────────────
  Future<void> reportProgress(String moduleKey) async {
    if (_todayChallenge == null) return;

    bool updated = false;
    String? completedMissionTitle;
    final updatedMissions = _todayChallenge!.missions.map((mission) {
      if (mission.moduleKey == moduleKey && !mission.isCompleted && !updated) {
        updated = true;
        final newCount = mission.currentCount + 1;
        final updatedMission = mission.copyWith(currentCount: newCount);
        // Check if this specific mission just completed
        if (updatedMission.isCompleted) {
          completedMissionTitle = mission.titleEn;
        }
        return updatedMission;
      }
      return mission;
    }).toList();

    if (!updated) return;

    _todayChallenge = _todayChallenge!.copyWith(missions: updatedMissions);

    // Emit mission completion event
    if (completedMissionTitle != null) {
      _missionCompleteController.add(completedMissionTitle!);
    }

    // Check if all missions just completed
    if (_todayChallenge!.isAllCompleted) {
      final today = _todayString();
      if (_progress.lastCompletedDate != today) {
        // Add today to completed dates if not already present
        final updatedCompletedDates = List<String>.from(_progress.completedDates);
        if (!updatedCompletedDates.contains(today)) {
          updatedCompletedDates.add(today);
        }
        
        _progress = _progress.copyWith(
          totalStars: _progress.totalStars + _todayChallenge!.starsEarned,
          currentStreak: _progress.currentStreak + 1,
          longestStreak: max(
            _progress.longestStreak,
            _progress.currentStreak + 1,
          ),
          lastCompletedDate: today,
          completedDates: updatedCompletedDates,
        );
      }
    }

    await _saveToLocal();
    _syncToFirestore();
    notifyListeners();
  }

  // ─── Streak Logic ──────────────────────────────────────────────────
  void _updateStreakOnNewDay(String today) {
    if (_progress.lastCompletedDate.isEmpty) return;

    final lastDate = DateTime.tryParse(_progress.lastCompletedDate);
    final todayDate = DateTime.tryParse(today);
    if (lastDate == null || todayDate == null) return;

    final diff = todayDate.difference(lastDate).inDays;
    if (diff > 1) {
      // Streak broken — reset
      _progress = _progress.copyWith(currentStreak: 0);
    }
    // If diff == 1, streak continues (will be incremented on completion)
    // If diff == 0, same day — no change
    
    // Clean up old completed dates (keep last 90 days for calendar)
    final ninetyDaysAgo = todayDate.subtract(const Duration(days: 90));
    final filteredDates = _progress.completedDates
        .where((date) {
          final d = DateTime.tryParse(date);
          return d != null && d.isAfter(ninetyDaysAgo);
        })
        .toList();
    
    if (filteredDates.length != _progress.completedDates.length) {
      _progress = _progress.copyWith(completedDates: filteredDates);
    }
  }

  // ─── Local Persistence (SharedPreferences) ─────────────────────────
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final challengeJson = prefs.getString(_prefKeyChallenge);
      if (challengeJson != null) {
        _todayChallenge = DailyChallenge.fromMap(
          jsonDecode(challengeJson) as Map<String, dynamic>,
        );
      }

      final progressJson = prefs.getString(_prefKeyProgress);
      if (progressJson != null) {
        _progress = ChallengeProgress.fromMap(
          jsonDecode(progressJson) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      LoggerService.logError('Error loading daily challenge: $e');
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_todayChallenge != null) {
        await prefs.setString(
          _prefKeyChallenge,
          jsonEncode(_todayChallenge!.toMap()),
        );
      }
      await prefs.setString(_prefKeyProgress, jsonEncode(_progress.toMap()));
    } catch (e) {
      LoggerService.logError('Error saving daily challenge: $e');
    }
  }

  // ─── Firestore Restore (after uninstall / new device) ───────────────
  Future<void> _restoreFromFirestore() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      final userRef = _firestore.collection('users').doc(user.uid);

      // 1. Restore user-level stats (stars, streak)
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _progress = ChallengeProgress(
          totalStars: data['totalStars'] ?? 0,
          currentStreak: data['currentStreak'] ?? 0,
          longestStreak: data['longestStreak'] ?? 0,
          lastCompletedDate: data['lastCompletedDate'] ?? '',
        );
        LoggerService.logInfo(
          'Restored stats from Firestore: stars=${_progress.totalStars}, streak=${_progress.currentStreak}',
        );
      }

      // 2. Restore today's challenge progress if it exists
      final today = _todayString();
      final todayDoc = await userRef
          .collection('daily_progress')
          .doc(today)
          .get();
      if (todayDoc.exists) {
        final data = todayDoc.data()!;
        // Only restore if it has missions data
        if (data['missions'] != null) {
          _todayChallenge = DailyChallenge.fromMap(data);
          LoggerService.logInfo('Restored today\'s challenge from Firestore');
        }
      }

      // Persist restored data locally
      await _saveToLocal();
    } catch (e) {
      LoggerService.logError('Firestore restore failed (offline?): $e');
    }
  }

  // ─── Firestore Sync ────────────────────────────────────────────────
  Future<void> _syncToFirestore() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null || _todayChallenge == null) return;

      final userRef = _firestore.collection('users').doc(user.uid);

      // Build enhanced daily progress data
      final challengeData = _todayChallenge!.toMap();
      challengeData['completedAt'] = _todayChallenge!.isAllCompleted
          ? FieldValue.serverTimestamp()
          : null;
      challengeData['completedMissions'] = _todayChallenge!.missions
          .where((m) => m.isCompleted)
          .map(
            (m) => {
              'id': m.id,
              'moduleKey': m.moduleKey,
              'targetCount': m.targetCount,
              'completedAt': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      // Save today's challenge progress with completion data
      await userRef
          .collection('daily_progress')
          .doc(_todayChallenge!.date)
          .set(challengeData, SetOptions(merge: true));

      // Update user-level stats (including lastCompletedDate for restore)
      await userRef.set({
        'totalStars': _progress.totalStars,
        'currentStreak': _progress.currentStreak,
        'longestStreak': _progress.longestStreak,
        'lastCompletedDate': _progress.lastCompletedDate,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      LoggerService.logError('Error syncing daily challenge: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────
  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
