interface InstrumentSound {
  void noteOn(String pitch, float duration, float velocity);
  void noteOff();
}

class ToneInstrument implements Instrument {
  Oscil wave;
  Oscil attackWave;
  Line ampEnv;
  Line attackEnv;
  float amp;
  float attackRatio;

  ToneInstrument(float frequency, float amp, Waveform waveform, float attackRatio) {
    wave = new Oscil(frequency, 0, waveform);
    attackWave = new Oscil(frequency * 2.0f, 0, Waves.SINE);
    ampEnv = new Line();
    attackEnv = new Line();
    ampEnv.patch(wave.amplitude);
    attackEnv.patch(attackWave.amplitude);
    this.amp = amp;
    this.attackRatio = attackRatio;
  }

  void noteOn(float duration) {
    ampEnv.activate(duration, amp, 0);
    attackEnv.activate(0.04f, amp * attackRatio, 0);
    wave.patch(out);
    attackWave.patch(out);
  }

  void noteOff() {
    wave.unpatch(out);
    attackWave.unpatch(out);
  }
}

class DrumInstrument implements Instrument {
  Noise noise;
  Oscil thump;
  Line noiseEnv;
  Line thumpEnv;
  float amp;
  String drumType;

  DrumInstrument(String drumType, float amp) {
    this.drumType = drumType;
    this.amp = amp;
    noise = new Noise(0);
    float frequency = drumType.equals("kick") ? 70 : 180;
    thump = new Oscil(frequency, 0, Waves.SINE);
    noiseEnv = new Line();
    thumpEnv = new Line();
    noiseEnv.patch(noise.amplitude);
    thumpEnv.patch(thump.amplitude);
  }

  void noteOn(float duration) {
    float noiseAmp = drumType.equals("hat") ? amp : amp * 0.55f;
    noiseEnv.activate(duration, noiseAmp, 0);
    thumpEnv.activate(duration, amp, 0);
    noise.patch(out);
    thump.patch(out);
  }

  void noteOff() {
    noise.unpatch(out);
    thump.unpatch(out);
  }
}

float pitchToFrequency(String pitch) {
  float value = parseFloat(pitch);
  if (!Float.isNaN(value)) {
    return value;
  }
  return Frequency.ofPitch(pitch).asHz();
}
