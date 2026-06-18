#include <Wire.h>

#define GUITAR_ADDRESS 9

const byte startSwitchPin = 13;
const byte bpmUpSwitchPin = 4;
const byte bpmDownSwitchPin = 5;

const byte joinOrderInfo = 1;
const byte drumStartTrigger = 0;
const byte scoreLength = 32;

bool playing = false;
bool lastStartSwitchState = HIGH;
bool lastBpmUpState = HIGH;
bool lastBpmDownState = HIGH;

byte beatNumber = 1;
byte currentBPM = 90;
unsigned long lastBeatTime = 0;

void setup() {
  Wire.begin();
  Wire.setClock(10000);
  Serial.begin(9600);

  pinMode(startSwitchPin, INPUT_PULLUP);
  pinMode(bpmUpSwitchPin, INPUT_PULLUP);
  pinMode(bpmDownSwitchPin, INPUT_PULLUP);

  Serial.println("hck_00_2026-06-17 master start");
}

void loop() {
  update();
}

void startSync() {
  playing = true;
  beatNumber = 1;
  lastBeatTime = millis();
  Serial.println("startSync guitar single test");
  sendSyncPacket(GUITAR_ADDRESS, beatNumber, currentBPM, joinOrderInfo, drumStartTrigger);
}

void stopSync() {
  playing = false;
  Serial.println("stopSync");
}

void update() {
  checkSwitch();
  changeBPM();

  if (!playing) {
    delay(20);
    return;
  }

  unsigned long beatInterval = 60000UL / getBPM();
  if (millis() - lastBeatTime >= beatInterval) {
    lastBeatTime += beatInterval;

    if (nextBeat()) {
      sendSyncPacket(GUITAR_ADDRESS, beatNumber, currentBPM, joinOrderInfo, drumStartTrigger);
    } else {
      stopSync();
      Serial.println("song finished");
    }
  }
}

void changeBPM() {
  bool bpmUpState = digitalRead(bpmUpSwitchPin);
  bool bpmDownState = digitalRead(bpmDownSwitchPin);

  if (lastBpmUpState == HIGH && bpmUpState == LOW && currentBPM <= 140) {
    currentBPM += 10;
    Serial.print("BPM up: ");
    Serial.println(currentBPM);
  }

  if (lastBpmDownState == HIGH && bpmDownState == LOW && currentBPM >= 70) {
    currentBPM -= 10;
    Serial.print("BPM down: ");
    Serial.println(currentBPM);
  }

  lastBpmUpState = bpmUpState;
  lastBpmDownState = bpmDownState;
}

int getBPM() {
  return currentBPM;
}

void checkSwitch() {
  bool startSwitchState = digitalRead(startSwitchPin);

  if (lastStartSwitchState == HIGH && startSwitchState == LOW) {
    if (playing) {
      stopSync();
    } else {
      startSync();
    }
  }

  lastStartSwitchState = startSwitchState;
}

bool sendSyncPacket(byte address, byte packetBeatNumber, byte packetBPM, byte packetJoinOrderInfo, byte packetDrumStartTrigger) {
  Wire.beginTransmission(address);
  Wire.write(packetBeatNumber);
  Wire.write(packetBPM);
  Wire.write(packetJoinOrderInfo);
  Wire.write(packetDrumStartTrigger);
  byte result = Wire.endTransmission();

  Serial.print("beat:");
  Serial.print(packetBeatNumber);
  Serial.print(" bpm:");
  Serial.print(packetBPM);
  Serial.print(" order:");
  Serial.print(packetJoinOrderInfo);
  Serial.print(" drum:");
  Serial.print(packetDrumStartTrigger);
  Serial.print(" send:");
  Serial.println(result == 0 ? "ok" : "ng");

  return result == 0;
}

bool nextBeat() {
  if (beatNumber >= scoreLength) {
    return false;
  }

  beatNumber++;
  return true;
}
