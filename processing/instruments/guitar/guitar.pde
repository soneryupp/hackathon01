import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

final int INSTRUMENT_ID = 2;
final String INSTRUMENT_NAME = "guitar";

Minim minim;
AudioOutput out;
Serial port;
String[] serialPorts;
String fixedPortName = "";
int serialPortIndex = -1;
int serialBaud = 115200;
Waveform guitarWaveform;

String lastMessage = "";
String lastPitch = "";
float lastDuration = 0;
float lastVelocity = 0;
int lastBeat = 0;
int lastBPM = 0;

class GuitarInstrument implements Instrument {
  Oscil wave;
  Oscil attackWave;
  Noise pickNoise;
  Line ampEnv;
  Line attackEnv;
  Line noiseEnv;
  float amp;

  GuitarInstrument(float frequency, float amp) {
    this.amp = amp;
    wave = new Oscil(frequency, 0, guitarWaveform);
    attackWave = new Oscil(frequency * 10.0f, 0, Waves.SAW);
    pickNoise = new Noise(0);
    ampEnv = new Line();
    attackEnv = new Line();
    noiseEnv = new Line();
    ampEnv.patch(wave.amplitude);
    attackEnv.patch(attackWave.amplitude);
    noiseEnv.patch(pickNoise.amplitude);
  }

  void noteOn(float duration) {
    ampEnv.activate(duration, amp, 0);
    attackEnv.activate(0.06f, amp * 0.35f, 0);
    noiseEnv.activate(0.015f, amp * 0.18f, 0);
    wave.patch(out);
    attackWave.patch(out);
    pickNoise.patch(out);
  }

  void noteOff() {
    wave.unpatch(out);
    attackWave.unpatch(out);
    pickNoise.unpatch(out);
  }
}

void setup() {
  size(820, 400);
  minim = new Minim(this);
  out = minim.getLineOut(Minim.STEREO, 256);
  guitarWaveform = WavetableGenerator.gen10(
    4096,
    new float[] {
      1.50f, 1.00f, 0.50f, 0.37f, 0.15f,
      0.13f, 0.12f, 0.08f, 0.04f, 0.02f
    }
  );
  serialPorts = Serial.list();
  openSerialPort(findArduinoPort());
}

void draw() {
  drawMonitor("Guitar");
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
  lastBeat = parseInt(data[6]);
  lastBPM = parseInt(data[7]);

  playGuitar(lastPitch, lastDuration, lastVelocity);
  return true;
}

void playGuitar(String pitch, float duration, float velocity) {
  out.playNote(0, duration, new GuitarInstrument(pitchToFrequency(pitch), velocity));
}

float pitchToFrequency(String pitch) {
  float value = parseFloat(pitch);
  return Float.isNaN(value) ? Frequency.ofPitch(pitch).asHz() : value;
}

void keyPressed() {
  if (key == ' ') {
    receivePerformanceData("PERF,2,guitar,E4,0.50,0.75,1,90");
  } else if (key >= '0' && key <= '9') {
    openSerialPort(key - '0');
  }
}

void drawMonitor(String title) {
  background(0);
  stroke(255);
  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 105 - out.left.get(i) * 75, i + 1, 105 - out.left.get(i + 1) * 75);
    line(i, 295 - out.right.get(i) * 75, i + 1, 295 - out.right.get(i + 1) * 75);
  }

  fill(255);
  textSize(16);
  text(title + " sound", 20, 28);
  text("last message: " + lastMessage, 20, 55);
  text("pitch: " + lastPitch, 20, 80);
  text("duration: " + nf(lastDuration, 1, 3), 20, 105);
  text("velocity: " + nf(lastVelocity, 1, 2), 20, 130);
  text("beat: " + lastBeat + " bpm: " + lastBPM, 20, 155);
  text("serial port index: " + serialPortIndex, 20, 180);
  text("space: local test / 0-9: change port", 20, 205);
  for (int i = 0; i < serialPorts.length && i < 10; i++) {
    text(i + ": " + serialPorts[i], 20, 235 + i * 18);
  }
}

int findArduinoPort() {
  for (int i = 0; i < serialPorts.length; i++) {
    if (fixedPortName.length() > 0 && serialPorts[i].equals(fixedPortName)) {
      return i;
    }
    String name = serialPorts[i].toLowerCase();
    if (fixedPortName.length() == 0 && (name.indexOf("usbmodem") >= 0 || name.indexOf("usbserial") >= 0)) {
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
