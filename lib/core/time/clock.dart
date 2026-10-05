abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  void set(DateTime value) => _now = value;

  void advance(Duration d) => _now = _now.add(d);

  @override
  DateTime now() => _now;
}
