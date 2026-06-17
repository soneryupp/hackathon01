class GuitarSound implements InstrumentSound {
  Waveform guitarWaveform;

  GuitarSound() {
    guitarWaveform = WavetableGenerator.gen10(
      4096,
      new float[] {
        1.50f, 1.00f, 0.50f, 0.37f, 0.15f,
        0.13f, 0.12f, 0.08f, 0.04f, 0.02f
      }
    );
  }

  void noteOn(String pitch, float duration, float velocity) {
    out.playNote(0, duration, new ToneInstrument(pitchToFrequency(pitch), velocity * 0.80f, guitarWaveform, 0.35f));
  }

  void noteOff() {
  }
}
