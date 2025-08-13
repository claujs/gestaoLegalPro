class ClientContact {
  String name;
  String email;
  String phone;
  String role; // cargo ou relação
  ClientContact({
    required this.name,
    this.email = '',
    this.phone = '',
    this.role = '',
  });
}

class ClientDraft {
  // Identificação
  String tipo = 'PF'; // PF | PJ
  String nomeRazao = '';
  String apelidoFantasia = '';
  String cpf = '';
  String cnpj = '';
  String rg = '';
  String ie = '';
  DateTime? dataRef; // nascimento (PF) ou abertura (PJ)
  String emailPrincipal = '';
  String telefonePrincipal = '';

  // Contatos
  String responsavelNome = '';
  String responsavelCargo = '';
  String responsavelEmail = '';
  String responsavelTelefone = '';
  List<ClientContact> outrosContatos = [];

  // Endereço
  String cep = '';
  String uf = '';
  String cidade = '';
  String bairro = '';
  String logradouro = '';
  String numero = '';
  String complemento = '';

  // Jurídico / Contrato
  String tipoCliente = 'Cliente'; // Cliente | Potencial | Interno
  List<String> areasAtuacao = [];
  bool consentimentoLgpd = false;
  String observacoes = '';

  // Financeiro
  String formaFaturamento = '';
  String faturamentoResponsavelNome = '';
  String faturamentoResponsavelEmail = '';
  String dadosNfe = '';

  // Anexos (paths temporários)
  List<String> anexos = [];

  Map<String, dynamic> toMap() => {
    'tipo': tipo,
    'nomeRazao': nomeRazao,
    'apelidoFantasia': apelidoFantasia,
    'cpf': cpf,
    'cnpj': cnpj,
    'rg': rg,
    'ie': ie,
    'dataRef': dataRef?.toIso8601String(),
    'emailPrincipal': emailPrincipal,
    'telefonePrincipal': telefonePrincipal,
    'responsavelNome': responsavelNome,
    'responsavelCargo': responsavelCargo,
    'responsavelEmail': responsavelEmail,
    'responsavelTelefone': responsavelTelefone,
    'outrosContatos': outrosContatos
        .map(
          (c) => {
            'name': c.name,
            'email': c.email,
            'phone': c.phone,
            'role': c.role,
          },
        )
        .toList(),
    'cep': cep,
    'uf': uf,
    'cidade': cidade,
    'bairro': bairro,
    'logradouro': logradouro,
    'numero': numero,
    'complemento': complemento,
    'tipoCliente': tipoCliente,
    'areasAtuacao': areasAtuacao,
    'consentimentoLgpd': consentimentoLgpd,
    'observacoes': observacoes,
    'formaFaturamento': formaFaturamento,
    'faturamentoResponsavelNome': faturamentoResponsavelNome,
    'faturamentoResponsavelEmail': faturamentoResponsavelEmail,
    'dadosNfe': dadosNfe,
    'anexos': anexos,
  };
}
