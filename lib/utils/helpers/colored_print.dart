// 🌎 Project imports:

// Blue text
import 'package:flutter/foundation.dart';

void printB(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[34m$msg\x1B[0m');
}

// Green text
void printG(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[32m$msg\x1B[0m');
}

// Yellow text
void printY(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[33m$msg\x1B[0m');
}

// Red text
void printR(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[31m$msg\x1B[0m');
}

// white text
void printW(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[37m$msg\x1B[0m');
}

// cyan text
void printC(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[36m$msg\x1B[0m');
}

// black text
void printK(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[30m$msg\x1B[0m');
}

// Additional colors and bright variants
// Magenta text
void printM(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[35m$msg\x1B[0m');
}

// Light/Bright variants
void printLR(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[91m$msg\x1B[0m');
}

void printLG(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[92m$msg\x1B[0m');
}

void printLY(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[93m$msg\x1B[0m');
}

void printLB(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[94m$msg\x1B[0m');
}

void printLM(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[95m$msg\x1B[0m');
}

void printLC(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[96m$msg\x1B[0m');
}

void printLW(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[97m$msg\x1B[0m');
}

// Gray (bright black)
void printGray(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[90m$msg\x1B[0m');
}

void printO(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[38;5;208m$msg\x1B[0m');
}

void printP(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[38;5;13m$msg\x1B[0m');
}

void printPink(Object? msg) {
  if (kDebugMode) debugPrint('\x1B[38;5;205m$msg\x1B[0m');
}
