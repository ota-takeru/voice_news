import 'package:flutter/foundation.dart';

class VoiceSettings {
  final double speed;
  final String selectedVoice;
  final List<String> availableVoices;

  VoiceSettings({
    this.speed = 1.0,
    this.selectedVoice = '',
    this.availableVoices = const [],
  });

  VoiceSettings copyWith({
    double? speed,
    String? selectedVoice,
    List<String>? availableVoices,
  }) {
    return VoiceSettings(
      speed: speed ?? this.speed,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      availableVoices: availableVoices ?? this.availableVoices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speed': speed,
      'selectedVoice': selectedVoice,
      'availableVoices': availableVoices,
    };
  }

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      selectedVoice: json['selectedVoice'] as String? ?? '',
      availableVoices: (json['availableVoices'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceSettings &&
        other.speed == speed &&
        other.selectedVoice == selectedVoice &&
        listEquals(other.availableVoices, availableVoices);
  }

  @override
  int get hashCode =>
      speed.hashCode ^ selectedVoice.hashCode ^ availableVoices.hashCode;
}
