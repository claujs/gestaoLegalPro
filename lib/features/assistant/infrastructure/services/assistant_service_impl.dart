import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/chat_models.dart';
import '../../domain/services/assistant_service.dart';

class AssistantServiceImpl implements AssistantService {
  http.Client? _currentClient;
  final Uri _endpoint;
  static const Duration _timeout = Duration(
    minutes: 4,
  ); // Aumentado para 4 minutos

  AssistantServiceImpl({String? baseUrl})
    : _endpoint = Uri.parse(
        baseUrl ?? 'https://gestaolegalpro.duckdns.org/chat',
      );

  @override
  void cancelCurrentRequest() {
    _currentClient?.close();
    _currentClient = null;
  }

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    // Cancela qualquer requisição anterior e cria um novo cliente
    cancelCurrentRequest();
    _currentClient = http.Client();

    final headers = <String, String>{'Content-Type': 'application/json'};

    final payloadStr = jsonEncode({
      'messages': [
        {
          'role': 'system',
          'content':
              'Você é um assistente jurídico para o Brasil. Responda de forma técnica, clara e objetiva.',
        },
        {'role': 'user', 'content': request.message},
      ],
      'stream': false,
    });

    try {
      // Primeira tentativa
      http.Response res;
      try {
        res = await _doPostWithRedirects(headers: headers, body: payloadStr);
      } on TimeoutException {
        // Uma única retry em caso de timeout
        await Future.delayed(const Duration(milliseconds: 500));
        res = await _doPostWithRedirects(headers: headers, body: payloadStr);
      } catch (e) {
        // Retry apenas para erros de servidor (5xx)
        if (e.toString().contains('502') ||
            e.toString().contains('503') ||
            e.toString().contains('504')) {
          await Future.delayed(const Duration(milliseconds: 1000));
          res = await _doPostWithRedirects(headers: headers, body: payloadStr);
        } else {
          rethrow;
        }
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return _parseResponse(res.body, res.headers['content-type'] ?? '');
      }

      throw Exception('Erro ao comunicar com o assistente (${res.statusCode})');
    } finally {
      _currentClient?.close();
      _currentClient = null;
    }
  }

  @override
  Future<ChatResponse> sendPlainText(String text) async {
    cancelCurrentRequest();
    _currentClient = http.Client();

    final headers = <String, String>{'Content-Type': 'application/json'};
    final payloadStr = jsonEncode({
      'messages': [
        {'role': 'user', 'content': text},
      ],
      'stream': false,
    });

    try {
      http.Response res = await _doPostWithRedirects(
        headers: headers,
        body: payloadStr,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return _parseResponse(res.body, res.headers['content-type'] ?? '');
      }
      throw Exception('Erro ao comunicar com o assistente (${res.statusCode})');
    } finally {
      _currentClient?.close();
      _currentClient = null;
    }
  }

  ChatResponse _parseResponse(String body, String contentType) {
    if (contentType.contains('application/x-ndjson')) {
      final buffer = StringBuffer();
      final lines = body
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty);

      for (final line in lines) {
        try {
          final obj = jsonDecode(line.trim());
          if (obj is Map<String, dynamic>) {
            final msg = obj['message'];
            if (msg is Map<String, dynamic>) {
              final chunk = (msg['content'] ?? '').toString();
              if (chunk.isNotEmpty) buffer.write(chunk);
            }
            if (buffer.isEmpty && obj['response'] is String) {
              buffer.write(obj['response'] as String);
            }
          }
        } catch (_) {
          // ignora linha inválida
        }
      }
      return ChatResponse(response: buffer.toString());
    }

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['response'] is String) {
        return ChatResponse(response: json['response'] as String);
      }
      final msg = json['message'];
      if (msg is Map<String, dynamic>) {
        final content = (msg['content'] ?? '').toString();
        return ChatResponse(response: content);
      }
    } catch (_) {
      // Se falhar no parse, retorna o body diretamente
      return ChatResponse(response: body);
    }

    return ChatResponse(response: '');
  }

  Future<http.Response> _doPostWithRedirects({
    required Map<String, String> headers,
    required String body,
  }) async {
    if (_currentClient == null) {
      throw Exception('Cliente HTTP não inicializado');
    }

    http.Response res;
    try {
      res = await _currentClient!
          .post(_endpoint, headers: headers, body: body)
          .timeout(_timeout);
    } catch (e) {
      rethrow;
    }

    // Handle redirects
    if (res.statusCode >= 300 && res.statusCode < 400) {
      final loc = res.headers['location'];
      if (loc != null && loc.isNotEmpty) {
        final uri = Uri.parse(loc);
        res = await _currentClient!
            .post(uri, headers: headers, body: body)
            .timeout(_timeout);
      }
    }
    return res;
  }
}
