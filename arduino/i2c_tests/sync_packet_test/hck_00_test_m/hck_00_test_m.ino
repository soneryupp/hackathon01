#include <Wire.h>

#define SLAVE_COUNT 4

const byte startSwitchPin = 13;
const byte bpmUpSwitchPin = 4;
const byte bpmDownSwitchPin = 5;
const byte slaveAddresses[SLAVE_COUNT] = {8, 9, 10, 11};
const byte slaveIds[SLAVE_COUNT] = {1, 2, 3, 4};

bool syncRunning = false;
byte beatNumber = 1;
byte activeIndex = 0;
byte currentBPM = 90;
unsigned long lastBeatTime = 0;
bool lastStartSwitchState = HIGH;
bool lastBpmUpState = HIGH;
bool lastBpmDownState = HIGH;

void setup() {
  Wire.begin();
  Wire.setClock(10000);
  Serial.begin(9600);
  pinMode(startSwitchPin, INPUT_PULLUP);
  pinMode(bpmUpSwitchPin, INPUT_PULLUP);
  pinMode(bpmDownSwitchPin, INPUT_PULLUP);
  Serial.println("hck_00_test master start");
}

void loop() {
  update();
}

void startSync() {
  syncRunning = true;
  beatNumber = 1;
  activeIndex = 0;
  lastBeatTime = millis();
  Serial.println("startSync");
  sendBeatPacket();
}

void stopSync() {
  syncRunning = false;
  Serial.println("stopSync");
}

void update() {
  checkSwitch();
  changeBPM();

  if (!syncRunning) {
    delay(20);
    return;
  }

  unsigned long beatInterval = 60000UL / getBPM();
  if (millis() - lastBeatTime >= beatInterval) {
    lastBeatTime += beatInterval;
    nextBeat();
    sendBeatPacket();
  }
}

void changeBPM() {
  bool bpmUpState = digitalRead(bpmUpSwitchPin);
  bool bpmDownState = digitalRead(bpmDownSwitchPin);

  if (lastBpmUpState == HIGH && bpmUpState == LOW && currentBPM <= 140) {
    currentBPM += 10;
    sendBPM();
  }

  if (lastBpmDownState == HIGH && bpmDownState == LOW && currentBPM >= 70) {
    currentBPM -= 10;
    sendBPM();
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
    if (syncRunning) {
      stopSync();
    } else {
      startSync();
    }
  }

  lastStartSwitchState = startSwitchState;
}

int getActiveInfo() {
  return slaveIds[activeIndex];
}

bool sendSyncPacket(byte address, byte packetBeatNumber, byte packetBPM, byte targetSlaveId) {
  Wire.beginTransmission(address);
  Wire.write(packetBeatNumber);
  Wire.write(packetBPM);
  Wire.write(targetSlaveId);
  return Wire.endTransmission() == 0;
}

bool sendBPM() {
  bool allOk = true;
  for (byte i = 0; i < SLAVE_COUNT; i++) {
    bool ok = sendSyncPacket(slaveAddresses[i], beatNumber, currentBPM, 0);
    allOk = allOk && ok;
  }

  Serial.print("sendBPM bpm:");
  Serial.print(currentBPM);
  Serial.print(" result:");
  Serial.println(allOk ? "ok" : "ng");
  return allOk;
}

void sendBeatPacket() {
  byte targetSlaveId = getActiveInfo();
  bool allOk = true;

  for (byte i = 0; i < SLAVE_COUNT; i++) {
    bool ok = sendSyncPacket(slaveAddresses[i], beatNumber, currentBPM, targetSlaveId);
    allOk = allOk && ok;
  }

  Serial.print("beat:");
  Serial.print(beatNumber);
  Serial.print(" bpm:");
  Serial.print(currentBPM);
  Serial.print(" target:");
  Serial.print(targetSlaveId);
  Serial.print(" send:");
  Serial.println(allOk ? "ok" : "ng");
}

void nextBeat() {
  beatNumber++;
  if (beatNumber > 4) {
    beatNumber = 1;
  }

  activeIndex++;
  if (activeIndex >= SLAVE_COUNT) {
    activeIndex = 0;
  }
}
