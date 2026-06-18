#include <Wire.h>

// =====================================================
// Instrument settings: edit this section for each child
// =====================================================
const byte INSTRUMENT_ID = 2;
const char INSTRUMENT_NAME[] = "guitar";
const byte SLAVE_ADDRESS = 9;
const byte LED_PIN = 8;
// =====================================================

const byte TICKS_PER_BEAT = 4;
const byte JOIN_DELAY_TICKS = 16;
const byte SCORE_LENGTH_TICKS = 80;

struct NoteEvent {
  const char* note;
  byte durationTicks;
  byte volume;
};

NoteEvent score[] = {
  {"F4", 1, 90}, {"REST", 1, 0},
  {"G4", 1, 90}, {"REST", 1, 0},
  {"A4", 1, 92}, {"REST", 1, 0},
  {"Bb4", 1, 92}, {"REST", 1, 0},
  {"A4", 1, 92}, {"REST", 1, 0},
  {"G4", 1, 90}, {"REST", 1, 0},
  {"F4", 3, 90}, {"REST", 1, 0},

  {"A4", 1, 92}, {"REST", 1, 0},
  {"Bb4", 1, 92}, {"REST", 1, 0},
  {"C5", 1, 95}, {"REST", 1, 0},
  {"D5", 1, 100}, {"REST", 1, 0},
  {"C5", 1, 95}, {"REST", 1, 0},
  {"Bb4", 1, 92}, {"REST", 1, 0},
  {"A4", 2, 92}, {"REST", 2, 0},

  {"F4", 2, 90}, {"REST", 2, 0},
  {"F4", 2, 90}, {"REST", 2, 0},
  {"F4", 2, 90}, {"REST", 2, 0},
  {"F4", 2, 90}, {"REST", 2, 0},

  {"F4", 1, 90},
  {"F4", 1, 90},
  {"G4", 1, 90},
  {"G4", 1, 90},
  {"A4", 1, 92},
  {"A4", 1, 92},
  {"Bb4", 1, 95},
  {"Bb4", 1, 95},
  {"A4", 1, 92}, {"REST", 1, 0},
  {"G4", 1, 90}, {"REST", 1, 0},
  {"F4", 2, 90},

  {"REST", 18, 0}
};

const byte SCORE_EVENT_COUNT = sizeof(score) / sizeof(score[0]);

volatile byte packetTickNumber = 0;
volatile byte packetBPM = 0;
volatile byte packetOrder[3] = {0, 0, 0};
volatile byte packetDrumStartTrigger = 0;
volatile bool packetReceived = false;

void setup() {
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
  Serial.begin(115200);

  pinMode(LED_PIN, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
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
  if (packetBPM < 40 || packetBPM > 240) {
    return false;
  }

  return getParticipationIndex() >= 0;
}

void playCurrentNote() {
  int localTick = getLocalTick();
  if (localTick < 1 || localTick > SCORE_LENGTH_TICKS) {
    stop();
    return;
  }

  int eventIndex = getEventStartingAtTick(localTick);
  if (eventIndex < 0) {
    return;
  }

  NoteEvent current = score[eventIndex];
  if (strcmp(current.note, "REST") == 0) {
    stop();
    return;
  }

  turnOn();
  sendPerformanceData(current, localTick);
}

void stop() {
  turnOff();
}

void turnOn() {
  digitalWrite(LED_PIN, HIGH);
}

void turnOff() {
  digitalWrite(LED_PIN, LOW);
}

int getParticipationIndex() {
  for (byte i = 0; i < 3; i++) {
    if (packetOrder[i] == INSTRUMENT_ID) {
      return i;
    }
  }
  return -1;
}

int getLocalTick() {
  int participationIndex = getParticipationIndex();
  if (participationIndex < 0) {
    return -1;
  }

  return packetTickNumber - participationIndex * JOIN_DELAY_TICKS;
}

int getEventStartingAtTick(int localTick) {
  int eventStartTick = 1;

  for (byte i = 0; i < SCORE_EVENT_COUNT; i++) {
    if (eventStartTick == localTick) {
      return i;
    }
    eventStartTick += score[i].durationTicks;
  }

  return -1;
}

float getNoteLengthSeconds(byte durationTicks) {
  float secondsPerTick = 60.0f / packetBPM / TICKS_PER_BEAT;
  return secondsPerTick * durationTicks * 0.90f;
}

String formatData(NoteEvent noteEvent, int localTick) {
  String data = "PERF,";
  data += INSTRUMENT_ID;
  data += ",";
  data += INSTRUMENT_NAME;
  data += ",";
  data += noteEvent.note;
  data += ",";
  data += String(getNoteLengthSeconds(noteEvent.durationTicks), 3);
  data += ",";
  data += String(noteEvent.volume / 100.0f, 2);
  data += ",";
  data += localTick;
  data += ",";
  data += packetBPM;
  return data;
}

bool sendPerformanceData(NoteEvent noteEvent, int localTick) {
  Serial.println(formatData(noteEvent, localTick));
  return true;
}

void receiveEvent(int howMany) {
  if (Wire.available() >= 6) {
    packetTickNumber = Wire.read();
    packetBPM = Wire.read();
    packetOrder[0] = Wire.read();
    packetOrder[1] = Wire.read();
    packetOrder[2] = Wire.read();
    packetDrumStartTrigger = Wire.read();
    packetReceived = true;
  }

  while (Wire.available() > 0) {
    Wire.read();
  }
}
