#include <Wire.h>

#define SLAVE_ADDRESS 10

int pinLed = 9;
volatile int x = HIGH;
volatile bool received = false;
unsigned long lastBlinkTime = 0;
bool builtInLedState = LOW;

void setup(){
    Wire.begin(SLAVE_ADDRESS);
    Wire.onReceive(receiveEvent);
    pinMode(pinLed, OUTPUT);
    pinMode(LED_BUILTIN, OUTPUT);

    digitalWrite(pinLed, HIGH);
    delay(300);
    digitalWrite(pinLed, LOW);
}

void loop(){
    if (millis() - lastBlinkTime >= 500){
        lastBlinkTime = millis();
        builtInLedState = !builtInLedState;
        digitalWrite(LED_BUILTIN, builtInLedState);
    }

    if (received){
        received = false;

        if (x == HIGH){
            digitalWrite(pinLed, LOW);
        }else{
            digitalWrite(pinLed, HIGH);
        }
    }

    delay(100);
}

void receiveEvent(int howMany){
    if (Wire.available() > 0){
        x = Wire.read();
        received = true;
    }
}
