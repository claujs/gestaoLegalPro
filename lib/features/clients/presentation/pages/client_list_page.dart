import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math' as math; // adicionado para cálculo de largura mínima
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http; // busca CEP
import 'dart:convert'; // para jsonDecode
import '../../../processes/presentation/viewmodels/process_list_view_model.dart';
import '../../data/process_client_link_adapter.dart';
import '../../data/mock_clientes.dart';
import '../../../processes/domain/models/process_models.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({Key? key}) : super(key: key);

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class ClientExtendedData {
  String nome;
  String sobrenome;
  String cpf;
  String endereco; // manter agregado (legado)
  String estado;
  String cidade;
  // Novos campos detalhados de endereço
  String cep;
  String bairro;
  String logradouro;
  String numero;
  String complemento;
  List<String> processos; // lista de CNJ
  Map<String, List<String>> audiencias; // chave categoria -> descrições
  ClientExtendedData({
    required this.nome,
    this.sobrenome = '',
    this.cpf = '',
    this.endereco = '',
    this.estado = '',
    this.cidade = '',
    this.cep = '',
    this.bairro = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    List<String>? processos,
    Map<String, List<String>>? audiencias,
  }) : processos = processos ?? [],
       audiencias =
           audiencias ??
           {
             'Futuros': [],
             'Presentes': [],
             'Realizados': [],
             'Finalizados': [],
           };
}

class _ClientListPageState extends State<ClientListPage> {
  final TextEditingController _buscaCtrl = TextEditingController();
  TextEditingController? _autoCtrl; // referência ao campo do Autocomplete
  String? _roleFiltro;
  bool _somentePrincipais = false;
  final Map<String, List<String>> _clienteProcessos =
      {}; // clientId -> lista de CNJ

  final _verticalScroll = ScrollController();
  final _horizontalScroll = ScrollController();

  List<ProcessClientLink> _todos = [];
  bool _carregando = true;
  int _page = 0;
  int _pageSize = 10;

  final Map<String, ClientExtendedData> _extended = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    await Hive.openBox<ProcessClientLinkHive>('clientes');
    final box = Hive.box<ProcessClientLinkHive>('clientes');
    final hiveClientes = box.values.map((e) => e.toModel()).toList();
    setState(() {
      _todos = [...hiveClientes, ...mockClientes];
      _carregando = false;
      _page = 0;
    });
  }

  List<ProcessClientLink> get _filtrados {
    final q = _buscaCtrl.text.trim().toLowerCase();
    return _todos.where((c) {
      final matchBusca =
          q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.clientId.toLowerCase().contains(q) ||
          _sobrenome(c.name).toLowerCase().contains(q);
      final matchRole = _roleFiltro == null || c.role == _roleFiltro;
      final matchPrincipal = !_somentePrincipais || c.isPrimary;
      return matchBusca && matchRole && matchPrincipal;
    }).toList();
  }

  String? _primeiroProcessoDoCliente(String clientName) {
    try {
      final procCtrl = Get.find<ProcessListViewModel>();
      final proc = procCtrl.processes.firstWhereOrNull(
        (p) => p['cliente'] == clientName,
      );
      return proc?['cnj'];
    } catch (_) {
      return null;
    }
  }

  List<ProcessClientLink> get _paginados {
    final f = _filtrados;
    final start = _page * _pageSize;
    if (start >= f.length) return [];
    final end = start + _pageSize;
    return f.sublist(start, end > f.length ? f.length : end);
  }

  int get _totalPages => (_filtrados.length / _pageSize).ceil();

  String _sobrenome(String nome) {
    final parts = nome.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  void _aplicarBusca() {
    setState(() => _page = 0);
  }

  void _limpar() {
    setState(() {
      _buscaCtrl.clear();
      _autoCtrl?.clear(); // limpa campo visível
      _roleFiltro = null;
      _somentePrincipais = false;
      _page = 0;
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = _todos.map((e) => e.role).toSet().toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: FilledButton.icon(
                onPressed: () {
                  // Abre o cadastro existente de cliente
                  context.push('/dashboard/clientes/novo');
                },
                icon: const Icon(Icons.add),
                label: const Text('Novo Cliente'),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 240,
                  child: Autocomplete<ProcessClientLink>(
                    optionsBuilder: (text) {
                      final q = text.text.toLowerCase();
                      if (q.isEmpty) return const Iterable.empty();
                      return _todos.where(
                        (c) =>
                            c.name.toLowerCase().contains(q) ||
                            c.clientId.toLowerCase().contains(q),
                      );
                    },
                    displayStringForOption: (o) => o.name,
                    fieldViewBuilder: (ctx, ctrl, focus, submit) {
                      _autoCtrl = ctrl; // guarda referência para limpar depois
                      return TextField(
                        controller: ctrl,
                        focusNode: focus,
                        decoration: const InputDecoration(
                          labelText: 'Nome / CPF',
                          isDense: true,
                        ),
                        onChanged: (v) {
                          if (_buscaCtrl.text != v) {
                            _buscaCtrl.text = v;
                          }
                          _aplicarBusca();
                        },
                        onSubmitted: (_) => _aplicarBusca(),
                      );
                    },
                    onSelected: (sel) {
                      _buscaCtrl.text = sel.name; // ou sel.clientId
                      _autoCtrl?.text = sel.name; // mantém sincronizado
                      _aplicarBusca();
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _roleFiltro,
                    items: [
                      for (final r in roles)
                        DropdownMenuItem(value: r, child: Text(r)),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Papel',
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() {
                      _roleFiltro = v;
                      _page = 0;
                    }),
                  ),
                ),
                FilterChip(
                  label: const Text('Somente principais'),
                  selected: _somentePrincipais,
                  onSelected: (v) => setState(() {
                    _somentePrincipais = v;
                    _page = 0;
                  }),
                ),
                FilledButton(
                  onPressed: _aplicarBusca,
                  child: const Text('Buscar'),
                ),
                OutlinedButton(onPressed: _limpar, child: const Text('Limpar')),
                DropdownButton<int>(
                  value: _pageSize,
                  items: const [10, 20, 50]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) {
                      _pageSize = v;
                      _page = 0;
                    }
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _filtrados.isEmpty
          ? const Center(child: Text('Nenhum cliente encontrado.'))
          : Stack(
              children: [
                Positioned.fill(
                  child: Scrollbar(
                    controller: _verticalScroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalScroll,
                      child: SingleChildScrollView(
                        controller: _horizontalScroll,
                        scrollDirection: Axis.horizontal,
                        child: Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(
                              context,
                            ).size.width;
                            final tableWidth = math.max(
                              800,
                              screenWidth - 32,
                            ); // 32 ~ padding horizontal
                            return SizedBox(
                              width: tableWidth.toDouble(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DataTable(
                                    columnSpacing: 32,
                                    headingRowHeight: 48,
                                    columns: const [
                                      DataColumn(label: Text('Nome')),
                                      DataColumn(label: Text('CPF/ID')),
                                      DataColumn(label: Text('Nº Processo')),
                                      DataColumn(label: Text('Papel')),
                                      DataColumn(label: Text('Principal')),
                                    ],
                                    rows: [
                                      for (
                                        int i = 0;
                                        i < _paginados.length;
                                        i++
                                      )
                                        DataRow(
                                          // cor e cells já definidos anteriormente, reaproveitar lógica existente
                                          color:
                                              WidgetStateProperty.resolveWith(
                                                (states) => i.isEven
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.surface
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .surfaceVariant
                                                          .withOpacity(.3),
                                              ),
                                          cells: [
                                            DataCell(
                                              _cellText(_paginados[i].name),
                                            ),
                                            DataCell(
                                              _cellText(_paginados[i].clientId),
                                            ),
                                            DataCell(
                                              _cellText(
                                                _primeiroProcessoDoCliente(
                                                      _paginados[i].name,
                                                    ) ??
                                                    '-',
                                              ),
                                            ),
                                            DataCell(
                                              _cellText(_paginados[i].role),
                                            ),
                                            DataCell(
                                              Icon(
                                                _paginados[i].isPrimary
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: _paginados[i].isPrimary
                                                    ? Colors.amber
                                                    : null,
                                              ),
                                            ),
                                          ],
                                          onSelectChanged: (_) =>
                                              _openClienteDrawer(_paginados[i]),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 96,
                                  ), // espaço para paginação
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(.95),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Página ${_page + 1} de ${_totalPages == 0 ? 1 : _totalPages}  •  ${_filtrados.length} itens',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Primeira',
                            onPressed: _page <= 0
                                ? null
                                : () => setState(() => _page = 0),
                            icon: const Icon(Icons.first_page, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Anterior',
                            onPressed: _page <= 0
                                ? null
                                : () => setState(() => _page--),
                            icon: const Icon(Icons.chevron_left, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Próxima',
                            onPressed: _page >= _totalPages - 1
                                ? null
                                : () => setState(() => _page++),
                            icon: const Icon(Icons.chevron_right, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Última',
                            onPressed: _page >= _totalPages - 1
                                ? null
                                : () => setState(() => _page = _totalPages - 1),
                            icon: const Icon(Icons.last_page, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _cellText(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
  );

  void _openClienteDrawer(ProcessClientLink cliente) {
    // inicializa dados estendidos se não existir
    _extended.putIfAbsent(
      cliente.clientId,
      () => ClientExtendedData(
        nome: cliente.name.split(' ').first,
        sobrenome: _sobrenome(cliente.name),
        processos: [...?_clienteProcessos[cliente.clientId]],
        audiencias: {
          'Futuros': ['Audiência de conciliação 12/09/2025 14:00'],
          'Presentes': ['Audiência instrução agora 10:30'],
          'Realizados': ['Audiência inicial 05/08/2025 concluída'],
          'Finalizados': ['Sessão julgamento 22/07/2025'],
        },
      ),
    );
    final data = _extended[cliente.clientId]!;
    final procCtrl = Get.isRegistered<ProcessListViewModel>()
        ? Get.find<ProcessListViewModel>()
        : null;
    final processos = (procCtrl?.processes ?? []).cast<Map<String, String>>();
    final width = MediaQuery.of(context).size.width;

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(ctx).maybePop(),
              child: Opacity(
                opacity: anim.value,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            SlideTransition(
              position: offset,
              child: Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 12,
                  shadowColor: Colors.black45,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: width.clamp(420, 640),
                    child: _ClienteDrawerContent(
                      cliente: cliente,
                      data: data,
                      processos: processos,
                      onSave: (updated, procs) {
                        setState(() {
                          cliente.name = '${updated.nome} ${updated.sobrenome}'
                              .trim();
                          cliente.isPrimary = cliente.isPrimary; // mantém
                          _clienteProcessos[cliente.clientId] = procs;
                          _extended[cliente.clientId] = updated;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClienteDrawerContent extends StatefulWidget {
  final ProcessClientLink cliente;
  final ClientExtendedData data;
  final List<Map<String, String>> processos;
  final void Function(ClientExtendedData updated, List<String> processos)
  onSave;
  const _ClienteDrawerContent({
    required this.cliente,
    required this.data,
    required this.processos,
    required this.onSave,
  });
  @override
  State<_ClienteDrawerContent> createState() => _ClienteDrawerContentState();
}

class _ClienteDrawerContentState extends State<_ClienteDrawerContent>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nomeCtrl;
  late TextEditingController _sobrenomeCtrl;
  late TextEditingController _cpfCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _estadoCtrl;
  late TextEditingController _cidadeCtrl;
  late TabController _tabCtrl;
  late List<String> _vinculados; // CNJs

  late TextEditingController _cepCtrl;
  late TextEditingController _bairroCtrl;
  late TextEditingController _logradouroCtrl;
  late TextEditingController _numeroCtrl;
  late TextEditingController _complCtrl;
  bool _loadingCep = false;
  String? _cepError;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _nomeCtrl = TextEditingController(text: d.nome);
    _sobrenomeCtrl = TextEditingController(text: d.sobrenome);
    _cpfCtrl = TextEditingController(text: d.cpf);
    _endCtrl = TextEditingController(text: d.endereco);
    _estadoCtrl = TextEditingController(text: d.estado);
    _cidadeCtrl = TextEditingController(text: d.cidade);
    _vinculados = [...d.processos];
    _tabCtrl = TabController(length: 4, vsync: this);
    _cepCtrl = TextEditingController(text: d.cep);
    _bairroCtrl = TextEditingController(text: d.bairro);
    _logradouroCtrl = TextEditingController(text: d.logradouro);
    _numeroCtrl = TextEditingController(text: d.numero);
    _complCtrl = TextEditingController(text: d.complemento);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _sobrenomeCtrl.dispose();
    _cpfCtrl.dispose();
    _endCtrl.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _tabCtrl.dispose();
    _cepCtrl.dispose();
    _bairroCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _complCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Cliente',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Dados Básicos'),
                    _twoCols([
                      TextField(
                        controller: _nomeCtrl,
                        decoration: const InputDecoration(labelText: 'Nome'),
                      ),
                      TextField(
                        controller: _sobrenomeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sobrenome',
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _twoCols([
                      TextField(
                        controller: _cpfCtrl,
                        decoration: const InputDecoration(labelText: 'CPF'),
                      ),
                      TextField(
                        controller: _endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Endereço',
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _twoCols([
                      TextField(
                        controller: _estadoCtrl,
                        decoration: const InputDecoration(labelText: 'Estado'),
                      ),
                      TextField(
                        controller: _cidadeCtrl,
                        decoration: const InputDecoration(labelText: 'Cidade'),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    _sectionTitle('Endereço'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cepCtrl,
                            decoration: InputDecoration(
                              labelText: 'CEP',
                              errorText: _cepError,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final only = v.replaceAll(RegExp(r'[^0-9]'), '');
                              final masked = _maskCep(only);
                              if (masked != v) {
                                final cursor = masked.length;
                                _cepCtrl.value = TextEditingValue(
                                  text: masked,
                                  selection: TextSelection.collapsed(
                                    offset: cursor,
                                  ),
                                );
                              }
                              if (only.length == 8) {
                                _fetchCep(masked);
                              }
                            },
                            onSubmitted: _fetchCep,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _loadingCep
                                ? null
                                : () => _fetchCep(_cepCtrl.text),
                            icon: _loadingCep
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(_loadingCep ? 'Buscando...' : 'Buscar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _twoCols([
                      TextField(
                        controller: _bairroCtrl,
                        decoration: const InputDecoration(labelText: 'Bairro'),
                      ),
                      TextField(
                        controller: _logradouroCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Logradouro',
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _twoCols([
                      TextField(
                        controller: _numeroCtrl,
                        decoration: const InputDecoration(labelText: 'Número'),
                      ),
                      TextField(
                        controller: _complCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Complemento',
                        ),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    _sectionTitle('Processos Vinculados'),
                    const SizedBox(height: 8),
                    if (widget.processos.isEmpty)
                      const Text('Nenhum processo carregado.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.processos.take(100).map((p) {
                          final cnj = p['cnj']!;
                          final sel = _vinculados.contains(cnj);
                          return FilterChip(
                            label: Text(
                              cnj,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: sel,
                            onSelected: (v) => setState(() {
                              if (v) {
                                _vinculados.add(cnj);
                              } else {
                                _vinculados.remove(cnj);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 28),
                    _sectionTitle('Audiências'),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabCtrl,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Futuros'),
                        Tab(text: 'Presentes'),
                        Tab(text: 'Realizados'),
                        Tab(text: 'Finalizados'),
                      ],
                    ),
                    SizedBox(
                      height: 220,
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          for (final cat in [
                            'Futuros',
                            'Presentes',
                            'Realizados',
                            'Finalizados',
                          ])
                            _audienciasList(cat),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String txt) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      txt,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _twoCols(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 16),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }

  Widget _audienciasList(String cat) {
    final list = widget.data.audiencias[cat] ?? [];
    if (list.isEmpty) {
      return Center(
        child: Text(
          'Sem registros',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 12),
      itemCount: list.length,
      itemBuilder: (_, i) => ListTile(
        dense: true,
        leading: const Icon(Icons.event_note, size: 20),
        title: Text(list[i], style: const TextStyle(fontSize: 13)),
        trailing: IconButton(
          tooltip: 'Detalhes',
          icon: const Icon(Icons.open_in_new, size: 18),
          onPressed: () {},
        ),
      ),
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }

  void _salvar() {
    final updated = ClientExtendedData(
      nome: _nomeCtrl.text.trim(),
      sobrenome: _sobrenomeCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim(),
      estado: _estadoCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim(),
      cep: _cepCtrl.text.trim(),
      bairro: _bairroCtrl.text.trim(),
      logradouro: _logradouroCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      complemento: _complCtrl.text.trim(),
      endereco: '${_logradouroCtrl.text.trim()}, ${_numeroCtrl.text.trim()}',
      processos: _vinculados,
      audiencias: widget.data.audiencias,
    );
    widget.onSave(updated, _vinculados);
    Navigator.of(context).maybePop();
  }

  Future<void> _fetchCep(String raw) async {
    final cepOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepOnly.length != 8) {
      setState(() => _cepError = 'CEP inválido');
      return;
    }
    final masked = _maskCep(cepOnly);
    if (_cepCtrl.text != masked) _cepCtrl.text = masked;
    setState(() {
      _loadingCep = true;
      _cepError = null;
    });
    try {
      final uri = Uri.parse('https://brasilapi.com.br/api/cep/v1/$cepOnly');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final map = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _estadoCtrl.text = map['state']?.toString() ?? _estadoCtrl.text;
          _cidadeCtrl.text = map['city']?.toString() ?? _cidadeCtrl.text;
          _bairroCtrl.text =
              map['neighborhood']?.toString() ?? _bairroCtrl.text;
          _logradouroCtrl.text =
              map['street']?.toString() ?? _logradouroCtrl.text;
        });
      } else {
        setState(() => _cepError = 'CEP não encontrado');
      }
    } catch (_) {
      setState(() => _cepError = 'Erro ao consultar CEP');
    } finally {
      setState(() => _loadingCep = false);
    }
  }

  String _maskCep(String digits) => digits.length <= 5
      ? digits
      : '${digits.substring(0, 5)}-${digits.substring(5)}';
}
