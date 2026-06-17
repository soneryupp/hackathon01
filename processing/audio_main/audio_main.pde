import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial port;
ProcessingAudioManager audioManager;

int serialBaud = 115200;
int serialPortIndex = -1;
String fixedPortName = "";
String[] serialPorts;
String lastMessage = "";

void setup() {
  size(900, 420);
  pixelDensity(1);

  minim = new Minim(this);
  out = minim.getLineOut(Minim.STEREO, 256);
  audioManager = new ProcessingAudioManager();

  serialPorts = Serial.list();
  serialPortIndex = findArduinoPort();
  openSerialPort(serialPortIndex);
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
  text("audio_main / ProcessingAudioManager", 20, 28);
  text("last message: " + lastMessage, 20, 55);
  text("instrument: " + audioManager.instrumentId + " " + audioManager.instrumentName, 20, 80);
  text("pitch: " + audioManager.pitch, 20, 105);
  text("duration: " + nf(audioManager.duration, 1, 2), 20, 130);
  text("velocity: " + nf(audioManager.velocity, 1, 2), 20, 155);
  text("beat: " + audioManager.beatNumber + " bpm: " + audioManager.bpm, 20, 180);
  text("serial port index: " + serialPortIndex, 20, 205);
  text("press 1-4: local sound test / press 0-9: change serial port", 20, 230);

  if (serialPorts != null) {
    for (int i = 0; i < serialPorts.length && i < 10; i++) {
      text(i + ": " + serialPorts[i], 20, 260 + i * 18);
    }
  }
}

void serialEvent(Serial p) {
  String message = p.readStringUntil('\n');
  if (message == null) {
    return;
  }

  message = trim(message);
  if (message.length() == 0) {
    return;
  }

  lastMessage = message;
  if (audioManager.parsePerformanceData(message)) {
    audioManager.playSound();
  }
}

void keyPressed() {
  if (key >= '0' && key <= '9') {
    openSerialPort(key - '0');
    return;
  }

  if (key == '1') {
    testPerformanceData("PERF,1,piano,C4,0.35,0.75,1,90");
  } else if (key == '2') {
    testPerformanceData("PERF,2,guitar,E4,0.35,0.75,2,90");
  } else if (key == '3') {
    testPerformanceData("PERF,3,flute,G4,0.35,0.75,3,90");
  } else if (key == '4') {
    testPerformanceData("PERF,4,drum,kick,0.20,0.90,4,90");
  }
}

void testPerformanceData(String data) {
  lastMessage = data;
  if (audioManager.parsePerformanceData(data)) {
    audioManager.playSound();
  }
}

int findArduinoPort() {
  if (fixedPortName.length() > 0) {
    for (int i = 0; i < serialPorts.length; i++) {
      if (serialPorts[i].equals(fixedPortName)) {
        return i;
      }
    }
    return -1;
  }

  for (int i = 0; i < serialPorts.length; i++) {
    String name = serialPorts[i].toLowerCase();
    if (name.indexOf("usbmodem") >= 0 || name.indexOf("usbserial") >= 0) {
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
  if (index < 0 || index >= serialPorts.length) {
    serialPortIndex = index;
    lastMessage = "serial port not found";
    return;
  }

  serialPortIndex = index;
  port = new Serial(this, serialPorts[serialPortIndex], serialBaud);
  port.bufferUntil('\n');
  port.clear();
  lastMessage = "serial open: " + serialPorts[serialPortIndex];
}
