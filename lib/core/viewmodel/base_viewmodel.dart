import 'package:flutter/foundation.dart';
import 'view_state.dart';

abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get isBusy => _state == ViewState.busy;
  bool get isError => _state == ViewState.error;
  bool get isSuccess => _state == ViewState.success;

  void setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    if (message != null) {
      _state = ViewState.error;
    } else {
      _state = ViewState.idle;
    }
    notifyListeners();
  }

  void setSuccess() {
    _state = ViewState.success;
    _errorMessage = null;
    notifyListeners();
  }
}
