import 'package:dio/dio.dart';

/// Хранит CancelToken для отмены устаревших запросов списка.
class CancelScope {
  CancelToken? _token;

  CancelToken next() {
    _token?.cancel('устаревший запрос');
    _token = CancelToken();
    return _token!;
  }

  void dispose() {
    _token?.cancel('dispose');
    _token = null;
  }
}
