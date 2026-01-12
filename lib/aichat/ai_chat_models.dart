import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final String? petName;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    this.petName,
    required this.timestamp,
  });
}