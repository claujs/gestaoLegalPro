import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart'; // adicionado para navegação ao cadastro de cliente
import '../controllers/process_create_controller.dart';
import '../../domain/models/process_models.dart';
import 'package:intl/intl.dart';

class ProcessCreatePage extends StatefulWidget {
  const ProcessCreatePage({super.key});
  static const route = '/processos/novo';

  @override
  State<ProcessCreatePage> createState() => _ProcessCreatePageState();
}

class _ProcessCreatePageState extends State<ProcessCreatePage> {
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());
  late final ProcessCreateController c;
  final _cnjCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  TextEditingController? _foroFieldCtrl; // controller usado pelo Autocomplete

  @override
  void initState() {
    super.initState();
    c = Get.put(ProcessCreateController());
  }

  @override
  void dispose() {
    _cnjCtrl.dispose();
    _valorCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  String? _validateCnj(String? v) {
    if (v == null || v.isEmpty) return 'Obrigatório';
    // Simplificação: validar comprimento 25
    if (v.length != 25) return 'CNJ inválido';
    return null;
  }

  String? _validateValor(String? v) {
    if (v == null || v.isEmpty) return null;
    final clean = v.replaceAll('.', '').replaceAll(',', '.');
    if (double.tryParse(clean) == null) return 'Valor inválido';
    return null;
  }

  void _addClient(ProcessClientLink link) {
    final d = c.draft.value;
    d.clients.add(link);
    c.draft.refresh();
  }

  void _togglePrimary(ProcessClientLink link) {
    final d = c.draft.value;
    for (final cl in d.clients) {
      cl.isPrimary = cl == link;
    }
    c.draft.refresh();
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Form(
          key: _formKeys[0],
          onChanged: () => c.autoSave(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _cnjCtrl,
                decoration: const InputDecoration(labelText: 'Número CNJ *'),
                validator: _validateCnj,
                onChanged: (v) => c.draft.update((d) => d!.cnj = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status *'),
                items: const [
                  DropdownMenuItem(
                    value: 'Em andamento',
                    child: Text('Em andamento'),
                  ),
                  DropdownMenuItem(
                    value: 'Concluído',
                    child: Text('Concluído'),
                  ),
                  DropdownMenuItem(value: 'Suspenso', child: Text('Suspenso')),
                ],
                value: c.draft.value.status.isEmpty
                    ? null
                    : c.draft.value.status,
                onChanged: (v) => c.draft.update((d) => d!.status = v ?? ''),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Obx(() {
                final date = c.draft.value.distributionDate;
                return InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(now.year - 10),
                      lastDate: DateTime(now.year + 1),
                      initialDate: date ?? now,
                    );
                    if (picked != null) {
                      c.draft.update((d) => d!.distributionDate = picked);
                      c.autoSave();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data de distribuição *',
                    ),
                    child: Text(
                      date == null
                          ? 'Selecionar'
                          : DateFormat('dd/MM/yyyy').format(date),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorCtrl,
                decoration: InputDecoration(labelText: 'Valor da causa (R\$)'),
                keyboardType: TextInputType.number,
                validator: _validateValor,
                onChanged: (v) {
                  final clean = v.replaceAll('.', '').replaceAll(',', '.');
                  final val = double.tryParse(clean);
                  if (val != null) c.draft.update((d) => d!.caseValue = val);
                },
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          onChanged: () => c.autoSave(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<ProcessClientLink>(
                      optionsBuilder: (text) {
                        final q = text.text.toLowerCase();
                        return c.allClients.where(
                          (cl) => cl.name.toLowerCase().contains(q),
                        );
                      },
                      displayStringForOption: (o) => o.name,
                      fieldViewBuilder: (ctx, ctrl, focus, onFieldSubmitted) =>
                          TextField(
                            controller: ctrl,
                            focusNode: focus,
                            decoration: const InputDecoration(
                              labelText: 'Cliente *',
                            ),
                          ),
                      onSelected: (sel) {
                        _addClient(
                          ProcessClientLink(
                            clientId: sel.clientId,
                            name: sel.name,
                            role: 'Autor',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Navega para criação de cliente e ao voltar poderemos futuramente atualizar a lista
                      await context.pushNamed('cliente_novo');
                      // TODO: após implementação de criação de cliente, recarregar lista de clientes (ex: c.reloadClients())
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Novo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                final list = c.draft.value.clients;
                if (list.isEmpty) {
                  return const Text('Nenhum cliente adicionado');
                }
                return Column(
                  children: list
                      .map(
                        (cl) => Card(
                          child: ListTile(
                            title: Text(cl.name),
                            subtitle: Text('Papel: ${cl.role}'),
                            leading: IconButton(
                              icon: Icon(
                                cl.isPrimary ? Icons.star : Icons.star_border,
                                color: cl.isPrimary ? Colors.amber : null,
                              ),
                              onPressed: () => _togglePrimary(cl),
                              tooltip: 'Cliente principal',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                list.remove(cl);
                                c.draft.refresh();
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              }),
            ],
          ),
        );
      case 2:
        return SingleChildScrollView(
          child: Form(
            key: _formKeys[2],
            onChanged: () => c.autoSave(),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Segmento'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Estadual',
                      child: Text('Estadual'),
                    ),
                    DropdownMenuItem(value: 'Federal', child: Text('Federal')),
                    DropdownMenuItem(
                      value: 'Trabalho',
                      child: Text('Trabalho'),
                    ),
                  ],
                  value: c.draft.value.segment.isEmpty
                      ? null
                      : c.draft.value.segment,
                  onChanged: (v) => c.draft.update((d) => d!.segment = v ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Tribunal'),
                  onChanged: (v) => c.draft.update((d) => d!.tribunal = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'UF'),
                  onChanged: (v) => c.draft.update((d) => d!.uf = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Comarca / Seção',
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.comarca = v),
                ),
                const SizedBox(height: 12),
                // Campo Foro / Vara com autocomplete e adição dinâmica
                GetX<ProcessCreateController>(
                  builder: (ctrlGet) {
                    final options = ctrlGet.foros.toList();
                    final foroAtual = ctrlGet.draft.value.foro;
                    return Autocomplete<String>(
                      optionsBuilder: (text) {
                        final q = text.text.toLowerCase();
                        return options.where(
                          (o) => o.toLowerCase().contains(q),
                        );
                      },
                      fieldViewBuilder: (ctx, textCtrl, focus, onSubmit) {
                        _foroFieldCtrl ??= textCtrl; // guarda referência
                        // sincroniza caso valor no draft tenha mudado externamente
                        if (foroAtual.isNotEmpty &&
                            textCtrl.text != foroAtual) {
                          textCtrl.text = foroAtual;
                          textCtrl.selection = TextSelection.collapsed(
                            offset: foroAtual.length,
                          );
                        }
                        return TextFormField(
                          controller: textCtrl,
                          focusNode: focus,
                          decoration: InputDecoration(
                            labelText: 'Foro / Vara',
                            suffixIcon: IconButton(
                              tooltip: 'Adicionar foro',
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                ctrlGet.addForo(textCtrl.text);
                                FocusScope.of(ctx).unfocus();
                              },
                            ),
                          ),
                          onChanged: (v) =>
                              ctrlGet.draft.update((d) => d!.foro = v),
                          onEditingComplete: () {
                            ctrlGet.addForo(textCtrl.text);
                            onSubmit();
                          },
                        );
                      },
                      onSelected: (val) {
                        // força exibição imediata
                        _foroFieldCtrl?.text = val;
                        _foroFieldCtrl?.selection = TextSelection.collapsed(
                          offset: val.length,
                        );
                        ctrlGet.draft.update((d) => d!.foro = val);
                        ctrlGet.autoSave();
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Classe processual',
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.classe = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Assunto principal',
                  ),
                  onChanged: (v) =>
                      c.draft.update((d) => d!.assuntoPrincipal = v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: c.draft.value.assuntosAdicionais
                      .map(
                        (a) => Chip(
                          label: Text(a),
                          onDeleted: () {
                            c.draft.value.assuntosAdicionais.remove(a);
                            c.draft.refresh();
                          },
                        ),
                      )
                      .toList(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final txt = await _showAddDialog('Assunto adicional');
                      if (txt != null && txt.isNotEmpty) {
                        c.draft.value.assuntosAdicionais.add(txt);
                        c.draft.refresh();
                        c.autoSave();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar assunto'),
                  ),
                ),
              ],
            ),
          ),
        );
      case 3:
        return SingleChildScrollView(
          child: Form(
            key: _formKeys[3],
            onChanged: () => c.autoSave(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Polo Ativo'),
                const SizedBox(height: 8),
                _partyList(c.draft.value.poloAtivo, true),
                const SizedBox(height: 16),
                const Text('Polo Passivo'),
                const SizedBox(height: 8),
                _partyList(c.draft.value.poloPassivo, false),
                const SizedBox(height: 24),
                const Text('Advogados do cliente'),
                const SizedBox(height: 8),
                _lawyerList(c.draft.value.advClientes, true),
                const SizedBox(height: 16),
                const Text('Advogados da parte contrária'),
                const SizedBox(height: 8),
                _lawyerList(c.draft.value.advContrarios, false),
              ],
            ),
          ),
        );
      case 4:
        return SingleChildScrollView(
          child: Form(
            key: _formKeys[4],
            onChanged: () => c.autoSave(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Sigilo'),
                  items: const [
                    DropdownMenuItem(value: 'Público', child: Text('Público')),
                    DropdownMenuItem(
                      value: 'Segredo de justiça',
                      child: Text('Segredo de justiça'),
                    ),
                  ],
                  value: c.draft.value.sigilo,
                  onChanged: (v) =>
                      c.draft.update((d) => d!.sigilo = v ?? 'Público'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Procedimento / Rito',
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.rito = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Origem'),
                  onChanged: (v) => c.draft.update((d) => d!.origem = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Número anterior',
                  ),
                  onChanged: (v) =>
                      c.draft.update((d) => d!.numeroAnterior = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Formato'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Eletrônico',
                      child: Text('Eletrônico'),
                    ),
                    DropdownMenuItem(value: 'Físico', child: Text('Físico')),
                  ],
                  value: c.draft.value.formato,
                  onChanged: (v) =>
                      c.draft.update((d) => d!.formato = v ?? 'Eletrônico'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: c.draft.value.tags
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          onDeleted: () {
                            c.draft.value.tags.remove(t);
                            c.draft.refresh();
                          },
                        ),
                      )
                      .toList(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final txt = await _showAddDialog('Tag');
                      if (txt != null && txt.isNotEmpty) {
                        c.draft.value.tags.add(txt);
                        c.draft.refresh();
                        c.autoSave();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar tag'),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Criar alerta do primeiro prazo'),
                  value: c.draft.value.criarAlertaPrimeiroPrazo,
                  onChanged: (v) =>
                      c.draft.update((d) => d!.criarAlertaPrimeiroPrazo = v),
                ),
                const SizedBox(height: 12),
                Text('Resumo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Obx(() {
                  final map = c.draft.value.toMap();
                  return Text(
                    map.toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                }),
                const SizedBox(height: 24),
                Obx(
                  () => ElevatedButton.icon(
                    onPressed: c.isSaving.value
                        ? null
                        : () async {
                            await c.saveFinal();
                            if (mounted) Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.save),
                    label: Text(
                      c.isSaving.value ? 'Salvando...' : 'Salvar Processo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = c.currentStep.value;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Novo Processo'),
          actions: [
            if (c.autoSavedAt.value != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Rascunho salvo às ${DateFormat('HH:mm:ss').format(c.autoSavedAt.value!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (ctx, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Stepper(
                    currentStep: step,
                    onStepTapped: (s) => c.setStep(s),
                    controlsBuilder: (ctx, details) {
                      final canNext = c.canGoNext;
                      return Row(
                        children: [
                          if (step < 4)
                            FilledButton(
                              onPressed: canNext ? () => c.nextStep() : null,
                              child: const Text('Avançar'),
                            ),
                          if (step == 4) const SizedBox(),
                          const SizedBox(width: 8),
                          if (step > 0)
                            OutlinedButton(
                              onPressed: () => c.prevStep(),
                              child: const Text('Voltar'),
                            ),
                        ],
                      );
                    },
                    steps: [
                      Step(
                        title: const Text('Identificação'),
                        isActive: step >= 0,
                        state: step > 0
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStepContent(0),
                      ),
                      Step(
                        title: const Text('Clientes'),
                        isActive: step >= 1,
                        state: step > 1
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStepContent(1),
                      ),
                      Step(
                        title: const Text('Juízo'),
                        isActive: step >= 2,
                        state: step > 2
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStepContent(2),
                      ),
                      Step(
                        title: const Text('Partes'),
                        isActive: step >= 3,
                        state: step > 3
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStepContent(3),
                      ),
                      Step(
                        title: const Text('Revisão'),
                        isActive: step >= 4,
                        state: step == 4
                            ? StepState.editing
                            : StepState.indexed,
                        content: _buildStepContent(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _partyList(List<Party> list, bool active) {
    return Column(
      children: [
        ...list.map(
          (p) => Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text(p.document),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  list.remove(p);
                  c.draft.refresh();
                  c.autoSave();
                },
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final name = await _showAddDialog('Nome da parte');
              if (name != null && name.isNotEmpty) {
                list.add(Party(name: name));
                c.draft.refresh();
                c.autoSave();
              }
            },
            icon: const Icon(Icons.add),
            label: Text('Adicionar parte ${active ? 'ativa' : 'passiva'}'),
          ),
        ),
      ],
    );
  }

  Widget _lawyerList(List<Lawyer> list, bool cliente) {
    return Column(
      children: [
        ...list.map(
          (l) => Card(
            child: ListTile(
              title: Text(l.name),
              subtitle: Text('OAB ${l.oab} / ${l.uf}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  list.remove(l);
                  c.draft.refresh();
                  c.autoSave();
                },
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final name = await _showAddDialog('Nome do advogado');
              if (name != null && name.isNotEmpty) {
                list.add(Lawyer(name: name, oab: '0000', uf: 'SP'));
                c.draft.refresh();
                c.autoSave();
              }
            },
            icon: const Icon(Icons.add),
            label: Text(
              'Adicionar advogado ${cliente ? 'do cliente' : 'contrário'}',
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _showAddDialog(String label) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(isDense: true),
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
  }
}
