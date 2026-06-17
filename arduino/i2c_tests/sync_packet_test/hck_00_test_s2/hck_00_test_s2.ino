#include <Wire.h>

#define SLAVE_ADDRESS 9
#define SLAVE_ID 2

const byte ledPin = 8;
const byte instrumentId = 2;
const char instrumentName[] = "guitar";
const char* notes[] = {"C4", "D4", "E4", "F4"};

volatile byte packetBeatNumber = 0;
volatile byte packetBPM = 0;
volatile byte packetTargetSlaveId = 0;
volatile bool packetReceived = false;

void setup() {
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  update();
}

void update() {
  digitalWrite(LED_BUILTIN, millis() / 500 % 2);

  if (receiveSyncPacket() && checkPacket()) {
    if (packetTargetSlaveId == SLAVE_ID) {
      playCurrentNote();
    } else {
      stop();
    }
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
  if (packetBeatNumber < 1 || packetBeatNumber > 4) {
    return false;
  }
  if (packetBPM < 40 || packetBPM > 240) {
    return false;
  }
  return packetTargetSlaveId <= 4;
}

void playCurrentNote() {
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
  return String(notes[(packetBeatNumber - 1) % 4]);
}

void nextNote() {
}

String formatData() {
  String data = "PERF,";
  data += instrumentId;
  data += ",";
  data += instrumentName;
  data += ",";
  data += getNote();
  data += ",";
  data += "0.35,0.75,";
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
  if (Wire.available() >= 3) {
    packetBeatNumber = Wire.read();
    packetBPM = Wire.read();
    packetTargetSlaveId = Wire.read();
    packetReceived = true;
  }
  while (Wire.available() > 0) {
    Wire.read();
  }
}
