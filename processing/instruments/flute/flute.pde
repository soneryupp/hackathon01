import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

final int INSTRUMENT_ID = 3;
final String INSTRUMENT_NAME = "flute";

Minim minim;
AudioOutput out;
Serial port;
String[] serialPorts;
String fixedPortName = "";
int serialPortIndex = -1;
int serialBaud = 115200;

String lastMessage = "";
String lastPitch = "";
float lastDuration = 0;
float lastVelocity = 0;
int lastBeat = 0;
int lastBPM = 0;

class FluteInstrument implements Instrument {
  Oscil tone;
  Noise breath;
  Line toneEnv;
  Line breathEnv;
  float amp;

  FluteInstrument(float frequency, float amp) {
    this.amp = amp;
    tone = new Oscil(frequency, 0, Waves.SINE);
    breath = new Noise(0);
    toneEnv = new Line();
    breathEnv = new Line();
    toneEnv.patch(tone.amplitude);
    breathEnv.patch(breath.amplitude);
  }

  void noteOn(float duration) {
    toneEnv.activate(duration, amp * 0.55f, 0);
    breathEnv.activate(duration, amp * 0.035f, 0);
    tone.patch(out);
    breath.patch(out);
  }

  void noteOff() {
    tone.unpatch(out);
    breath.unpatch(out);
  }
}

void setup() {
  size(820, 400);
  minim = new Minim(this);
  out = minim.getLineOut(Minim.STEREO, 256);
  serialPorts = Serial.list();
  openSerialPort(findArduinoPort());
}

void draw() {
  drawMonitor("Flute");
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

  playFlute(lastPitch, lastDuration, lastVelocity);
  return true;
}

void playFlute(String pitch, float duration, float velocity) {
  out.playNote(0, duration, new FluteInstrument(pitchToFrequency(pitch), velocity));
}

float pitchToFrequency(String pitch) {
  float value = parseFloat(pitch);
  return Float.isNaN(value) ? Frequency.ofPitch(pitch).asHz() : value;
}

void keyPressed() {
  if (key == ' ') {
    receivePerformanceData("PERF,3,flute,G4,0.50,0.75,1,90");
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
