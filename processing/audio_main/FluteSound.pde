class FluteSound implements InstrumentSound {
  void noteOn(String pitch, float duration, float velocity) {
    out.playNote(0, duration, new ToneInstrument(pitchToFrequency(pitch), velocity * 0.45f, Waves.SINE, 0.08f));
  }

  void noteOff() {
  }
}
