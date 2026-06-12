# Hackathon01 Guitar Performance System

Processing + Arduinoで作成しているギター演奏システムです。

最終構成は、親機Arduinoが演奏情報を処理し、I2Cで子機Arduinoへ送信します。子機Arduinoは受け取った演奏情報をUSBシリアル通信でProcessingへ送り、Processing側でギター音を鳴らします。

## フォルダ構成

```text
processing/
  guiter/
    guiter.pde
  guiter_standalone_2026-06-09/
    guiter_standalone_2026-06-09.pde

arduino/
  I2C通信テスト/
    hck_00_2026-06-10_m/
    hck_00_2026-06-10_s1/
    hck_00_2026-06-10_s2/
    i2c_scanner_2026-06-10/
```

## Processing

`processing/guiter/guiter.pde` はArduino連携版です。Minimライブラリを使ってギター音を生成します。

受信形式:

```text
NOTE,音の高さ,強さ,長さ,タイミング
```

例:

```text
NOTE,C4,0.7,0.9,0.0
NOTE,440,700,1.0,0.5
```

音の高さは `C4` のような音名、または `440` のような周波数で指定できます。

シリアルポートを固定したい場合は、Processing側の以下を書き換えます。

```java
String fixedPortName = "";
```

例:

```java
String fixedPortName = "/dev/cu.usbmodem1101";
```

空文字のままなら、`usbmodem` または `usbserial` を含むポートを自動で探します。

## Processing単体版

`processing/guiter_standalone_2026-06-09/guiter_standalone_2026-06-09.pde` はArduinoなしで音を確認するための単体版です。

- `1`〜`6`: 弦の音を鳴らす
- `p`: カエルの歌を演奏する

## Arduino I2Cテスト

`arduino/I2C通信テスト/` に、I2C通信テスト用のArduinoコードを入れています。

- `hck_00_2026-06-10_m`, `s1`, `s2`: 親機1台・子機2台の初期テスト
- `hck_00_2026-06-13_m`, `s1`〜`s4`: 親機1台・子機4台のテスト
- `i2c_scanner_2026-06-10`: I2Cアドレス確認用スキャナ

Arduino UnoのI2Cピン:

```text
A4 = SDA
A5 = SCL
```

4台テスト時の基本配線:

```text
親機 5V  -> 子機1 5V -> 子機2 5V -> 子機3 5V -> 子機4 5V
親機 GND -> 子機1 GND -> 子機2 GND -> 子機3 GND -> 子機4 GND
親機 A4  -> 子機1 A4 -> 子機2 A4 -> 子機3 A4 -> 子機4 A4
親機 A5  -> 子機1 A5 -> 子機2 A5 -> 子機3 A5 -> 子機4 A5
```

子機アドレス:

```text
子機1 = 8
子機2 = 9
子機3 = 10
子機4 = 11
```

親機のスイッチピン:

```text
子機1用 = 13
子機2用 = 4
子機3用 = 5
子機4用 = 6
```

## I2Cプルアップ抵抗

I2CのSDA/SCLにはプルアップ抵抗が必要です。

理想:

```text
A4(SDA) -> 4.7kΩ -> 5V
A5(SCL) -> 4.7kΩ -> 5V
```

手元に33kΩしかない場合でも、短い配線なら試せます。

```text
A4(SDA) -> 33kΩ -> 5V
A5(SCL) -> 33kΩ -> 5V
```

## 今後の方針

I2Cで複数の配列をまとめて送るより、1音ずつ以下の形式で送る方針が安全です。Arduino UnoのWireライブラリは1回あたり32バイト程度が目安です。

```text
pitch,strength,length,timing
```

例:

```text
60,70,90,0
C4,70,90,0
```

子機Arduinoは、親機から受け取った文字列の先頭に `NOTE,` を付けてProcessingへ送る想定です。
