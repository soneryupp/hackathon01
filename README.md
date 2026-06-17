# Hackathon01 Guitar Performance System

Processing + Arduinoで作成しているArduinoオーケストラ/ギター演奏システムです。

親機Arduinoが演奏情報や同期情報を処理し、I2Cで子機Arduinoへ送信します。子機Arduinoは受け取った情報に応じてLEDを制御し、必要に応じてUSBシリアル通信でProcessingへ演奏データを送ります。Processing側ではMinimを使って楽器音を鳴らします。

## Directory Structure

```text
arduino/
  i2c_tests/
    2026-06-10/          # 親機1台・子機2台の初期I2Cテスト
    2026-06-13/          # 親機1台・子機4台のI2Cテスト
    2026-06-16/          # 開始スイッチ1個で4台のLEDを順番点灯
    scanners/            # I2Cアドレス確認用スキャナ
    sync_packet_test/    # 設計書準拠の3バイト同期パケットテスト

processing/
  audio_main/                  # 設計書準拠の4楽器音源
  guitar_serial/               # Arduino連携ギター音源
  guitar_standalone_2026-06-09/ # Arduinoなしのギター単体版
```

## Arduino I2C Tests

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

## Sketches

### 2026-06-10

初期の2台構成テストです。

```text
arduino/i2c_tests/2026-06-10/hck_00_2026-06-10_m/
arduino/i2c_tests/2026-06-10/hck_00_2026-06-10_s1/
arduino/i2c_tests/2026-06-10/hck_00_2026-06-10_s2/
```

### 2026-06-13

4台構成の基本I2Cテストです。

```text
arduino/i2c_tests/2026-06-13/hck_00_2026-06-13_m/
arduino/i2c_tests/2026-06-13/hck_00_2026-06-13_s1/
arduino/i2c_tests/2026-06-13/hck_00_2026-06-13_s2/
arduino/i2c_tests/2026-06-13/hck_00_2026-06-13_s3/
arduino/i2c_tests/2026-06-13/hck_00_2026-06-13_s4/
```

### 2026-06-16

開始スイッチ1個で全子機と通信し、LEDを子機1から子機4まで順に点灯するテストです。

```text
arduino/i2c_tests/2026-06-16/hck_00_2026-06-16_m/
arduino/i2c_tests/2026-06-16/hck_00_2026-06-16_s1/
arduino/i2c_tests/2026-06-16/hck_00_2026-06-16_s2/
arduino/i2c_tests/2026-06-16/hck_00_2026-06-16_s3/
arduino/i2c_tests/2026-06-16/hck_00_2026-06-16_s4/
```

親機の開始スイッチ:

```text
13番ピン <-> タクトスイッチ <-> GND
```

### Sync Packet Test

設計書と先輩からの助言に合わせた同期通信テストです。

```text
arduino/i2c_tests/sync_packet_test/hck_00_test_m/
arduino/i2c_tests/sync_packet_test/hck_00_test_s1/
arduino/i2c_tests/sync_packet_test/hck_00_test_s2/
arduino/i2c_tests/sync_packet_test/hck_00_test_s3/
arduino/i2c_tests/sync_packet_test/hck_00_test_s4/
```

親機から子機へ送る3バイト同期パケット:

```text
1バイト目 = 拍番号
2バイト目 = BPM
3バイト目 = 対象子機ID
```

主な関数:

```text
startSync()
update()
sendSyncPacket()
receiveSyncPacket()
checkPacket()
formatData()
sendPerformanceData()
```

親機スイッチ:

```text
開始/停止 = 13番ピン
BPM上昇 = 4番ピン
BPM下降 = 5番ピン
```

## I2C Scanners

```text
arduino/i2c_tests/scanners/i2c_scanner_2026-06-10/
arduino/i2c_tests/scanners/i2c_scanner_2026-06-14/
```

4台構成では `i2c_scanner_2026-06-14` を使います。期待する結果:

```text
address 8: found
address 9: found
address 10: found
address 11: found
```

## Processing

### audio_main

設計書準拠の4楽器音源です。

```text
processing/audio_main/audio_main.pde
processing/audio_main/ProcessingAudioManager.pde
processing/audio_main/InstrumentSound.pde
processing/audio_main/PianoSound.pde
processing/audio_main/GuitarSound.pde
processing/audio_main/FluteSound.pde
processing/audio_main/DrumSound.pde
```

子機からProcessingへ送る形式:

```text
PERF,楽器ID,楽器名,音階,長さ,音量,拍番号,BPM
```

例:

```text
PERF,2,guitar,E4,0.35,0.75,2,90
```

### guitar_serial

Arduino連携版のギター音源です。

```text
processing/guitar_serial/guitar_serial.pde
```

受信形式:

```text
NOTE,音の高さ,強さ,長さ,タイミング
```

例:

```text
NOTE,C4,0.7,0.9,0.0
NOTE,440,700,1.0,0.5
```

### guitar_standalone_2026-06-09

Arduinoなしで音を確認するための単体版です。

```text
processing/guitar_standalone_2026-06-09/guitar_standalone_2026-06-09.pde
```

- `1`〜`6`: 弦の音を鳴らす
- `p`: カエルの歌を演奏する

## I2C Pull-up Resistors

I2CのSDA/SCLにはプルアップ抵抗が必要です。3.3kΩまたは4.7kΩを使います。

```text
A4(SDA) -> 3.3kΩ or 4.7kΩ -> 5V
A5(SCL) -> 3.3kΩ or 4.7kΩ -> 5V
```

プルアップ抵抗はI2Cバス全体で1組、つまりSDA用1本とSCL用1本で十分です。
