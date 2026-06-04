class FirebaseParser {
  static Map<String, dynamic> convertToMap(Object? val) {
    if (val == null) return {};
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), v));
    }
    if (val is List) {
      final Map<String, dynamic> map = {};
      for (int i = 0; i < val.length; i++) {
        if (val[i] != null) {
          map[i.toString()] = val[i];
        }
      }
      return map;
    }
    return {};
  }
}
