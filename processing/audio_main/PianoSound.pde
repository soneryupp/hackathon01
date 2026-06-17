class PianoSound implements InstrumentSound {
  void noteOn(String pitch, float duration, float velocity) {
    out.playNote(0, duration, new ToneInstrument(pitchToFrequency(pitch), velocity * 0.65f, Waves.TRIANGLE, 0.25f));
  }

  void noteOff() {
  }
}
