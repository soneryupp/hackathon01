#include <Wire.h>

#define SLAVE_ADDRESS 9
#define INSTRUMENT_ID 2

const byte ledPin = 8;
const char instrumentName[] = "guitar";

const byte scoreLength = 32;
const char* scorePitches[scoreLength] = {
  "C4", "D4", "E4", "F4", "E4", "D4", "C4", "REST",
  "E4", "F4", "G4", "A4", "G4", "F4", "E4", "REST",
  "C4", "REST", "C4", "REST", "C4", "REST", "C4", "REST",
  "C4", "C4", "D4", "D4", "E4", "E4", "F4", "F4"
};
const float scoreBeatLengths[scoreLength] = {
  1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0,
  1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0,
  1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0,
  0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0
};

volatile byte packetBeatNumber = 0;
volatile byte packetBPM = 0;
volatile byte packetJoinOrderInfo = 0;
volatile byte packetDrumStartTrigger = 0;
volatile bool packetReceived = false;

void setup() {
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
  Serial.begin(115200);

  pinMode(ledPin, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(ledPin, LOW);
}

void loop() {
  update();
}

void update() {
  digitalWrite(LED_BUILTIN, millis() / 500 % 2);

  if (receiveSyncPacket() && checkPacket()) {
    playCurrentNote();
  }
}

bool receiveSyncPacket() {
  if (!packetReceived) {
    return false;
  }
  packetReceived = false;
  return true;
}

bool checkPacket() {
  if (packetBeatNumber < 1 || packetBeatNumber > scoreLength) {
    return false;
  }
  if (packetBPM < 40 || packetBPM > 240) {
    return false;
  }
  if (packetJoinOrderInfo != 1) {
    return false;
  }
  return packetDrumStartTrigger == 0;
}

void playCurrentNote() {
  String note = getNote();

  if (note.equals("REST")) {
    stop();
    return;
  }

  turnOn();
  sendPerformanceData();
}

void stop() {
  turnOff();
}

void turnOn() {
  digitalWrite(ledPin, HIGH);
}

void turnOff() {
  digitalWrite(ledPin, LOW);
}

String getNote() {
  return String(scorePitches[getScoreIndex()]);
}

void nextNote() {
}

byte getScoreIndex() {
  return (packetBeatNumber - 1) % scoreLength;
}

float getNoteLengthSeconds() {
  float secondsPerBeat = 60.0 / packetBPM;
  return secondsPerBeat * scoreBeatLengths[getScoreIndex()] * 0.85;
}

String formatData() {
  String data = "PERF,";
  data += INSTRUMENT_ID;
  data += ",";
  data += instrumentName;
  data += ",";
  data += getNote();
  data += ",";
  data += String(getNoteLengthSeconds(), 3);
  data += ",0.75,";
  data += packetBeatNumber;
  data += ",";
  data += packetBPM;
  return data;
}

bool sendPerformanceData() {
  Serial.println(formatData());
  return true;
}

void receiveEvent(int howMany) {
  if (Wire.available() >= 4) {
    packetBeatNumber = Wire.read();
    packetBPM = Wire.read();
    packetJoinOrderInfo = Wire.read();
    packetDrumStartTrigger = Wire.read();
    packetReceived = true;
  }

  while (Wire.available() > 0) {
    Wire.read();
  }
}
