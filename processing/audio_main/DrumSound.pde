class DrumSound implements InstrumentSound {
  void noteOn(String pitch, float duration, float velocity) {
    out.playNote(0, duration, new DrumInstrument(pitch, velocity));
  }

  void noteOff() {
  }
}
