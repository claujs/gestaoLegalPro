import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../domain/models/client_models.dart';

class ClientCreateController extends GetxController {
  final draft = ClientDraft().obs;
  final step = 0.obs; // 0..4 (podemos agrupar seções)
  final isSaving = false.obs;
  final autoSavedAt = Rxn<DateTime>();
  final isLoadingCep = false.obs;
  final cepError = RxnString();
  final clientes = <ClientDraft>[].obs;

  void setStep(int s) {
    if (s < 0 || s > 4) return;
    step.value = s;
  }

  void next() => setStep(step.value + 1);
  void back() => setStep(step.value - 1);

  Future<void> autoSave() async {
    autoSavedAt.value = DateTime.now();
  }

  String? validate(int s) {
    final d = draft.value;
    switch (s) {
      case 0: // Identificação
        if (d.tipo != 'PF' && d.tipo != 'PJ') return 'Tipo inválido';
        if (d.nomeRazao.isEmpty) return 'Informe o nome/razão social';
        if (d.tipo == 'PF' && d.cpf.isEmpty) return 'Informe CPF';
        if (d.tipo == 'PJ' && d.cnpj.isEmpty) return 'Informe CNPJ';
        if (d.emailPrincipal.isEmpty) return 'Informe e-mail';
        if (d.telefonePrincipal.isEmpty) return 'Informe telefone';
        return null;
      case 1: // Contatos
        if (d.tipo == 'PJ' && d.responsavelNome.isEmpty) {
          return 'Responsável obrigatório para PJ';
        }
        return null;
      case 2: // Endereço
        if (d.uf.isEmpty) return 'UF obrigatória';
        if (d.cidade.isEmpty) return 'Cidade obrigatória';
        return null;
      case 3: // Jurídico
        if (!d.consentimentoLgpd) return 'Consentimento LGPD obrigatório';
        return null;
      default:
        return null;
    }
  }

  bool get canNext => validate(step.value) == null;

  Future<void> save() async {
    isSaving.value = true;
    await Future.delayed(const Duration(milliseconds: 700));
    isSaving.value = false;
  }

  void addCliente(ClientDraft draft) {
    clientes.add(draft);
  }

  Future<void> fetchCep(String rawCep) async {
    final cep = rawCep.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint('[CEP] Iniciando busca para: $rawCep -> normalizado: $cep');
    if (cep.length != 8) {
      cepError.value = 'CEP inválido';
      debugPrint('[CEP] CEP inválido (tamanho != 8)');
      return;
    }
    isLoadingCep.value = true;
    cepError.value = null;
    try {
      final uri = Uri.parse('https://brasilapi.com.br/api/cep/v1/$cep');
      debugPrint('[CEP] GET $uri');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      debugPrint('[CEP] Status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        debugPrint(
          '[CEP] Body: ${resp.body.substring(0, resp.body.length.clamp(0, 200))}',
        );
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        draft.update((d) {
          if (d == null) return;
          d.cep = data['cep']?.toString() ?? cep;
          debugPrint('[CEP] CEP salvo: ${d.cep}');
          d.uf = data['state']?.toString() ?? d.uf;
          d.cidade = data['city']?.toString() ?? d.cidade;
          d.bairro = data['neighborhood']?.toString() ?? d.bairro;
          d.logradouro = data['street']?.toString() ?? d.logradouro;
        });
        debugPrint(
          '[CEP] Preenchido -> UF: ${draft.value.uf}, Cidade: ${draft.value.cidade}, Bairro: ${draft.value.bairro}, Logradouro: ${draft.value.logradouro}',
        );
        autoSave();
      } else {
        cepError.value = 'CEP não encontrado';
        debugPrint('[CEP] Erro: não encontrado. Body: ${resp.body}');
      }
    } catch (e) {
      cepError.value = 'Erro ao consultar CEP';
      debugPrint('[CEP] Exceção: $e');
    } finally {
      isLoadingCep.value = false;
      debugPrint('[CEP] Finalizado. isLoadingCep=false');
    }
  }

  @override
  void onInit() {
    super.onInit();
    addMockClientes();
  }

  void addMockClientes() {
    if (clientes.isNotEmpty) return;
    clientes.addAll([
      ClientDraft()
        ..tipo = 'PF'
        ..nomeRazao = 'João Silva'
        ..cpf = '123.456.789-00'
        ..emailPrincipal = 'joao@email.com'
        ..telefonePrincipal = '(11) 99999-1111'
        ..uf = 'SP'
        ..cidade = 'São Paulo',
      ClientDraft()
        ..tipo = 'PJ'
        ..nomeRazao = 'Empresa Exemplo Ltda.'
        ..cnpj = '12.345.678/0001-99'
        ..emailPrincipal = 'contato@exemplo.com'
        ..telefonePrincipal = '(21) 88888-2222'
        ..uf = 'RJ'
        ..cidade = 'Rio de Janeiro',
      ClientDraft()
        ..tipo = 'PF'
        ..nomeRazao = 'Maria Oliveira'
        ..cpf = '987.654.321-00'
        ..emailPrincipal = 'maria@email.com'
        ..telefonePrincipal = '(31) 77777-3333'
        ..uf = 'MG'
        ..cidade = 'Belo Horizonte',
    ]);
  }
}
