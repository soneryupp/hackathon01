#include <Wire.h>

#define SLAVE1_ADDRESS 8
#define SLAVE2_ADDRESS 9

int pushButton_0 = 13;
int pushButton_1 = 4;
int x_0 = 0;
int x_1 = 0;

void setup(){
    Wire.begin();
    Wire.setClock(10000);
    Serial.begin(9600);
    pinMode(pushButton_0,INPUT_PULLUP);
    pinMode(pushButton_1,INPUT_PULLUP);
}

void loop(){
    Wire.beginTransmission(SLAVE1_ADDRESS);
    x_0 = digitalRead(pushButton_0);
    Wire.write(x_0);
    int result0 = Wire.endTransmission();
    
    Wire.beginTransmission(SLAVE2_ADDRESS);
    x_1 = digitalRead(pushButton_1);
    Wire.write(x_1);
    int result1 = Wire.endTransmission();

    Serial.print("button0:");
    Serial.print(x_0);
    Serial.print(" slave1:");
    Serial.print(result0);
    Serial.print(" button1:");
    Serial.print(x_1);
    Serial.print(" slave2:");
    Serial.println(result1);

    delay(100);
}
