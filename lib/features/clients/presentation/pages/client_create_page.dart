import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/client_models.dart';
import '../controllers/client_create_controller.dart';
import 'package:intl/intl.dart';

class ClientCreatePage extends StatefulWidget {
  const ClientCreatePage({super.key});
  static const route = '/clientes/novo';

  @override
  State<ClientCreatePage> createState() => _ClientCreatePageState();
}

class _ClientCreatePageState extends State<ClientCreatePage> {
  late final ClientCreateController c;
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  final _dateFormat = DateFormat('dd/MM/yyyy');

  // Controllers endereço
  final _cepCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  bool _syncingEndereco = false; // flag para evitar onChanged durante sync

  @override
  void initState() {
    super.initState();
    c = Get.put(ClientCreateController());
  }

  @override
  void dispose() {
    _cepCtrl.dispose();
    _ufCtrl.dispose();
    _cidadeCtrl.dispose();
    _bairroCtrl.dispose();
    _logradouroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = c.step.value;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Novo Cliente'),
          actions: [
            if (c.autoSavedAt.value != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Rascunho: ${DateFormat('HH:mm:ss').format(c.autoSavedAt.value!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Stepper(
                currentStep: step,
                onStepTapped: (s) => c.setStep(s),
                controlsBuilder: (ctx, details) => Row(
                  children: [
                    if (step < 4)
                      FilledButton(
                        onPressed: c.canNext ? c.next : null,
                        child: const Text('Avançar'),
                      ),
                    if (step == 4)
                      FilledButton.icon(
                        onPressed: c.isSaving.value
                            ? null
                            : () async {
                                await c.save();
                                if (mounted) Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.save),
                        label: Text(
                          c.isSaving.value ? 'Salvando...' : 'Salvar',
                        ),
                      ),
                    const SizedBox(width: 12),
                    if (step > 0)
                      OutlinedButton(
                        onPressed: c.back,
                        child: const Text('Voltar'),
                      ),
                  ],
                ),
                steps: [
                  Step(
                    title: const Text('Identificação'),
                    isActive: step >= 0,
                    state: step > 0 ? StepState.complete : StepState.indexed,
                    content: _identificacao(),
                  ),
                  Step(
                    title: const Text('Contato'),
                    isActive: step >= 1,
                    state: step > 1 ? StepState.complete : StepState.indexed,
                    content: _contatos(),
                  ),
                  Step(
                    title: const Text('Endereço'),
                    isActive: step >= 2,
                    state: step > 2 ? StepState.complete : StepState.indexed,
                    content: _endereco(),
                  ),
                  Step(
                    title: const Text('Jurídico'),
                    isActive: step >= 3,
                    state: step > 3 ? StepState.complete : StepState.indexed,
                    content: _juridico(),
                  ),
                  Step(
                    title: const Text('Financeiro'),
                    isActive: step >= 4,
                    state: step == 4 ? StepState.editing : StepState.indexed,
                    content: _financeiro(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Exemplo de botão/menu para acessar lista de clientes:
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/dashboard/clientes'),
          label: const Text('Ver clientes cadastrados'),
          icon: const Icon(Icons.list),
        ),
      );
    });
  }

  Widget _identificacao() {
    final d = c.draft.value;
    return Form(
      key: _formKeys[0],
      onChanged: () => c.autoSave(),
      child: Column(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'PF', label: Text('Pessoa Física')),
              ButtonSegment(value: 'PJ', label: Text('Pessoa Jurídica')),
            ],
            selected: {d.tipo},
            onSelectionChanged: (v) {
              c.draft.update((dd) => dd!.tipo = v.first);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nome / Razão Social *',
            ),
            initialValue: d.nomeRazao,
            onChanged: (v) => c.draft.update((dd) => dd!.nomeRazao = v),
            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Apelido / Fantasia'),
            initialValue: d.apelidoFantasia,
            onChanged: (v) => c.draft.update((dd) => dd!.apelidoFantasia = v),
          ),
          const SizedBox(height: 12),
          if (d.tipo == 'PF')
            TextFormField(
              decoration: const InputDecoration(labelText: 'CPF *'),
              initialValue: d.cpf,
              onChanged: (v) => c.draft.update((dd) => dd!.cpf = v),
              validator: (v) => (d.tipo == 'PF' && (v == null || v.isEmpty))
                  ? 'Obrigatório'
                  : null,
            )
          else
            TextFormField(
              decoration: const InputDecoration(labelText: 'CNPJ *'),
              initialValue: d.cnpj,
              onChanged: (v) => c.draft.update((dd) => dd!.cnpj = v),
              validator: (v) => (d.tipo == 'PJ' && (v == null || v.isEmpty))
                  ? 'Obrigatório'
                  : null,
            ),
          const SizedBox(height: 12),
          if (d.tipo == 'PF')
            TextFormField(
              decoration: const InputDecoration(labelText: 'RG / Documento'),
              initialValue: d.rg,
              onChanged: (v) => c.draft.update((dd) => dd!.rg = v),
            )
          else
            TextFormField(
              decoration: const InputDecoration(labelText: 'IE (Opcional)'),
              initialValue: d.ie,
              onChanged: (v) => c.draft.update((dd) => dd!.ie = v),
            ),
          const SizedBox(height: 12),
          _datePickerField(
            label: d.tipo == 'PF' ? 'Data de nascimento' : 'Data de abertura',
            date: d.dataRef,
            onPick: (dt) => c.draft.update((dd) => dd!.dataRef = dt),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'E-mail *'),
            initialValue: d.emailPrincipal,
            onChanged: (v) => c.draft.update(
              (dd) => dd!.emailPrincipal = v.trim().toLowerCase(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Telefone *'),
            initialValue: d.telefonePrincipal,
            onChanged: (v) => c.draft.update((dd) => dd!.telefonePrincipal = v),
            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
          ),
        ],
      ),
    );
  }

  Widget _contatos() {
    final d = c.draft.value;
    return Form(
      key: _formKeys[1],
      onChanged: () => c.autoSave(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.tipo == 'PJ') ...[
            TextFormField(
              decoration: const InputDecoration(labelText: 'Responsável *'),
              initialValue: d.responsavelNome,
              onChanged: (v) => c.draft.update((dd) => dd!.responsavelNome = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Cargo'),
              initialValue: d.responsavelCargo,
              onChanged: (v) =>
                  c.draft.update((dd) => dd!.responsavelCargo = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'E-mail do responsável',
              ),
              initialValue: d.responsavelEmail,
              onChanged: (v) => c.draft.update(
                (dd) => dd!.responsavelEmail = v.trim().toLowerCase(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Telefone do responsável',
              ),
              initialValue: d.responsavelTelefone,
              onChanged: (v) =>
                  c.draft.update((dd) => dd!.responsavelTelefone = v),
            ),
            const Divider(height: 32),
          ],
          Text(
            'Outros Contatos',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...d.outrosContatos.map(
            (ct) => Card(
              child: ListTile(
                title: Text(ct.name),
                subtitle: Text('${ct.email}  ${ct.phone}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    d.outrosContatos.remove(ct);
                    c.draft.refresh();
                  },
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final novo = await _dialogContato();
                if (novo != null) {
                  d.outrosContatos.add(novo);
                  c.draft.refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar contato'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _endereco() {
    return Obx(() {
      final d = c.draft.value;
      // Sincroniza controllers quando valores do draft mudam
      void sync(TextEditingController ctrl, String value) {
        if (ctrl.text != value) {
          ctrl.text = value;
          ctrl.selection = TextSelection.collapsed(offset: value.length);
        }
      }

      _syncingEndereco = true;
      sync(_cepCtrl, d.cep);
      sync(_ufCtrl, d.uf);
      sync(_cidadeCtrl, d.cidade);
      sync(_bairroCtrl, d.bairro);
      sync(_logradouroCtrl, d.logradouro);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncingEndereco = false;
      });
      return Form(
        key: _formKeys[2],
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepCtrl,
                    decoration: const InputDecoration(labelText: 'CEP'),
                    onChanged: (v) {
                      if (!_syncingEndereco)
                        c.draft.update((dd) => dd!.cep = v);
                    },
                    onFieldSubmitted: (v) => c.fetchCep(v),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final loading = c.isLoadingCep.value;
                  return SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: loading
                          ? null
                          : () => c.fetchCep(_cepCtrl.text),
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(loading ? 'Buscando...' : 'Buscar'),
                    ),
                  );
                }),
              ],
            ),
            Obx(
              () => c.cepError.value == null
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          c.cepError.value!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ufCtrl,
              decoration: const InputDecoration(labelText: 'UF *'),
              onChanged: (v) {
                if (!_syncingEndereco) c.draft.update((dd) => dd!.uf = v);
              },
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cidadeCtrl,
              decoration: const InputDecoration(labelText: 'Cidade *'),
              onChanged: (v) {
                if (!_syncingEndereco) c.draft.update((dd) => dd!.cidade = v);
              },
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bairroCtrl,
              decoration: const InputDecoration(labelText: 'Bairro'),
              onChanged: (v) {
                if (!_syncingEndereco) c.draft.update((dd) => dd!.bairro = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _logradouroCtrl,
              decoration: const InputDecoration(labelText: 'Logradouro'),
              onChanged: (v) {
                if (!_syncingEndereco)
                  c.draft.update((dd) => dd!.logradouro = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Número'),
              initialValue: d.numero,
              onChanged: (v) => c.draft.update((dd) => dd!.numero = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Complemento'),
              initialValue: d.complemento,
              onChanged: (v) => c.draft.update((dd) => dd!.complemento = v),
            ),
          ],
        ),
      );
    });
  }

  Widget _juridico() {
    final d = c.draft.value;
    return Form(
      key: _formKeys[3],
      onChanged: () => c.autoSave(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Tipo'),
            value: d.tipoCliente,
            items: const [
              DropdownMenuItem(value: 'Cliente', child: Text('Cliente')),
              DropdownMenuItem(value: 'Potencial', child: Text('Potencial')),
              DropdownMenuItem(value: 'Interno', child: Text('Interno')),
            ],
            onChanged: (v) =>
                c.draft.update((dd) => dd!.tipoCliente = v ?? 'Cliente'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: d.areasAtuacao
                .map(
                  (a) => Chip(
                    label: Text(a),
                    onDeleted: () {
                      d.areasAtuacao.remove(a);
                      c.draft.refresh();
                    },
                  ),
                )
                .toList(),
          ),
          TextButton.icon(
            onPressed: () async {
              final area = await _dialogTexto('Área de atuação / Interesse');
              if (area != null && area.isNotEmpty) {
                d.areasAtuacao.add(area);
                c.draft.refresh();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar área'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: d.consentimentoLgpd,
            onChanged: (v) =>
                c.draft.update((dd) => dd!.consentimentoLgpd = v ?? false),
            title: const Text('Consentimento LGPD *'),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Observações'),
            initialValue: d.observacoes,
            maxLines: 4,
            onChanged: (v) => c.draft.update((dd) => dd!.observacoes = v),
          ),
        ],
      ),
    );
  }

  Widget _financeiro() {
    final d = c.draft.value;
    return Form(
      key: _formKeys[4],
      onChanged: () => c.autoSave(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Forma de faturamento',
            ),
            value: d.formaFaturamento.isEmpty ? null : d.formaFaturamento,
            items: const [
              DropdownMenuItem(value: 'Hora', child: Text('Hora')),
              DropdownMenuItem(value: 'Tabela', child: Text('Tabela')),
              DropdownMenuItem(value: 'Sucesso', child: Text('Sucesso')),
              DropdownMenuItem(
                value: 'Mensalidade',
                child: Text('Mensalidade'),
              ),
            ],
            onChanged: (v) =>
                c.draft.update((dd) => dd!.formaFaturamento = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Responsável faturamento',
            ),
            initialValue: d.faturamentoResponsavelNome,
            onChanged: (v) =>
                c.draft.update((dd) => dd!.faturamentoResponsavelNome = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'E-mail faturamento'),
            initialValue: d.faturamentoResponsavelEmail,
            onChanged: (v) => c.draft.update(
              (dd) => dd!.faturamentoResponsavelEmail = v.trim().toLowerCase(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Dados NF-e'),
            initialValue: d.dadosNfe,
            onChanged: (v) => c.draft.update((dd) => dd!.dadosNfe = v),
          ),
          const SizedBox(height: 16),
          Text('Resumo', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(d.toMap().toString(), style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _datePickerField({
    required String label,
    DateTime? date,
    required ValueChanged<DateTime?> onPick,
  }) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(now.year - 120),
          lastDate: DateTime(now.year + 1),
          initialDate: date ?? DateTime(now.year - 18),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(date == null ? 'Selecionar' : _dateFormat.format(date)),
      ),
    );
  }

  Future<ClientContact?> _dialogContato() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final result = await showDialog<ClientContact?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo Contato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome *'),
            ),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: 'Cargo'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                ClientContact(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim().toLowerCase(),
                  phone: phoneCtrl.text.trim(),
                  role: roleCtrl.text.trim(),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<String?> _dialogTexto(String titulo) async {
    final ctrl = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return res;
  }

  void _onSave() {
    if (_formKeys.every((k) => k.currentState?.validate() ?? false)) {
      c.addCliente(c.draft.value);
      context.go('/dashboard/clientes');
    }
  }
}
