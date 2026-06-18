import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

// =====================================================
// Instrument settings: copy this sketch and edit here
// =====================================================
final int INSTRUMENT_ID = 2;
final String INSTRUMENT_NAME = "guitar";

final float[] HARMONICS = {
  1.00f, 0.67f, 0.33f, 0.25f, 0.10f,
  0.09f, 0.08f, 0.05f, 0.03f, 0.01f
};

final float OUTPUT_GAIN = 0.80f;
final float ATTACK_GAIN = 0.35f;
final float ATTACK_SECONDS = 0.06f;
final float NOISE_GAIN = 0.18f;
final float NOISE_SECONDS = 0.015f;
final Waveform ATTACK_WAVEFORM = Waves.SAW;
// =====================================================

Minim minim;
AudioOutput out;
Serial port;
String[] serialPorts;
String fixedPortName = "";
int serialPortIndex = -1;
int serialBaud = 115200;
Waveform instrumentWaveform;

String lastMessage = "";
String lastPitch = "";
float lastDuration = 0;
float lastVelocity = 0;
int lastTick = 0;
int lastBPM = 0;

class ConfigurableToneInstrument implements Instrument {
  Oscil wave;
  Oscil attackWave;
  Noise noise;
  Line waveEnv;
  Line attackEnv;
  Line noiseEnv;
  float amp;

  ConfigurableToneInstrument(float frequency, float amp) {
    this.amp = amp;
    wave = new Oscil(frequency, 0, instrumentWaveform);
    attackWave = new Oscil(frequency * 2.0f, 0, ATTACK_WAVEFORM);
    noise = new Noise(0);

    waveEnv = new Line();
    attackEnv = new Line();
    noiseEnv = new Line();

    waveEnv.patch(wave.amplitude);
    attackEnv.patch(attackWave.amplitude);
    noiseEnv.patch(noise.amplitude);
  }

  void noteOn(float duration) {
    waveEnv.activate(duration, amp * OUTPUT_GAIN, 0);
    attackEnv.activate(ATTACK_SECONDS, amp * ATTACK_GAIN, 0);
    noiseEnv.activate(NOISE_SECONDS, amp * NOISE_GAIN, 0);

    wave.patch(out);
    attackWave.patch(out);
    noise.patch(out);
  }

  void noteOff() {
    wave.unpatch(out);
    attackWave.unpatch(out);
    noise.unpatch(out);
  }
}

void setup() {
  size(840, 420);
  minim = new Minim(this);
  out = minim.getLineOut(Minim.STEREO, 256);
  instrumentWaveform = WavetableGenerator.gen10(4096, HARMONICS);

  serialPorts = Serial.list();
  openSerialPort(findArduinoPort());
}

void draw() {
  background(0);
  stroke(255);

  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 110 - out.left.get(i) * 80, i + 1, 110 - out.left.get(i + 1) * 80);
    line(i, 310 - out.right.get(i) * 80, i + 1, 310 - out.right.get(i + 1) * 80);
  }

  fill(255);
  textSize(15);
  text("Configurable tone instrument: " + INSTRUMENT_NAME, 20, 28);
  text("instrument ID: " + INSTRUMENT_ID, 20, 53);
  text("last message: " + lastMessage, 20, 78);
  text("pitch: " + lastPitch, 20, 103);
  text("duration: " + nf(lastDuration, 1, 3), 20, 128);
  text("velocity: " + nf(lastVelocity, 1, 2), 20, 153);
  text("tick: " + lastTick + " bpm: " + lastBPM, 20, 178);
  text("serial port index: " + serialPortIndex, 20, 203);
  text("space: local test / 0-9: change port", 20, 228);

  for (int i = 0; i < serialPorts.length && i < 10; i++) {
    text(i + ": " + serialPorts[i], 20, 258 + i * 18);
  }
}

void serialEvent(Serial source) {
  String message = source.readStringUntil('\n');
  if (message != null) {
    receivePerformanceData(trim(message));
  }
}

boolean receivePerformanceData(String message) {
  String[] data = splitTokens(message, ", ");

  if (data.length < 8 || !data[0].equals("PERF")) {
    return false;
  }

  int instrumentId = parseInt(data[1]);
  if (instrumentId != INSTRUMENT_ID || !data[2].equals(INSTRUMENT_NAME)) {
    return false;
  }

  float duration = parseFloat(data[4]);
  float velocity = parseFloat(data[5]);
  if (Float.isNaN(duration) || Float.isNaN(velocity)) {
    return false;
  }

  lastMessage = message;
  lastPitch = data[3];
  lastDuration = max(duration, 0.05f);
  lastVelocity = constrain(velocity, 0.0f, 1.0f);
  lastTick = parseInt(data[6]);
  lastBPM = parseInt(data[7]);

  playTone(lastPitch, lastDuration, lastVelocity);
  return true;
}

void playTone(String pitch, float duration, float velocity) {
  out.playNote(
    0,
    duration,
    new ConfigurableToneInstrument(pitchToFrequency(pitch), velocity)
  );
}

float pitchToFrequency(String pitch) {
  float value = parseFloat(pitch);
  return Float.isNaN(value) ? Frequency.ofPitch(pitch).asHz() : value;
}

void keyPressed() {
  if (key == ' ') {
    String testData = "PERF,";
    testData += INSTRUMENT_ID;
    testData += ",";
    testData += INSTRUMENT_NAME;
    testData += ",F4,0.50,0.80,1,";
    testData += 76;
    receivePerformanceData(testData);
  } else if (key >= '0' && key <= '9') {
    openSerialPort(key - '0');
  }
}

int findArduinoPort() {
  for (int i = 0; i < serialPorts.length; i++) {
    if (fixedPortName.length() > 0 && serialPorts[i].equals(fixedPortName)) {
      return i;
    }

    String name = serialPorts[i].toLowerCase();
    if (fixedPortName.length() == 0 &&
        (name.indexOf("usbmodem") >= 0 || name.indexOf("usbserial") >= 0)) {
      return i;
    }
  }

  return serialPorts.length > 0 ? 0 : -1;
}

void openSerialPort(int index) {
  if (port != null) {
    port.stop();
    port = null;
  }

  serialPorts = Serial.list();
  serialPortIndex = index;

  if (index < 0 || index >= serialPorts.length) {
    lastMessage = "serial port not found";
    return;
  }

  port = new Serial(this, serialPorts[index], serialBaud);
  port.bufferUntil('\n');
  port.clear();
  lastMessage = "serial open: " + serialPorts[index];
}
