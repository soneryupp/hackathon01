import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

final int INSTRUMENT_ID = 4;
final String INSTRUMENT_NAME = "drum";

Minim minim;
AudioOutput out;
Serial port;
String[] serialPorts;
String fixedPortName = "";
int serialPortIndex = -1;
int serialBaud = 115200;

String lastMessage = "";
String lastDrumType = "";
float lastDuration = 0;
float lastVelocity = 0;
int lastBeat = 0;
int lastBPM = 0;

class DrumInstrument implements Instrument {
  Noise noise;
  Oscil body;
  Line noiseEnv;
  Line bodyEnv;
  String drumType;
  float amp;

  DrumInstrument(String drumType, float amp) {
    this.drumType = drumType;
    this.amp = amp;
    noise = new Noise(0);
    float frequency = drumType.equals("kick") ? 65.0f : 180.0f;
    body = new Oscil(frequency, 0, Waves.SINE);
    noiseEnv = new Line();
    bodyEnv = new Line();
    noiseEnv.patch(noise.amplitude);
    bodyEnv.patch(body.amplitude);
  }

  void noteOn(float duration) {
    float noiseAmp = drumType.equals("hat") ? amp : amp * 0.55f;
    float bodyAmp = drumType.equals("hat") ? amp * 0.08f : amp;
    noiseEnv.activate(duration, noiseAmp, 0);
    bodyEnv.activate(duration, bodyAmp, 0);
    noise.patch(out);
    body.patch(out);
  }

  void noteOff() {
    noise.unpatch(out);
    body.unpatch(out);
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
  drawMonitor("Drum");
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
  lastDrumType = data[3];
  lastDuration = max(duration, 0.03f);
  lastVelocity = constrain(velocity, 0.0f, 1.0f);
  lastBeat = parseInt(data[6]);
  lastBPM = parseInt(data[7]);

  playDrum(lastDrumType, lastDuration, lastVelocity);
  return true;
}

void playDrum(String drumType, float duration, float velocity) {
  out.playNote(0, duration, new DrumInstrument(drumType, velocity));
}

void keyPressed() {
  if (key == ' ') {
    receivePerformanceData("PERF,4,drum,kick,0.20,0.90,1,90");
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
  text("drum type: " + lastDrumType, 20, 80);
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
