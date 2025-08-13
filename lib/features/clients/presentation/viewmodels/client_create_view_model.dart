import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/controllers/base_view_model.dart';
import '../../domain/models/client_models.dart';
import '../../data/mock_clientes_draft.dart';

class ClientCreateViewModel extends BaseViewModel {
  final draft = ClientDraft().obs;
  final step = 0.obs; // 0..4
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
      case 0:
        if (d.tipo != 'PF' && d.tipo != 'PJ') return 'Tipo inválido';
        if (d.nomeRazao.isEmpty) return 'Informe o nome/razão social';
        if (d.tipo == 'PF' && d.cpf.isEmpty) return 'Informe CPF';
        if (d.tipo == 'PJ' && d.cnpj.isEmpty) return 'Informe CNPJ';
        if (d.emailPrincipal.isEmpty) return 'Informe e-mail';
        if (d.telefonePrincipal.isEmpty) return 'Informe telefone';
        return null;
      case 1:
        if (d.tipo == 'PJ' && d.responsavelNome.isEmpty) {
          return 'Responsável obrigatório para PJ';
        }
        return null;
      case 2:
        if (d.uf.isEmpty) return 'UF obrigatória';
        if (d.cidade.isEmpty) return 'Cidade obrigatória';
        return null;
      case 3:
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
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        draft.update((d) {
          if (d == null) return;
          d.cep = data['cep']?.toString() ?? cep;
          d.uf = data['state']?.toString() ?? d.uf;
          d.cidade = data['city']?.toString() ?? d.cidade;
          d.bairro = data['neighborhood']?.toString() ?? d.bairro;
          d.logradouro = data['street']?.toString() ?? d.logradouro;
        });
        autoSave();
      } else {
        cepError.value = 'CEP não encontrado';
      }
    } catch (e) {
      cepError.value = 'Erro ao consultar CEP';
      debugPrint('[CEP] Exceção: $e');
    } finally {
      isLoadingCep.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    addMockClientes();
  }

  void addMockClientes() {
    if (clientes.isNotEmpty) return;
    clientes.addAll(mockClientesDraft);
  }
}
