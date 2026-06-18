#include <Wire.h>

#define SLAVE_ADDRESS 9
#define INSTRUMENT_ID 2

const byte ledPin = 8;
const char instrumentName[] = "guitar";
const byte ticksPerBeat = 4;

struct NoteEvent {
  const char* note;
  byte durationTicks;
  byte volume;
};

NoteEvent guitarScore[] = {
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

const byte scoreEventCount = sizeof(guitarScore) / sizeof(guitarScore[0]);
const byte scoreLengthTicks = 80;

volatile byte packetTickNumber = 0;
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
  if (packetTickNumber < 1 || packetTickNumber > scoreLengthTicks) {
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
  int eventIndex = getEventStartingAtTick(packetTickNumber);
  if (eventIndex < 0) {
    return;
  }

  NoteEvent current = guitarScore[eventIndex];
  if (strcmp(current.note, "REST") == 0) {
    stop();
    return;
  }

  turnOn();
  sendPerformanceData(current);
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

int getEventStartingAtTick(byte tickNumber) {
  int eventStartTick = 1;

  for (byte i = 0; i < scoreEventCount; i++) {
    if (eventStartTick == tickNumber) {
      return i;
    }
    eventStartTick += guitarScore[i].durationTicks;
  }

  return -1;
}

float getNoteLengthSeconds(byte durationTicks) {
  float secondsPerTick = 60.0f / packetBPM / ticksPerBeat;
  return secondsPerTick * durationTicks * 0.90f;
}

String formatData(NoteEvent noteEvent) {
  String data = "PERF,";
  data += INSTRUMENT_ID;
  data += ",";
  data += instrumentName;
  data += ",";
  data += noteEvent.note;
  data += ",";
  data += String(getNoteLengthSeconds(noteEvent.durationTicks), 3);
  data += ",";
  data += String(noteEvent.volume / 100.0f, 2);
  data += ",";
  data += packetTickNumber;
  data += ",";
  data += packetBPM;
  return data;
}

bool sendPerformanceData(NoteEvent noteEvent) {
  Serial.println(formatData(noteEvent));
  return true;
}

void receiveEvent(int howMany) {
  if (Wire.available() >= 4) {
    packetTickNumber = Wire.read();
    packetBPM = Wire.read();
    packetJoinOrderInfo = Wire.read();
    packetDrumStartTrigger = Wire.read();
    packetReceived = true;
  }

  while (Wire.available() > 0) {
    Wire.read();
  }
}
