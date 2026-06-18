#include <Wire.h>

#define GUITAR_ADDRESS 9

const byte startSwitchPin = 13;
const byte bpmUpSwitchPin = 4;
const byte bpmDownSwitchPin = 5;

const byte joinOrderInfo = 1;
const byte drumStartTrigger = 0;
const byte ticksPerBeat = 4;
const byte scoreLengthTicks = 80;

bool playing = false;
bool lastStartSwitchState = HIGH;
bool lastBpmUpState = HIGH;
bool lastBpmDownState = HIGH;

byte tickNumber = 1;
byte currentBPM = 76;
unsigned long lastTickTime = 0;

void setup() {
  Wire.begin();
  Wire.setClock(10000);
  Serial.begin(9600);

  pinMode(startSwitchPin, INPUT_PULLUP);
  pinMode(bpmUpSwitchPin, INPUT_PULLUP);
  pinMode(bpmDownSwitchPin, INPUT_PULLUP);

  Serial.println("hck_00_2026-06-18 master start");
}

void loop() {
  update();
}

void startSync() {
  playing = true;
  tickNumber = 1;
  lastTickTime = millis();
  Serial.println("startSync unified score");
  sendSyncPacket(GUITAR_ADDRESS, tickNumber, currentBPM, joinOrderInfo, drumStartTrigger);
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

  unsigned long tickInterval = 60000UL / getBPM() / ticksPerBeat;
  if (millis() - lastTickTime >= tickInterval) {
    lastTickTime += tickInterval;

    if (nextTick()) {
      sendSyncPacket(GUITAR_ADDRESS, tickNumber, currentBPM, joinOrderInfo, drumStartTrigger);
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

bool sendSyncPacket(byte address, byte packetTickNumber, byte packetBPM, byte packetJoinOrderInfo, byte packetDrumStartTrigger) {
  Wire.beginTransmission(address);
  Wire.write(packetTickNumber);
  Wire.write(packetBPM);
  Wire.write(packetJoinOrderInfo);
  Wire.write(packetDrumStartTrigger);
  byte result = Wire.endTransmission();

  Serial.print("tick:");
  Serial.print(packetTickNumber);
  Serial.print(" beat:");
  Serial.print((packetTickNumber - 1) / ticksPerBeat + 1);
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

bool nextTick() {
  if (tickNumber >= scoreLengthTicks) {
    return false;
  }

  tickNumber++;
  return true;
}
