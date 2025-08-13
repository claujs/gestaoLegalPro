/// MVP Draft models (simplificados) para criação de processo
/// Poderão evoluir para entidades de domínio/DTOs posteriormente.

class ProcessClientLink {
  String clientId; // id ou documento
  String name; // nome apresentado
  String role; // Autor, Réu, etc.
  bool isPrimary;
  ProcessClientLink({
    required this.clientId,
    required this.name,
    required this.role,
    this.isPrimary = false,
  });
}

class Party {
  String name;
  String document; // CPF/CNPJ opcional
  String type; // Fisica / Juridica
  Party({required this.name, this.document = '', this.type = 'Física'});
}

class Lawyer {
  String name;
  String oab;
  String uf;
  Lawyer({required this.name, required this.oab, required this.uf});
}

class ProcessDraft {
  // Passo 1 - Identificação
  String cnj = '';
  String status = '';
  DateTime? distributionDate;
  double? caseValue;

  // Passo 2 - Clientes
  List<ProcessClientLink> clients = [];

  // Passo 3 - Juízo / Classificação
  String segment = '';
  String tribunal = '';
  String uf = '';
  String comarca = '';
  String foro = '';
  String classe = '';
  String assuntoPrincipal = '';
  List<String> assuntosAdicionais = [];

  // Passo 4 - Partes / Advogados
  List<Party> poloAtivo = [];
  List<Party> poloPassivo = [];
  List<Lawyer> advClientes = [];
  List<Lawyer> advContrarios = [];

  // Passo 5 - Metadados / Regras / Documentos iniciais / Agenda
  String sigilo = 'Público';
  String rito = '';
  String origem = '';
  String numeroAnterior = '';
  String formato = 'Eletrônico';
  List<String> tags = [];
  // Documentos: manter apenas paths temporários ou objetos quando integrar storage
  List<String> documentos = [];
  bool criarAlertaPrimeiroPrazo = false;

  ProcessDraft();

  Map<String, dynamic> toMap() => {
    'cnj': cnj,
    'status': status,
    'distributionDate': distributionDate?.toIso8601String(),
    'caseValue': caseValue,
    'clients': clients
        .map(
          (c) => {
            'clientId': c.clientId,
            'name': c.name,
            'role': c.role,
            'isPrimary': c.isPrimary,
          },
        )
        .toList(),
    'segment': segment,
    'tribunal': tribunal,
    'uf': uf,
    'comarca': comarca,
    'foro': foro,
    'classe': classe,
    'assuntoPrincipal': assuntoPrincipal,
    'assuntosAdicionais': assuntosAdicionais,
    'poloAtivo': poloAtivo
        .map((p) => {'name': p.name, 'doc': p.document, 'type': p.type})
        .toList(),
    'poloPassivo': poloPassivo
        .map((p) => {'name': p.name, 'doc': p.document, 'type': p.type})
        .toList(),
    'advClientes': advClientes
        .map((a) => {'name': a.name, 'oab': a.oab, 'uf': a.uf})
        .toList(),
    'advContrarios': advContrarios
        .map((a) => {'name': a.name, 'oab': a.oab, 'uf': a.uf})
        .toList(),
    'sigilo': sigilo,
    'rito': rito,
    'origem': origem,
    'numeroAnterior': numeroAnterior,
    'formato': formato,
    'tags': tags,
    'documentos': documentos,
    'criarAlertaPrimeiroPrazo': criarAlertaPrimeiroPrazo,
  };
}
