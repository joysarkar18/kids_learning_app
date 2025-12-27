import 'package:flutter/material.dart';
import 'package:kids_learning/audio/audio_key.dart';

class CharacterModel {
  final String name;
  final String imagePath;
  final Color backgroundColor;
  final AudioKey audioKey;
  final String key;
  CharacterModel({
    required this.name,
    required this.imagePath,
    required this.backgroundColor,
    required this.audioKey,
    required this.key,
  });
}
