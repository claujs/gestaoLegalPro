import '../domain/models/client_models.dart';

final List<ClientDraft> mockClientesDraft = [
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
];
