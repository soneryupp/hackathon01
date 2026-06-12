#include <Wire.h>

#define SLAVE_COUNT 4

const byte slaveAddresses[SLAVE_COUNT] = {8, 9, 10, 11};
const byte pushButtons[SLAVE_COUNT] = {13, 4, 5, 6};

int buttonStates[SLAVE_COUNT] = {HIGH, HIGH, HIGH, HIGH};
int sendResults[SLAVE_COUNT] = {0, 0, 0, 0};

void setup(){
    Wire.begin();
    Wire.setClock(10000);
    Serial.begin(9600);

    for (int i = 0; i < SLAVE_COUNT; i++){
        pinMode(pushButtons[i], INPUT_PULLUP);
    }
}

void loop(){
    for (int i = 0; i < SLAVE_COUNT; i++){
        buttonStates[i] = digitalRead(pushButtons[i]);

        Wire.beginTransmission(slaveAddresses[i]);
        Wire.write(buttonStates[i]);
        sendResults[i] = Wire.endTransmission();
    }

    for (int i = 0; i < SLAVE_COUNT; i++){
        Serial.print("button");
        Serial.print(i + 1);
        Serial.print(":");
        Serial.print(buttonStates[i]);
        Serial.print(" slave");
        Serial.print(slaveAddresses[i]);
        Serial.print(":");
        Serial.print(sendResults[i]);

        if (i < SLAVE_COUNT - 1){
            Serial.print(" ");
        }else{
            Serial.println();
        }
    }

    delay(100);
}
