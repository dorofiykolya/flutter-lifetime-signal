import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:lifetime/lifetime.dart';

typedef VoidCallbackT<T> = void Function(T);

abstract class ISignal {
  bool subscribe(Lifetime lifetime, VoidCallback callback);
}

class Signal extends ISignal {
  static List<List<VoidCallback>> _pool = <List<VoidCallback>>[];

  final Lifetime _lifetime;
  late List<VoidCallback>? _actions;

  Signal(Lifetime lifetime) : _lifetime = lifetime {
    _lifetime.add(() {
      if (_actions != null) {
        _actions!.clear();
        _pool.add(_actions!);
        _actions = null;
      }
    });
  }

  bool subscribe(Lifetime lifetime, VoidCallback callback) {
    if (_lifetime.isTerminated || lifetime.isTerminated) {
      return false;
    }
    if (_actions == null) {
      if (_pool.isNotEmpty) {
        _actions = _pool.removeLast();
      } else {
        _actions = <VoidCallback>[];
      }
    }
    if (_actions!.contains(callback)) {
      throw ArgumentError("The callback is already sinking the signal.");
    }
    _actions!.add(callback);
    lifetime.add(() {
      _actions!.remove(callback);
    });
    return true;
  }

  void call() {
    fire();
  }

  void fire() {
    if (_actions != null) {
      List<VoidCallback> copy;
      if (_pool.isNotEmpty) {
        copy = _pool.removeLast();
        copy.addAll(_actions!);
      } else {
        copy = _actions!.toList();
      }

      for (var value in copy) {
        value();
      }

      copy.clear();
      _pool.add(copy);
    }
  }
}

abstract class ISignalT<T> {
  bool subscribe(Lifetime lifetime, VoidCallbackT<T> callback);
}

class SignalT<T> extends ISignalT<T> {
  final Lifetime _lifetime;
  late List<VoidCallbackT<T>>? _actions;

  SignalT(Lifetime lifetime) : _lifetime = lifetime {
    _lifetime.add(() {
      if (_actions != null) {
        _actions!.clear();
        _actions = null;
      }
    });
  }

  bool subscribe(Lifetime lifetime, VoidCallbackT<T> callback) {
    if (_lifetime.isTerminated || lifetime.isTerminated) {
      return false;
    }
    if (_actions == null) {
      _actions = <VoidCallbackT<T>>[];
    }
    if (_actions!.contains(callback)) {
      throw ArgumentError("The callback is already sinking the signal.");
    }
    _actions!.add(callback);
    lifetime.add(() {
      _actions!.remove(callback);
    });
    return true;
  }

  void fire(T value) {
    if (_actions != null) {
      List<VoidCallbackT<T>> copy = _actions!.toList();

      for (var handler in copy) {
        handler(value);
      }

      copy.clear();
    }
  }
}
