import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Waveform currentWaveform; // 音色格納用変数

// ギターの6本弦の音
String[] guitarStrings = {
  "C2", "D2", "E2", "F2", "G2", "A2"
};

// 各弦の音量
float[] volume = {
  0.8f, 0.8f, 0.8f, 0.8f, 0.8f, 0.8f
};

float[] noteLength = {
  2.4f, 2.2f, 2.0f, 1.8f, 1.6f, 1.4f
};

// カエルの歌のメロディ
String[] melody = {
  "C4", "D4", "E4", "F4", "E4", "D4", "C4",
  "E4", "F4", "G4", "A4", "G4", "F4", "E4",
  "C4", "C4", "C4", "C4",
  "C4", "C4", "D4", "D4", "E4", "E4", "F4", "F4",
  "E4", "D4", "C4"
};

// 各音の長さ(拍)
float[] duration = {
  0.9f, 0.9f, 0.9f, 0.9f, 0.9f, 0.9f, 1.2f,
  0.9f, 0.9f, 0.9f, 0.9f, 0.9f, 0.9f, 1.2f,
  1.2f, 1.2f, 1.2f, 1.2f,
  0.45f, 0.45f, 0.45f, 0.45f, 0.45f, 0.45f, 0.45f, 0.45f,
  0.9f, 0.9f, 1.2f
};

// 各音の開始位置
float[] startTime = {
  0.0f, 1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f,
  8.0f, 9.0f, 10.0f, 11.0f, 12.0f, 13.0f, 14.0f,
  16.0f, 18.0f, 20.0f, 22.0f,
  24.0f, 24.5f, 25.0f, 25.5f, 26.0f, 26.5f, 27.0f, 27.5f,
  28.5f, 29.5f, 30.5f
};

// 曲で使う音量
float[] songVolume = {
  0.7f, 0.7f, 0.7f, 0.7f, 0.7f, 0.7f, 0.7f,
  0.7f, 0.7f, 0.7f, 0.7f, 0.7f, 0.7f, 0.7f,
  0.6f, 0.6f, 0.6f, 0.6f,
  0.6f, 0.6f, 0.6f, 0.6f, 0.6f, 0.6f, 0.6f, 0.6f,
  0.7f, 0.7f, 0.7f
};

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
    noiseEnv.activate(0.001f, this.maxAmp * 0.01f, 0);

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
  size(512, 200);

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
}

void draw()
{
  background(0);
  stroke(255);

  // 左チャンネルと右チャンネルに入っている波形を描画
  for (int i = 0; i < out.bufferSize() - 1; i++)
  {
    line(i, 50 - out.left.get(i)*50, i+1, 50 - out.left.get(i+1)*50);
    line(i, 150 - out.right.get(i)*50, i+1, 150 - out.right.get(i+1)*50);
  }
}

void playSong()
{
  // 再生を停止
  out.pauseNotes();

  for (int i = 0; i < melody.length; i++)
  {
    out.playNote(
      startTime[i],
      duration[i],
      new GuitarInstrument(
        Frequency.ofPitch(melody[i]).asHz(),
        songVolume[i],
        currentWaveform
      )
    );
  }

  // 再生
  out.resumeNotes();
}

void playString(int stringNumber)
{
  out.playNote(
    0.0f,
    noteLength[stringNumber],
    new GuitarInstrument(
      Frequency.ofPitch(guitarStrings[stringNumber]).asHz(),
      volume[stringNumber],
      currentWaveform
    )
  );
}

void keyPressed()
{
  switch(key)
  {
  case '1':
    playString(0); // 6弦 E
    break;

  case '2':
    playString(1); // 5弦 A
    break;

  case '3':
    playString(2); // 4弦 D
    break;

  case '4':
    playString(3); // 3弦 G
    break;

  case '5':
    playString(4); // 2弦 B
    break;

  case '6':
    playString(5); // 1弦 E
    break;

  case 'p':
    playSong(); // カエルの歌
    break;

  default:
    break;
  }
}
