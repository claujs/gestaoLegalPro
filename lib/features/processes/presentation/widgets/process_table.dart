import 'package:flutter/material.dart';
import 'dart:math' as math; // largura mínima

class ProcessTable extends StatelessWidget {
  final List<Map<String, String>> processes;
  final void Function(Map<String, String>) onTap;
  final void Function(String cnj, bool? value)? onSelect;
  final Set<String>? selected;
  final bool allVisibleSelected;
  final void Function(bool? v)? onToggleAll;
  final ScrollController? verticalController;
  final ScrollController? horizontalController;

  const ProcessTable({
    super.key,
    required this.processes,
    required this.onTap,
    this.onSelect,
    this.selected,
    this.allVisibleSelected = false,
    this.onToggleAll,
    this.verticalController,
    this.horizontalController,
  });

  @override
  Widget build(BuildContext context) {
    final sel = selected ?? {};
    return Scrollbar(
      controller: verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: verticalController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          child: Builder(
            builder: (ctx) {
              final screenWidth = MediaQuery.of(ctx).size.width;
              final tableWidth = math.max(
                900,
                screenWidth - 48,
              ); // padding estimado
              return SizedBox(
                width: tableWidth.toDouble(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DataTable(
                      columnSpacing: 32,
                      headingRowHeight: 48,
                      columns: [
                        DataColumn(
                          label: Row(
                            children: [
                              if (onSelect != null)
                                Checkbox(
                                  value:
                                      allVisibleSelected &&
                                      processes.isNotEmpty,
                                  onChanged: onToggleAll,
                                ),
                              const Text('Nº CNJ'),
                            ],
                          ),
                        ),
                        const DataColumn(label: Text('Cliente')),
                        const DataColumn(label: Text('Último Andamento')),
                        const DataColumn(label: Text('Status')),
                      ],
                      rows: [
                        for (int i = 0; i < processes.length; i++)
                          DataRow(
                            selected: sel.contains(processes[i]['cnj']),
                            color: WidgetStateProperty.resolveWith(
                              (states) => i.isEven
                                  ? Theme.of(context).colorScheme.surface
                                  : Theme.of(context).colorScheme.surfaceVariant
                                        .withOpacity(.3),
                            ),
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    if (onSelect != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Checkbox(
                                          value: sel.contains(
                                            processes[i]['cnj'],
                                          ),
                                          onChanged: (v) => onSelect!(
                                            processes[i]['cnj']!,
                                            v,
                                          ),
                                        ),
                                      ),
                                    _cellText(processes[i]['cnj']!),
                                  ],
                                ),
                              ),
                              DataCell(_cellText(processes[i]['cliente']!)),
                              DataCell(_cellText(processes[i]['andamento']!)),
                              DataCell(_statusChip(processes[i]['status']!)),
                            ],
                            onSelectChanged: (_) => onTap(processes[i]),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 96,
                    ), // espaço para barra de paginação
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cellText(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
  );

  Widget _statusChip(String status) {
    final color = status == 'Ativo' ? Colors.green : Colors.grey;
    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(.15),
      labelStyle: TextStyle(color: color.shade700),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}
