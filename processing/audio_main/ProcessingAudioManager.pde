class ProcessingAudioManager {
  String receivedData = "";
  int instrumentId = 0;
  String instrumentName = "";
  String pitch = "";
  float duration = 0;
  float velocity = 0;
  int beatNumber = 0;
  int bpm = 0;

  InstrumentSound pianoSound = new PianoSound();
  InstrumentSound guitarSound = new GuitarSound();
  InstrumentSound fluteSound = new FluteSound();
  InstrumentSound drumSound = new DrumSound();

  boolean parsePerformanceData(String data) {
    receivedData = data;
    String[] tokens = splitTokens(data, ", ");

    if (tokens.length < 8 || !tokens[0].equals("PERF")) {
      return false;
    }

    instrumentId = parseInt(tokens[1]);
    instrumentName = tokens[2];
    pitch = tokens[3];
    duration = parseFloat(tokens[4]);
    velocity = parseFloat(tokens[5]);
    beatNumber = parseInt(tokens[6]);
    bpm = parseInt(tokens[7]);

    if (instrumentId < 1 || instrumentId > 4) {
      return false;
    }

    if (Float.isNaN(duration) || Float.isNaN(velocity)) {
      return false;
    }

    duration = max(duration, 0.05);
    velocity = constrain(velocity, 0.0, 1.0);
    return true;
  }

  void playSound() {
    if (instrumentId == 1) {
      pianoSound.noteOn(pitch, duration, velocity);
    } else if (instrumentId == 2) {
      guitarSound.noteOn(pitch, duration, velocity);
    } else if (instrumentId == 3) {
      fluteSound.noteOn(pitch, duration, velocity);
    } else if (instrumentId == 4) {
      drumSound.noteOn(pitch, duration, velocity);
    }
  }
}
