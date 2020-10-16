String roundDS(double d, int stellen) {
  // trim trailing zeroes
  // we try to achieve what str(round(d, stellen)) does in Python
  String s = d.toStringAsFixed(stellen);
  while (s[s.length - 1] == '0') {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
