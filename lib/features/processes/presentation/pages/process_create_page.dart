import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart'; // adicionado para navegação ao cadastro de cliente
import '../viewmodels/process_create_view_model.dart';
import '../../domain/models/process_models.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/process_create_texts.dart';

class ProcessCreatePage extends StatefulWidget {
  const ProcessCreatePage({super.key});
  static const route = '/processos/novo';

  @override
  State<ProcessCreatePage> createState() => _ProcessCreatePageState();
}

class _ProcessCreatePageState extends State<ProcessCreatePage> {
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());
  late final ProcessCreateViewModel c;
  final _cnjCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  TextEditingController? _foroFieldCtrl; // controller usado pelo Autocomplete

  @override
  void initState() {
    super.initState();
    c = Get.put(ProcessCreateViewModel());
  }

  @override
  void dispose() {
    _cnjCtrl.dispose();
    _valorCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  String? _validateCnj(String? v) {
    if (v == null || v.isEmpty) return ProcessCreateTexts.obrigatorio;
    // Simplificação: validar comprimento 25
    if (v.length != 25) return ProcessCreateTexts.cnjInvalido;
    return null;
  }

  String? _validateValor(String? v) {
    if (v == null || v.isEmpty) return null;
    final clean = v.replaceAll('.', '').replaceAll(',', '.');
    if (double.tryParse(clean) == null) return ProcessCreateTexts.valorInvalido;
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
                decoration: const InputDecoration(
                  labelText: ProcessCreateTexts.numeroCnj,
                ),
                validator: _validateCnj,
                onChanged: (v) => c.draft.update((d) => d!.cnj = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: ProcessCreateTexts.status,
                ),
                items: const [
                  DropdownMenuItem(
                    value: ProcessCreateTexts.statusEmAndamento,
                    child: Text(ProcessCreateTexts.statusEmAndamento),
                  ),
                  DropdownMenuItem(
                    value: ProcessCreateTexts.statusConcluido,
                    child: Text(ProcessCreateTexts.statusConcluido),
                  ),
                  DropdownMenuItem(
                    value: ProcessCreateTexts.statusSuspenso,
                    child: Text(ProcessCreateTexts.statusSuspenso),
                  ),
                ],
                value: c.draft.value.status.isEmpty
                    ? null
                    : c.draft.value.status,
                onChanged: (v) => c.draft.update((d) => d!.status = v ?? ''),
                validator: (v) => v == null || v.isEmpty
                    ? ProcessCreateTexts.obrigatorio
                    : null,
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
                      labelText: ProcessCreateTexts.dataDistribuicao,
                    ),
                    child: Text(
                      date == null
                          ? ProcessCreateTexts.selecionar
                          : DateFormat('dd/MM/yyyy').format(date),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorCtrl,
                decoration: const InputDecoration(
                  labelText: ProcessCreateTexts.valorCausa,
                ),
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
                              labelText: ProcessCreateTexts.clienteCampo,
                            ),
                          ),
                      onSelected: (sel) {
                        _addClient(
                          ProcessClientLink(
                            clientId: sel.clientId,
                            name: sel.name,
                            role: ProcessCreateTexts.selecionarRoleAutor,
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
                    label: const Text(ProcessCreateTexts.novo),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                final list = c.draft.value.clients;
                if (list.isEmpty) {
                  return const Text(ProcessCreateTexts.nenhumClienteAdicionado);
                }
                return Column(
                  children: list
                      .map(
                        (cl) => Card(
                          child: ListTile(
                            title: Text(cl.name),
                            subtitle: Text(
                              '${ProcessCreateTexts.papelPrefix}${cl.role}',
                            ),
                            leading: IconButton(
                              icon: Icon(
                                cl.isPrimary ? Icons.star : Icons.star_border,
                                color: cl.isPrimary ? Colors.amber : null,
                              ),
                              onPressed: () => _togglePrimary(cl),
                              tooltip:
                                  ProcessCreateTexts.clientePrincipalTooltip,
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
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.segmento,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ProcessCreateTexts.estadual,
                      child: Text(ProcessCreateTexts.estadual),
                    ),
                    DropdownMenuItem(
                      value: ProcessCreateTexts.federal,
                      child: Text(ProcessCreateTexts.federal),
                    ),
                    DropdownMenuItem(
                      value: ProcessCreateTexts.trabalho,
                      child: Text(ProcessCreateTexts.trabalho),
                    ),
                  ],
                  value: c.draft.value.segment.isEmpty
                      ? null
                      : c.draft.value.segment,
                  onChanged: (v) => c.draft.update((d) => d!.segment = v ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.tribunal,
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.tribunal = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.uf,
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.uf = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.comarcaSecao,
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.comarca = v),
                ),
                const SizedBox(height: 12),
                // Campo Foro / Vara com autocomplete e adição dinâmica
                GetX<ProcessCreateViewModel>(
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
                            labelText: ProcessCreateTexts.foroVara,
                            suffixIcon: IconButton(
                              tooltip: ProcessCreateTexts.adicionarForoTooltip,
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
                    labelText: ProcessCreateTexts.classeProcessual,
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.classe = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.assuntoPrincipal,
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
                      final txt = await _showAddDialog(
                        ProcessCreateTexts.assuntoAdicional,
                      );
                      if (txt != null && txt.isNotEmpty) {
                        c.draft.value.assuntosAdicionais.add(txt);
                        c.draft.refresh();
                        c.autoSave();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(ProcessCreateTexts.adicionarAssunto),
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
                const Text(ProcessCreateTexts.poloAtivo),
                const SizedBox(height: 8),
                _partyList(c.draft.value.poloAtivo, true),
                const SizedBox(height: 16),
                const Text(ProcessCreateTexts.poloPassivo),
                const SizedBox(height: 8),
                _partyList(c.draft.value.poloPassivo, false),
                const SizedBox(height: 24),
                const Text(ProcessCreateTexts.advClientes),
                const SizedBox(height: 8),
                _lawyerList(c.draft.value.advClientes, true),
                const SizedBox(height: 16),
                const Text(ProcessCreateTexts.advContrarios),
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
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.sigilo,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ProcessCreateTexts.sigiloPublico,
                      child: Text(ProcessCreateTexts.sigiloPublico),
                    ),
                    DropdownMenuItem(
                      value: ProcessCreateTexts.sigiloSegredo,
                      child: Text(ProcessCreateTexts.sigiloSegredo),
                    ),
                  ],
                  value: c.draft.value.sigilo,
                  onChanged: (v) =>
                      c.draft.update((d) => d!.sigilo = v ?? 'Público'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.procedimentoRito,
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.rito = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.origem,
                  ),
                  onChanged: (v) => c.draft.update((d) => d!.origem = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.numeroAnterior,
                  ),
                  onChanged: (v) =>
                      c.draft.update((d) => d!.numeroAnterior = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: ProcessCreateTexts.formato,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ProcessCreateTexts.formatoEletronico,
                      child: Text(ProcessCreateTexts.formatoEletronico),
                    ),
                    DropdownMenuItem(
                      value: ProcessCreateTexts.formatoFisico,
                      child: Text(ProcessCreateTexts.formatoFisico),
                    ),
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
                      final txt = await _showAddDialog(ProcessCreateTexts.tag);
                      if (txt != null && txt.isNotEmpty) {
                        c.draft.value.tags.add(txt);
                        c.draft.refresh();
                        c.autoSave();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(ProcessCreateTexts.adicionarTag),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    ProcessCreateTexts.criarAlertaPrimeiroPrazo,
                  ),
                  value: c.draft.value.criarAlertaPrimeiroPrazo,
                  onChanged: (v) =>
                      c.draft.update((d) => d!.criarAlertaPrimeiroPrazo = v),
                ),
                const SizedBox(height: 12),
                Text(
                  ProcessCreateTexts.resumo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                      c.isSaving.value
                          ? ProcessCreateTexts.salvando
                          : ProcessCreateTexts.salvarProcesso,
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
          title: const Text(ProcessCreateTexts.novoProcesso),
          actions: [
            if (c.autoSavedAt.value != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${ProcessCreateTexts.rascunhoSalvoPrefix}${DateFormat('HH:mm:ss').format(c.autoSavedAt.value!)}',
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
                              child: const Text(ProcessCreateTexts.avancar),
                            ),
                          if (step == 4) const SizedBox(),
                          const SizedBox(width: 8),
                          if (step > 0)
                            OutlinedButton(
                              onPressed: () => c.prevStep(),
                              child: const Text(ProcessCreateTexts.voltar),
                            ),
                        ],
                      );
                    },
                    steps: [
                      Step(
                        title: const Text(ProcessCreateTexts.identificacao),
                        isActive: step >= 0,
                        state: step > 0
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStepContent(0),
                      ),
                      Step(
                        title: const Text(ProcessCreateTexts.clientes),
                        isActive: step >= 1,
                        state: step > 1
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStepContent(1),
                      ),
                      Step(
                        title: const Text(ProcessCreateTexts.juizo),
                        isActive: step >= 2,
                        state: step > 2
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStepContent(2),
                      ),
                      Step(
                        title: const Text(ProcessCreateTexts.partes),
                        isActive: step >= 3,
                        state: step > 3
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStepContent(3),
                      ),
                      Step(
                        title: const Text(ProcessCreateTexts.revisao),
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
              final name = await _showAddDialog(ProcessCreateTexts.nomeDaParte);
              if (name != null && name.isNotEmpty) {
                list.add(Party(name: name));
                c.draft.refresh();
                c.autoSave();
              }
            },
            icon: const Icon(Icons.add),
            label: Text(ProcessCreateTexts.adicionarParte(active)),
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
              final name = await _showAddDialog(
                ProcessCreateTexts.nomeAdvogado,
              );
              if (name != null && name.isNotEmpty) {
                list.add(Lawyer(name: name, oab: '0000', uf: 'SP'));
                c.draft.refresh();
                c.autoSave();
              }
            },
            icon: const Icon(Icons.add),
            label: Text(ProcessCreateTexts.adicionarAdvogado(cliente)),
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
            child: const Text(ProcessCreateTexts.cancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text(ProcessCreateTexts.ok),
          ),
        ],
      ),
    );
    return result;
  }
}
