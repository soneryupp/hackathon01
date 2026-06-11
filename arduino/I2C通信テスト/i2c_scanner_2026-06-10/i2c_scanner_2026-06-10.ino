#include <Wire.h>

void setup() {
  Serial.begin(9600);

  while (!Serial) {
  }

  Serial.println("I2C scanner start");
}

void loop() {
  pinMode(A4, INPUT_PULLUP);
  pinMode(A5, INPUT_PULLUP);

  int sdaState = digitalRead(A4);
  int sclState = digitalRead(A5);

  Serial.print("SDA(A4): ");
  Serial.print(sdaState);
  Serial.print(" SCL(A5): ");
  Serial.println(sclState);

  if (sdaState == LOW || sclState == LOW) {
    Serial.println("SDA or SCL is LOW. Check wiring before scanning.");
    Serial.println();
    delay(2000);
    return;
  }

  Wire.begin();
  Wire.setClock(10000);

  Serial.println("scanning address 8 and 9...");

  scanAddress(8);
  scanAddress(9);

  Serial.println();
  delay(2000);
}

void scanAddress(byte address) {
  Wire.beginTransmission(address);
  byte error = Wire.endTransmission();

  Serial.print("address ");
  Serial.print(address);
  Serial.print(": ");

  if (error == 0) {
    Serial.println("found");
  } else {
    Serial.print("not found / error ");
    Serial.println(error);
  }
}
