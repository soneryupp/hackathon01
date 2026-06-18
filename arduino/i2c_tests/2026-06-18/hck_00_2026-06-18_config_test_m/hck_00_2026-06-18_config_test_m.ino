#include <Wire.h>

// =====================================================
// Test settings: edit this section only
// =====================================================
const byte TEST_BPM = 76;

const byte PIANO_ID = 1;
const byte GUITAR_ID = 2;
const byte FLUTE_ID = 3;

const byte PARTICIPATION_ORDER[3] = {
  PIANO_ID,
  GUITAR_ID,
  FLUTE_ID
};

// Use {9} for the current guitar-only test.
// Use {8, 9, 10} after all three children are connected.
const byte TARGET_ADDRESSES[] = {9};
const byte TARGET_COUNT = sizeof(TARGET_ADDRESSES) / sizeof(TARGET_ADDRESSES[0]);

// Delay between instruments joining the round.
// 16 ticks = 4 quarter-note beats.
const byte JOIN_DELAY_TICKS = 16;
// =====================================================

const byte startSwitchPin = 13;
const byte ticksPerBeat = 4;
const byte scoreLengthTicks = 80;
const byte drumStartTrigger = 0;

bool playing = false;
bool lastStartSwitchState = HIGH;
byte tickNumber = 1;
unsigned long lastTickTime = 0;

void setup() {
  Wire.begin();
  Wire.setClock(10000);
  Serial.begin(9600);
  pinMode(startSwitchPin, INPUT_PULLUP);

  Serial.println("hck_00_2026-06-18 config test master");
  printTestSettings();
}

void loop() {
  update();
}

void startSync() {
  playing = true;
  tickNumber = 1;
  lastTickTime = millis();
  Serial.println("startSync");
  sendPacketToAll();
}

void stopSync() {
  playing = false;
  Serial.println("stopSync");
}

void update() {
  checkSwitch();

  if (!playing) {
    delay(20);
    return;
  }

  unsigned long tickInterval = 60000UL / TEST_BPM / ticksPerBeat;
  if (millis() - lastTickTime >= tickInterval) {
    lastTickTime += tickInterval;

    if (nextTick()) {
      sendPacketToAll();
    } else {
      stopSync();
      Serial.println("song finished");
    }
  }
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

void sendPacketToAll() {
  bool allOk = true;

  for (byte i = 0; i < TARGET_COUNT; i++) {
    bool ok = sendSyncPacket(
      TARGET_ADDRESSES[i],
      tickNumber,
      TEST_BPM,
      PARTICIPATION_ORDER[0],
      PARTICIPATION_ORDER[1],
      PARTICIPATION_ORDER[2],
      drumStartTrigger
    );
    allOk = allOk && ok;
  }

  Serial.print("tick:");
  Serial.print(tickNumber);
  Serial.print(" bpm:");
  Serial.print(TEST_BPM);
  Serial.print(" order:");
  Serial.print(PARTICIPATION_ORDER[0]);
  Serial.print("-");
  Serial.print(PARTICIPATION_ORDER[1]);
  Serial.print("-");
  Serial.print(PARTICIPATION_ORDER[2]);
  Serial.print(" send:");
  Serial.println(allOk ? "ok" : "ng");
}

bool sendSyncPacket(
  byte address,
  byte packetTickNumber,
  byte packetBPM,
  byte order1,
  byte order2,
  byte order3,
  byte packetDrumStartTrigger
) {
  Wire.beginTransmission(address);
  Wire.write(packetTickNumber);
  Wire.write(packetBPM);
  Wire.write(order1);
  Wire.write(order2);
  Wire.write(order3);
  Wire.write(packetDrumStartTrigger);
  return Wire.endTransmission() == 0;
}

bool nextTick() {
  byte finalTick = scoreLengthTicks + JOIN_DELAY_TICKS * 2;
  if (tickNumber >= finalTick) {
    return false;
  }

  tickNumber++;
  return true;
}

void printTestSettings() {
  Serial.print("BPM:");
  Serial.println(TEST_BPM);
  Serial.print("participation order:");
  Serial.print(PARTICIPATION_ORDER[0]);
  Serial.print(",");
  Serial.print(PARTICIPATION_ORDER[1]);
  Serial.print(",");
  Serial.println(PARTICIPATION_ORDER[2]);
  Serial.print("join delay ticks:");
  Serial.println(JOIN_DELAY_TICKS);
  Serial.print("target count:");
  Serial.println(TARGET_COUNT);
}
