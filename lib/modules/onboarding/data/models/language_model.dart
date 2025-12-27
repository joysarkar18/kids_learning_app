import 'package:flutter/material.dart';

class LanguageModel {
  final String name;
  final String nativeName;
  final String code;
  final String flagEmoji;
  final Color backgroundColor;

  LanguageModel({
    required this.name,
    required this.nativeName,
    required this.code,
    required this.flagEmoji,
    required this.backgroundColor,
  });
}
