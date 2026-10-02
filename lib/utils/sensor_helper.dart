class SensorHelper {
  static final gAccel =  9.80665;

  static double ms2ToG(double ms2) {
    return ms2 / gAccel;
  }
}