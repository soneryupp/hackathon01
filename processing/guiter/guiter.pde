import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Waveform currentWaveform;

Serial port;

// Processingの画面に表示されるポート番号を見て変更できます
int serialPortIndex = -1;
int serialBaud = 115200;
String[] serialPorts;

// 事前にポートを決める場合はここに書く
// 例: String fixedPortName = "/dev/cu.usbmodem1101";
// 空文字のままなら自動でArduinoっぽいポートを探す
String fixedPortName = "";

String lastMessage = "";
String lastNote = "";
float lastStrength = 0;
float lastLength = 0;
float lastTiming = 0;
int receiveCount = 0;

// ギターの音を作るためにInstrumentインタフェースを実装する
class GuitarInstrument implements Instrument
{
  Oscil wave;
  Oscil attackWave;
  Noise pickNoise;
  Line ampEnv;
  Line attackEnv;
  Line noiseEnv;
  float maxAmp;

  GuitarInstrument(float frequency, float maxAmp, Waveform wf)
  {
    // メインの弦の音
    wave = new Oscil(frequency, 0, wf);

    // 弾いた瞬間の高い成分
    attackWave = new Oscil(frequency * 10, 0, Waves.SAW);

    // ピックが弦に当たるノイズ
    pickNoise = new Noise(0);

    this.maxAmp = maxAmp;

    ampEnv = new Line();
    ampEnv.patch(wave.amplitude);

    attackEnv = new Line();
    attackEnv.patch(attackWave.amplitude);

    noiseEnv = new Line();
    noiseEnv.patch(pickNoise.amplitude);
  }

  void noteOn(float duration)
  {
    // 弦の本体音
    ampEnv.activate(duration, this.maxAmp, 0);

    // 弾いた瞬間の高い成分
    attackEnv.activate(0.06f, this.maxAmp * 0.35f, 0);

    // ピックノイズ。一瞬だけ鳴らす
    noiseEnv.activate(0.015f, this.maxAmp * 0.18f, 0);

    wave.patch(out);
    attackWave.patch(out);
    pickNoise.patch(out);
  }

  void noteOff()
  {
    wave.unpatch(out);
    attackWave.unpatch(out);
    pickNoise.unpatch(out);
  }
}

void setup()
{
  size(800, 400);
  pixelDensity(1);

  // minimのインスタンスを用意
  minim = new Minim(this);

  // minimのgetLineOutメソッドを呼び出し，AudioOutputオブジェクトを受け取る
  out = minim.getLineOut();

  // テンポの設定，BPM=120
  out.setTempo(120);

  // ギターっぽくするため，倍音を含んだ音色を作る
  currentWaveform = WavetableGenerator.gen10(
    4096,
    new float[] {
      1.50f, 1.00f, 0.50f, 0.37f, 0.15f,
      0.13f, 0.12f, 0.08f, 0.04f, 0.02f
    }
  );

  // 使用できるシリアルポートを表示
  serialPorts = Serial.list();
  println(serialPorts);

  serialPortIndex = findArduinoPort();
  openSerialPort(serialPortIndex);
}

void draw()
{
  background(0);
  stroke(255);

  // 左チャンネルと右チャンネルに入っている波形を描画
  for (int i = 0; i < out.bufferSize() - 1; i++)
  {
    line(i, 100 - out.left.get(i)*80, i+1, 100 - out.left.get(i+1)*80);
    line(i, 300 - out.right.get(i)*80, i+1, 300 - out.right.get(i+1)*80);
  }

  fill(255);
  textSize(16);
  text("last message: " + lastMessage, 20, 30);
  text("note: " + lastNote, 20, 55);
  text("strength: " + nf(lastStrength, 1, 2), 20, 80);
  text("length: " + nf(lastLength, 1, 2), 20, 105);
  text("timing: " + nf(lastTiming, 1, 2), 20, 130);
  text("received notes: " + receiveCount, 20, 155);
  text("press p: request Kaeru no Uta from Arduino", 20, 180);
  text("serial port index: " + serialPortIndex, 20, 205);
  text("fixed port: " + fixedPortName, 20, 230);
  text("press 0-9: change serial port", 20, 255);

  if (serialPorts != null)
  {
    for (int i = 0; i < serialPorts.length && i < 10; i++)
    {
      text(i + ": " + serialPorts[i], 20, 285 + i * 18);
    }
  }
}

void serialEvent(Serial p)
{
  String message = p.readStringUntil('\n');

  if (message == null)
  {
    return;
  }

  message = trim(message);
  if (message.length() == 0)
  {
    return;
  }

  lastMessage = message;
  receiveNote(message);
}

void receiveNote(String message)
{
  // 受信形式: NOTE,音の高さ,強さ,長さ,タイミング
  // 例: NOTE,C4,0.8,1.2,0.0
  // 例: NOTE,440,700,1.0,0.5
  String[] data = splitTokens(message, ", ");

  if (data.length < 5)
  {
    return;
  }

  if (!data[0].equals("NOTE"))
  {
    return;
  }

  String pitchText = data[1];
  float frequency = getFrequency(pitchText);
  float strength = parseFloat(data[2]);
  float length = parseFloat(data[3]);
  float timing = parseFloat(data[4]);

  if (Float.isNaN(frequency) || Float.isNaN(strength) ||
      Float.isNaN(length) || Float.isNaN(timing))
  {
    return;
  }

  playGuitar(frequency, strength, length, timing);

  lastNote = pitchText + " / " + nf(frequency, 1, 2) + "Hz";
  lastStrength = strength;
  lastLength = length;
  lastTiming = timing;
  receiveCount++;

  println("receive note " + receiveCount + ": " + message);
}

void playGuitar(float frequency, float strength, float length, float timing)
{
  // 強さが0〜1023で来た場合は0〜1に変換する
  float amp = strength;
  if (amp > 1.0f)
  {
    amp = amp / 1023.0f;
  }

  amp = constrain(amp, 0.05f, 1.0f);
  length = max(length, 0.05f);
  timing = max(timing, 0);

  out.playNote(
    timing,
    length,
    new GuitarInstrument(
      frequency,
      amp,
      currentWaveform
    )
  );
}

float getFrequency(String pitchText)
{
  float value = parseFloat(pitchText);

  // 数字で送られてきた場合はHzとして使う
  if (!Float.isNaN(value))
  {
    return value;
  }

  // C4, D#4, Bb3 のような音名で送られてきた場合
  return Frequency.ofPitch(pitchText).asHz();
}

void keyPressed()
{
  // p: Arduinoへテスト曲を依頼
  // 0-9: シリアルポートを切り替え
  // a/s/d/f: 通信なしで音を確認するためのテスト
  switch(key)
  {
  case 'p':
    requestTestSong();
    break;

  case 'a':
    playGuitar(Frequency.ofPitch("C4").asHz(), 0.7f, 1.2f, 0.0f);
    break;

  case 's':
    playGuitar(Frequency.ofPitch("D4").asHz(), 0.7f, 1.2f, 0.0f);
    break;

  case 'd':
    playGuitar(Frequency.ofPitch("E4").asHz(), 0.7f, 1.2f, 0.0f);
    break;

  case 'f':
    playGuitar(Frequency.ofPitch("F4").asHz(), 0.7f, 1.2f, 0.0f);
    break;

  default:
    if (key >= '0' && key <= '9')
    {
      openSerialPort(key - '0');
    }
    break;
  }
}

void requestTestSong()
{
  if (port != null)
  {
    receiveCount = 0;
    port.write('p');
    lastMessage = "request test song";
  }
  else
  {
    lastMessage = "serial port is not open";
  }
}

int findArduinoPort()
{
  if (fixedPortName.length() > 0)
  {
    for (int i = 0; i < serialPorts.length; i++)
    {
      if (serialPorts[i].equals(fixedPortName))
      {
        return i;
      }
    }

    lastMessage = "fixed port not found: " + fixedPortName;
    return -1;
  }

  for (int i = 0; i < serialPorts.length; i++)
  {
    String name = serialPorts[i].toLowerCase();

    if (name.indexOf("usbmodem") >= 0 || name.indexOf("usbserial") >= 0)
    {
      return i;
    }
  }

  if (serialPorts.length > 0)
  {
    return 0;
  }

  return -1;
}

void openSerialPort(int index)
{
  if (port != null)
  {
    port.stop();
    port = null;
  }

  serialPorts = Serial.list();
  println(serialPorts);

  if (index < 0 || index >= serialPorts.length)
  {
    serialPortIndex = index;
    lastMessage = "serial port not found";
    return;
  }

  serialPortIndex = index;
  String portName = serialPorts[serialPortIndex];
  port = new Serial(this, portName, serialBaud);
  port.bufferUntil('\n');
  port.clear();
  lastMessage = "serial open: " + portName;
}
