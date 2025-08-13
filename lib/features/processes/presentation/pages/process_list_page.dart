import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../pages/process_detail_page.dart';
import '../widgets/process_table.dart';
import '../controllers/process_controller.dart';

class ProcessListPage extends StatefulWidget {
  const ProcessListPage({super.key});
  static const route = '/processos';

  @override
  State<ProcessListPage> createState() => _ProcessListPageState();
}

class _ProcessListPageState extends State<ProcessListPage> {
  final _cnjCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  String? _status;
  final _verticalScroll = ScrollController();
  final _horizontalScroll = ScrollController();

  final _controller = Get.find<ProcessController>();
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    if (_controller.processes.isEmpty) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    _cnjCtrl.dispose();
    _clienteCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    _controller.applyFilters(
      cnj: _cnjCtrl.text,
      cliente: _clienteCtrl.text,
      status: _status ?? '',
    );
  }

  void _clearFilter() {
    _controller.clearFilters();
    _cnjCtrl.clear();
    _clienteCtrl.clear();
    setState(() => _status = null);
  }

  bool get _allVisibleSelected =>
      _controller.paginated.isNotEmpty &&
      _controller.paginated.every((p) => _selected.contains(p['cnj']));

  void _toggleSelectAll(bool? v) {
    setState(() {
      if (v == true) {
        _selected.addAll(_controller.paginated.map((p) => p['cnj']!));
      } else {
        _selected.removeWhere(
          (cnj) => _controller.paginated.any((p) => p['cnj'] == cnj),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processos'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: FilledButton.icon(
                onPressed: () => context.push('/dashboard/processos/novo'),
                icon: const Icon(Icons.add),
                label: const Text('Novo Processo'),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${_selected.length} selecionado(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
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
                  width: 200,
                  child: TextField(
                    controller: _cnjCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número CNJ',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _clienteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
                      DropdownMenuItem(
                        value: 'Arquivado',
                        child: Text('Arquivado'),
                      ),
                      DropdownMenuItem(
                        value: 'Suspenso',
                        child: Text('Suspenso'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
                FilledButton(
                  onPressed: _applyFilter,
                  child: const Text('Buscar'),
                ),
                OutlinedButton(
                  onPressed: _clearFilter,
                  child: const Text('Limpar'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        final loading = _controller.isLoading.value;
        final page = _controller.page.value;
        final totalPages = _controller.totalPages;
        final data = _controller.paginated;
        return Stack(
          children: [
            Positioned.fill(
              child: ProcessTable(
                processes: data,
                selected: _selected,
                allVisibleSelected: _allVisibleSelected,
                onToggleAll: _toggleSelectAll,
                onTap: (p) {
                  context.push(
                    '/dashboard/processos/processo',
                    extra: ProcessDetailArgs(process: p),
                  );
                },
                onSelect: (cnj, v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(cnj);
                    } else {
                      _selected.remove(cnj);
                    }
                  });
                },
                verticalController: _verticalScroll,
                horizontalController: _horizontalScroll,
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              left: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface.withOpacity(.95),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Página ${page + 1} de ${totalPages == 0 ? 1 : totalPages}  •  ${_controller.filtered.length} itens',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Primeira',
                        onPressed: page <= 0
                            ? null
                            : () => _controller.setPage(0),
                        icon: const Icon(Icons.first_page, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Anterior',
                        onPressed: page <= 0 ? null : _controller.prevPage,
                        icon: const Icon(Icons.chevron_left, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Próxima',
                        onPressed: page >= totalPages - 1
                            ? null
                            : _controller.nextPage,
                        icon: const Icon(Icons.chevron_right, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Última',
                        onPressed: page >= totalPages - 1
                            ? null
                            : () => _controller.setPage(totalPages - 1),
                        icon: const Icon(Icons.last_page, size: 20),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _controller.pageSize.value,
                        items: const [10, 20, 50, 100]
                            .map(
                              (e) =>
                                  DropdownMenuItem(value: e, child: Text('$e')),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            _controller.pageSize.value = v;
                            _controller.page.value = 0;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(.05),
                  child: const Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(strokeWidth: 4),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
