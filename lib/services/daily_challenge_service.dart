import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/challenge_progress_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/daily_challenge_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/daily_mission_model.dart';
import 'package:kids_learning/services/auth_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyChallengeService {
  static final DailyChallengeService _instance =
      DailyChallengeService._internal();
  factory DailyChallengeService() => _instance;
  DailyChallengeService._internal();

  static DailyChallengeService get instance => _instance;

  static const _prefKeyChallenge = 'daily_challenge';
  static const _prefKeyProgress = 'challenge_progress';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DailyChallenge? _todayChallenge;
  ChallengeProgress _progress = const ChallengeProgress();

  DailyChallenge? get todayChallenge => _todayChallenge;
  ChallengeProgress get progress => _progress;

  // ─── Mission Pool ──────────────────────────────────────────────────
  static final List<DailyMission> _missionPool = [
    DailyMission(
      id: 'practice_bengali_3',
      moduleKey: 'bornomala',
      titleEn: 'Practice 3 Bengali letters',
      titleBn: '৩টি বাংলা অক্ষর অনুশীলন করো',
      targetCount: 3,
    ),
    DailyMission(
      id: 'practice_english_3',
      moduleKey: 'alphabate',
      titleEn: 'Practice 3 English letters',
      titleBn: '৩টি ইংরেজি অক্ষর অনুশীলন করো',
      targetCount: 3,
    ),
    DailyMission(
      id: 'answer_gk_2',
      moduleKey: 'sothik_uttor',
      titleEn: 'Answer 2 GK questions',
      titleBn: '২টি সাধারণ জ্ঞানের প্রশ্নের উত্তর দাও',
      targetCount: 2,
    ),
    DailyMission(
      id: 'solve_math_2',
      moduleKey: 'gonit',
      titleEn: 'Solve 2 math problems',
      titleBn: '২টি গণিতের সমস্যা সমাধান করো',
      targetCount: 2,
    ),
    DailyMission(
      id: 'count_bengali_5',
      moduleKey: 'bangla_sonkha',
      titleEn: 'Count 5 Bengali numbers',
      titleBn: '৫টি বাংলা সংখ্যা গোনো',
      targetCount: 5,
    ),
    DailyMission(
      id: 'count_english_5',
      moduleKey: 'english_sonkha',
      titleEn: 'Count 5 English numbers',
      titleBn: '৫টি ইংরেজি সংখ্যা গোনো',
      targetCount: 5,
    ),
    DailyMission(
      id: 'color_drawing_1',
      moduleKey: 'drawing',
      titleEn: 'Color 1 drawing',
      titleBn: '১টি ছবি রং করো',
      targetCount: 1,
    ),
    DailyMission(
      id: 'practice_namota_1',
      moduleKey: 'namota',
      titleEn: 'Practice 1 multiplication table',
      titleBn: '১টি নামতা অনুশীলন করো',
      targetCount: 1,
    ),
  ];

  // ─── Initialization ────────────────────────────────────────────────
  Future<void> initialize() async {
    await _loadFromLocal();
    final today = _todayString();

    if (_todayChallenge == null || _todayChallenge!.date != today) {
      _todayChallenge = _generateChallenge(today);
      _updateStreakOnNewDay(today);
      await _saveToLocal();
    }
  }

  // ─── Mission Generation (deterministic by date) ────────────────────
  DailyChallenge _generateChallenge(String date) {
    final seed = date.hashCode;
    final rng = Random(seed);
    final shuffled = List<DailyMission>.from(_missionPool)..shuffle(rng);
    final picked = shuffled.take(3).map((m) => m.copyWith(currentCount: 0)).toList();

    return DailyChallenge(date: date, missions: picked);
  }

  // ─── Report Progress from Modules ──────────────────────────────────
  Future<void> reportProgress(String moduleKey) async {
    if (_todayChallenge == null) return;

    bool updated = false;
    for (final mission in _todayChallenge!.missions) {
      if (mission.moduleKey == moduleKey && !mission.isCompleted) {
        mission.currentCount++;
        updated = true;
        break;
      }
    }

    if (!updated) return;

    // Check if all missions just completed
    if (_todayChallenge!.isAllCompleted) {
      final today = _todayString();
      _progress = _progress.copyWith(
        totalStars: _progress.totalStars + _todayChallenge!.starsEarned,
        currentStreak: _progress.currentStreak + 1,
        longestStreak: max(
          _progress.longestStreak,
          _progress.currentStreak + 1,
        ),
        lastCompletedDate: today,
      );
    }

    await _saveToLocal();
    await _syncToFirestore();
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
      await prefs.setString(
        _prefKeyProgress,
        jsonEncode(_progress.toMap()),
      );
    } catch (e) {
      LoggerService.logError('Error saving daily challenge: $e');
    }
  }

  // ─── Firestore Sync ────────────────────────────────────────────────
  Future<void> _syncToFirestore() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null || _todayChallenge == null) return;

      final userRef = _firestore.collection('users').doc(user.uid);

      // Save today's challenge progress
      await userRef
          .collection('daily_progress')
          .doc(_todayChallenge!.date)
          .set(_todayChallenge!.toMap(), SetOptions(merge: true));

      // Update user-level stats
      await userRef.update({
        'totalStars': _progress.totalStars,
        'currentStreak': _progress.currentStreak,
        'longestStreak': _progress.longestStreak,
      });
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
