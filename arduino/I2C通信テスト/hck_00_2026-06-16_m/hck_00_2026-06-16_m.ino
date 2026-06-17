#include <Wire.h>

#define SLAVE_COUNT 4

const byte startSwitchPin = 13;
const byte slaveAddresses[SLAVE_COUNT] = {8, 9, 10, 11};
const unsigned long lightIntervalMs = 500;

bool running = false;
bool lastStartSwitchState = HIGH;
byte activeIndex = 0;
unsigned long lastStepTime = 0;

void setup() {
  Wire.begin();
  Wire.setClock(10000);
  Serial.begin(9600);
  pinMode(startSwitchPin, INPUT_PULLUP);
  sendCommandToAll(0);
  Serial.println("hck_00_2026-06-16 master start");
}

void loop() {
  bool currentStartSwitchState = digitalRead(startSwitchPin);

  if (lastStartSwitchState == HIGH && currentStartSwitchState == LOW) {
    startSequence();
  }
  lastStartSwitchState = currentStartSwitchState;

  if (!running) {
    delay(20);
    return;
  }

  if (millis() - lastStepTime >= lightIntervalMs) {
    lastStepTime = millis();
    activeIndex = (activeIndex + 1) % SLAVE_COUNT;
    sendActiveSlave(activeIndex);
  }
}

void startSequence() {
  running = true;
  activeIndex = 0;
  lastStepTime = millis();
  Serial.println("start switch pressed");
  sendActiveSlave(activeIndex);
}

void sendActiveSlave(byte index) {
  for (byte i = 0; i < SLAVE_COUNT; i++) {
    byte command = (i == index) ? 1 : 0;
    bool result = sendLedCommand(slaveAddresses[i], command);

    Serial.print("slave");
    Serial.print(slaveAddresses[i]);
    Serial.print(":");
    Serial.print(result ? "ok" : "ng");
    Serial.print(" ");
  }

  Serial.print("active:");
  Serial.println(index + 1);
}

void sendCommandToAll(byte command) {
  for (byte i = 0; i < SLAVE_COUNT; i++) {
    sendLedCommand(slaveAddresses[i], command);
  }
}

bool sendLedCommand(byte address, byte command) {
  Wire.beginTransmission(address);
  Wire.write(command);
  return Wire.endTransmission() == 0;
}
