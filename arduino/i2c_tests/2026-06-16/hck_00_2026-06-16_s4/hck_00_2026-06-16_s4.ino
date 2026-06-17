#include <Wire.h>

#define SLAVE_ADDRESS 11

const byte ledPin = 10;
volatile byte receivedCommand = 0;
volatile bool received = false;

void setup() {
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
  pinMode(ledPin, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(ledPin, LOW);
}

void loop() {
  digitalWrite(LED_BUILTIN, millis() / 500 % 2);

  if (received) {
    received = false;
    digitalWrite(ledPin, receivedCommand == 1 ? HIGH : LOW);
  }
}

void receiveEvent(int howMany) {
  if (Wire.available() > 0) {
    receivedCommand = Wire.read();
    received = true;
  }
}
