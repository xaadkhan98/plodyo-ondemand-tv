/// Runs [attempt], retrying up to [retries] more times after 1s, 2s, … while [retryIf] allows the error.
Future<T> retry<T>(
  Future<T> Function() attempt, {
  int retries = 2,
  bool Function(Object error)? retryIf,
}) async {
  for (var tries = 0; ; tries++) {
    try {
      return await attempt();
    } catch (error) {
      if (tries >= retries || !(retryIf?.call(error) ?? true)) rethrow;
      await Future<void>.delayed(Duration(seconds: 1 << tries));
    }
  }
}
