import 'dart:convert';
import 'package:http/http.dart' as http;

class CepService {
  /// Busca endereço pelo CEP usando a API ViaCEP
  /// Retorna null se o CEP for inválido ou não encontrado
  static Future<Map<String, dynamic>?> buscarCep(String cep) async {
    // Remove caracteres não numéricos
    final cepLimpo = cep.replaceAll(RegExp(r'[^\d]'), '');

    if (cepLimpo.length != 8) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // ViaCEP retorna {"erro": true} quando o CEP não existe
        if (data['erro'] == true) {
          return null;
        }

        return data;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
