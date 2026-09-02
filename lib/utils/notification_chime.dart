import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Short PCM WAV (mono 16-bit) in memory — shared for offer, message, accept, etc.
Uint8List buildNotificationChimeWav() {
  const sampleRate = 22050;
  const ms = 200;
  final numSamples = sampleRate * ms ~/ 1000;
  const freq = 880.0;
  final dataBytes = numSamples * 2;
  final total = 44 + dataBytes;
  final out = Uint8List(total);
  final bd = ByteData.view(out.buffer);

  void writeStr(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      out[off + i] = s.codeUnitAt(i);
    }
  }

  writeStr(0, 'RIFF');
  bd.setUint32(4, 36 + dataBytes, Endian.little);
  writeStr(8, 'WAVE');
  writeStr(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little);
  bd.setUint16(22, 1, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  writeStr(36, 'data');
  bd.setUint32(40, dataBytes, Endian.little);

  final twoPi = math.pi * 2;
  final n1 = math.max(numSamples - 1, 1);
  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = 0.5 * (1 - math.cos(twoPi * i / n1));
    final v = (32767 * 0.32 * math.sin(twoPi * freq * t) * env).round().clamp(-32768, 32767);
    bd.setInt16(44 + i * 2, v, Endian.little);
  }
  return out;
}

/// Plays a short chime when the app is in foreground (avoid sound in background).
Future<void> playNotificationChime() async {
  final binding = WidgetsBinding.instance;
  if (binding.lifecycleState != AppLifecycleState.resumed) return;

  final player = AudioPlayer();
  try {
    final bytes = buildNotificationChimeWav();
    await player.play(BytesSource(bytes, mimeType: 'audio/wav'));
    await Future<void>.delayed(const Duration(milliseconds: 320));
  } catch (_) {
    // Ignore playback errors
  } finally {
    await player.dispose();
  }
}
