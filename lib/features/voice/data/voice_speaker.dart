abstract interface class VoiceSpeaker {
  bool get isAvailable;

  Future<void> speak(String text);

  Future<void> stop();
}
