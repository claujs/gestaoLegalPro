/// Textos/constantes usados na tela de criação de processo (MVVM / i18n ready)
/// Futuramente pode ser substituído por uma solução de localization.
class ProcessCreateTexts {
  static const numeroCnj = 'Número CNJ *';
  static const status = 'Status *';
  static const statusEmAndamento = 'Em andamento';
  static const statusConcluido = 'Concluído';
  static const statusSuspenso = 'Suspenso';
  static const dataDistribuicao = 'Data de distribuição *';
  static const selecionar = 'Selecionar';
  static const valorCausa = 'Valor da causa (R\$)';
  static const clienteCampo = 'Cliente *';
  static const papelPrefix = 'Papel: ';
  static const clientePrincipalTooltip = 'Cliente principal';
  static const segmento = 'Segmento';
  static const estadual = 'Estadual';
  static const federal = 'Federal';
  static const trabalho = 'Trabalho';
  static const tribunal = 'Tribunal';
  static const uf = 'UF';
  static const comarcaSecao = 'Comarca / Seção';
  static const foroVara = 'Foro / Vara';
  static const adicionarForoTooltip = 'Adicionar foro';
  static const classeProcessual = 'Classe processual';
  static const assuntoPrincipal = 'Assunto principal';
  static const assuntoAdicional = 'Assunto adicional';
  static const adicionarAssunto = 'Adicionar assunto';
  static const poloAtivo = 'Polo Ativo';
  static const poloPassivo = 'Polo Passivo';
  static const advClientes = 'Advogados do cliente';
  static const advContrarios = 'Advogados da parte contrária';
  static const sigilo = 'Sigilo';
  static const sigiloPublico = 'Público';
  static const sigiloSegredo = 'Segredo de justiça';
  static const procedimentoRito = 'Procedimento / Rito';
  static const origem = 'Origem';
  static const numeroAnterior = 'Número anterior';
  static const formato = 'Formato';
  static const formatoEletronico = 'Eletrônico';
  static const formatoFisico = 'Físico';
  static const tag = 'Tag';
  static const adicionarTag = 'Adicionar tag';
  static const criarAlertaPrimeiroPrazo = 'Criar alerta do primeiro prazo';
  static const resumo = 'Resumo';
  static const salvando = 'Salvando...';
  static const salvarProcesso = 'Salvar Processo';
  static const novoProcesso = 'Novo Processo';
  static const rascunhoSalvoPrefix = 'Rascunho salvo às ';
  static const avancar = 'Avançar';
  static const voltar = 'Voltar';
  static const identificacao = 'Identificação';
  static const clientes = 'Clientes';
  static const juizo = 'Juízo';
  static const partes = 'Partes';
  static const revisao = 'Revisão';
  static const obrigatorio = 'Obrigatório';
  static const cnjInvalido = 'CNJ inválido';
  static const valorInvalido = 'Valor inválido';
  static const nenhumClienteAdicionado = 'Nenhum cliente adicionado';
  static const novo = 'Novo';
  static const nomeDaParte = 'Nome da parte';
  static const adicionarParteBase = 'Adicionar parte';
  static const ativa = 'ativa';
  static const passiva = 'passiva';
  static const nomeAdvogado = 'Nome do advogado';
  static const adicionarAdvogadoBase = 'Adicionar advogado';
  static const doCliente = 'do cliente';
  static const contrario = 'contrário';
  static const cancelar = 'Cancelar';
  static const ok = 'OK';
  static const selecionarRoleAutor = 'Autor';

  static String adicionarParte(bool active) =>
      '$adicionarParteBase ${active ? ativa : passiva}';
  static String adicionarAdvogado(bool cliente) =>
      '$adicionarAdvogadoBase ${cliente ? doCliente : contrario}';
}
