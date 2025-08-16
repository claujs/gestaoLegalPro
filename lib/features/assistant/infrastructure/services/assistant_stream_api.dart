import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente de streaming para o Assistente Jurídico via NDJSON.
class JuridicoApiStream {
  static final Uri _url = Uri.parse('https://gestaolegalpro.duckdns.org/chat');

  /// Envia a pergunta e retorna um Stream de pedaços de texto (tokens) do assistente.
  static Stream<String> perguntar(String pergunta) async* {
    final req = http.Request('POST', _url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'messages': [
          {
            'role': 'system',
            'content':
                'Você é um assistente jurídico para o Brasil. Responda de forma técnica, clara e objetiva.',
          },
          {'role': 'user', 'content': pergunta},
        ],
        'stream': true,
        'keep_alive': '10m',
      });

    final client = http.Client();
    try {
      final streamed = await client
          .send(req)
          .timeout(const Duration(seconds: 60));
      final lines = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        final t = line.trim();
        if (t.isEmpty) continue;
        try {
          final obj = jsonDecode(t) as Map<String, dynamic>;
          final chunk = obj['message']?['content'];
          if (chunk is String && chunk.isNotEmpty) yield chunk;
        } catch (_) {
          // Ignora linhas parciais/ou não JSON válido
        }
      }
    } on TimeoutException {
      // Propaga para o chamador lidar com retry/backoff
      rethrow;
    } finally {
      client.close();
    }
  }
}
