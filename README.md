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
    2026-06-17/          # ギター子機1台の演奏テスト
    2026-06-18/          # チーム共通楽譜に合わせたギター演奏テスト
    scanners/            # I2Cアドレス確認用スキャナ
    sync_packet_test/    # 設計書準拠の3バイト同期パケットテスト

processing/
  instruments/
    piano/                     # ピアノ専用音源
    guitar/                    # ギター専用音源
    flute/                     # フルート専用音源
    drum/                      # ドラム専用音源
  templates/
    tone_instrument_2026_06_18/ # 音程楽器共通テンプレート
  audio_main/                  # 4楽器統合版（過去の結合テスト用）
  guitar_serial/               # Arduino連携ギター音源
  guitar_standalone_2026_06_09/ # Arduinoなしのギター単体版
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

### 2026-06-17 Guitar Single Test

親機の開始スイッチを押すと、ギター子機1台へ同期パケットを送り、子機側の楽譜配列に従ってProcessingへ演奏データを送るテストです。

```text
arduino/i2c_tests/2026-06-17/hck_00_2026-06-17_m/
arduino/i2c_tests/2026-06-17/hck_00_2026-06-17_guitar/
```

親機からギター子機へ送る4項目:

```text
1項目目 = 拍番号
2項目目 = BPM
3項目目 = 3楽器の参加順情報
4項目目 = ドラム演奏開始トリガー
```

今回のギター単体テストでは以下の固定値を使います。

```text
3楽器の参加順情報 = 1
ドラム演奏開始トリガー = 0
```

親機スイッチ:

```text
開始/停止 = 13番ピン
BPM上昇 = 4番ピン
BPM下降 = 5番ピン
```

ギター子機:

```text
I2Cアドレス = 9
LED = 8番ピン
```

子機は受信したBPMから音の長さを毎回計算するため、演奏途中でBPMが変わった場合も次のパケットから追従します。

このテストで使用するProcessingスケッチ:

```text
processing/instruments/guitar/guitar.pde
```

### 2026-06-18 Unified Score Test

チームメンバーのフルート楽譜と、音階・休符・音価・音量・曲全体の長さを統一したギター演奏テストです。

```text
arduino/i2c_tests/2026-06-18/hck_00_2026-06-18_m/
arduino/i2c_tests/2026-06-18/hck_00_2026-06-18_guitar/
```

楽譜は次の構造で管理します。

```cpp
struct NoteEvent {
  const char* note;
  byte durationTicks;
  byte volume;
};
```

1拍を4tickに分割し、全体は80tickです。親機は同期番号を1tickごとに送信し、子機はその番号と楽譜イベントの開始位置を照合して音を出します。

```text
初期BPM = 76
1拍 = 4tick
全体 = 80tick = 20拍
```

BPMは同期パケットごとに受信し、音の長さを次の式で毎回計算します。

```text
音の長さ = 60 / BPM / 4 × durationTicks
```

使用するProcessingスケッチ:

```text
processing/instruments/guitar/guitar.pde
```

### 2026-06-18 Configurable Test

BPM変更処理を省略し、テスト条件をプログラム冒頭で設定する版です。

```text
arduino/i2c_tests/2026-06-18/hck_00_2026-06-18_config_test_m/
arduino/i2c_tests/2026-06-18/hck_00_2026-06-18_config_test_tone/
processing/templates/tone_instrument_2026_06_18/
```

親機では次の設定だけを変更します。

```cpp
const byte TEST_BPM = 76;

const byte PARTICIPATION_ORDER[3] = {
  PIANO_ID,
  GUITAR_ID,
  FLUTE_ID
};

const byte TARGET_ADDRESSES[] = {9};
const byte JOIN_DELAY_TICKS = 16;
```

ギター1台だけのテストでは送信先を `{9}` にします。3台接続時は次のように変更します。

```cpp
const byte TARGET_ADDRESSES[] = {8, 9, 10};
```

同期パケットは6バイトです。

```text
1バイト目 = 同期tick番号
2バイト目 = BPM
3バイト目 = 参加順1
4バイト目 = 参加順2
5バイト目 = 参加順3
6バイト目 = ドラム開始フラグ（今回は0）
```

音程楽器用子機では、冒頭の設定だけを各Arduinoに合わせます。

```cpp
const byte INSTRUMENT_ID = 2;
const char INSTRUMENT_NAME[] = "guitar";
const byte SLAVE_ADDRESS = 9;
const byte LED_PIN = 8;
```

音程楽器用Processingは共通です。

```text
processing/templates/tone_instrument_2026_06_18/tone_instrument_2026_06_18.pde
```

主に以下を変更して音色を作ります。

```java
final int INSTRUMENT_ID = 2;
final String INSTRUMENT_NAME = "guitar";
final float[] HARMONICS = { ... };
final float OUTPUT_GAIN = 0.80f;
final float ATTACK_GAIN = 0.35f;
final float NOISE_GAIN = 0.18f;
```

ピアノ、ギター、フルートは同じプログラム構造を利用し、倍音構造などの設定だけを変更します。ドラムはノイズ主体の打撃音になるため、別プログラムとして扱います。

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

### Instrument-specific sketches

各楽器は独立したProcessingプログラムで動作します。各PDEは、自分の楽器IDと楽器名に一致する `PERF` データだけを再生します。

```text
processing/instruments/piano/piano.pde     # ID 1 / piano
processing/instruments/guitar/guitar.pde   # ID 2 / guitar
processing/instruments/flute/flute.pde     # ID 3 / flute
processing/instruments/drum/drum.pde       # ID 4 / drum
```

共通受信形式:

```text
PERF,楽器ID,楽器名,音階またはドラム種類,長さ,音量,拍番号,BPM
```

各スケッチでスペースキーを押すと、Arduinoなしで対応楽器の音を確認できます。`0`〜`9` キーでシリアルポートを切り替えます。

### audio_main (legacy)

4楽器を1つのプログラムで再生する過去の結合テスト用です。現在の構成では、通常は各楽器専用PDEを使用します。

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

### guitar_standalone_2026_06_09

Arduinoなしで音を確認するための単体版です。

```text
processing/guitar_standalone_2026_06_09/guitar_standalone_2026_06_09.pde
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
