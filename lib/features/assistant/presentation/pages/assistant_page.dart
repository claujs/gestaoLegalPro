import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../domain/models/chat_models.dart';
import '../viewmodels/assistant_view_model.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.put(AssistantViewModel());
    final cs = Theme.of(context).colorScheme;
    final scrollController = ScrollController();

    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Botão Novo Chat
              OutlinedButton.icon(
                onPressed: () => _showNewChatDialog(context, vm),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Novo Chat'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 40),
                ),
              ),
              const SizedBox(width: 8),
              // Botão Histórico
              OutlinedButton.icon(
                onPressed: () => _showHistoryDialog(context, vm),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Histórico'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 40),
                ),
              ),
              const SizedBox(width: 8),
              // Selecionar Processo
              Obx(
                () => OutlinedButton.icon(
                  onPressed: () => _showSelectProcessDialog(context, vm),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(
                    vm.selectedProcess.value == null
                        ? 'Vincular Processo'
                        : 'Processo: ${vm.selectedProcess.value!['cnj']}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Selecionar Cliente
              Obx(
                () => OutlinedButton.icon(
                  onPressed: () => _showSelectClientDialog(context, vm),
                  icon: const Icon(Icons.person_search, size: 18),
                  label: Text(
                    vm.selectedClient.value == null
                        ? 'Vincular Cliente'
                        : 'Cliente: ${vm.selectedClient.value!.name}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Quick action chips
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _QuickChip(
                      label: 'Petição Inicial',
                      onTap: () => vm.ask(
                        'Gerar petição inicial de cobrança com base no CPC, com fatos, fundamentos e pedidos.',
                      ),
                    ),
                    _QuickChip(
                      label: 'Contestação',
                      onTap: () => vm.ask(
                        'Escrever contestação em ação de indenização por danos morais, citando jurisprudência do STJ.',
                      ),
                    ),
                    _QuickChip(
                      label: 'Dúvida de Lei',
                      onTap: () => vm.ask(
                        'Explique a diferença entre decadência e prescrição no CDC com exemplos.',
                      ),
                    ),
                    _QuickChip(
                      label: 'Modelo Contrato',
                      onTap: () => vm.ask(
                        'Criar modelo de contrato de prestação de serviços simples, com cláusulas essenciais.',
                      ),
                    ),
                    _QuickChip(
                      label: '📎 Anexar Documento',
                      onTap: vm.attachDocumentAndAsk,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Banner de contexto
        Obx(() {
          final p = vm.selectedProcess.value;
          final c = vm.selectedClient.value;
          if (p == null && c == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Material(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (p != null)
                            _ContextChip(
                              icon: Icons.folder,
                              text: 'CNJ ${p['cnj']} • ${p['status']}',
                              onClear: () => vm.setSelectedProcess(null),
                            ),
                          if (c != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ContextChip(
                                  icon: Icons.person,
                                  text: '${c.name} • ${c.role}',
                                  onClear: () => vm.setSelectedClient(null),
                                ),
                                const SizedBox(width: 6),
                                Obx(
                                  () => FilterChip(
                                    showCheckmark: true,
                                    checkmarkColor: Colors.white,
                                    selectedColor: Colors.green,
                                    side: vm.useClientData.value
                                        ? BorderSide.none
                                        : const BorderSide(color: Colors.green),
                                    label: Text(
                                      vm.useClientData.value
                                          ? 'Usando dados do cliente'
                                          : 'Não usar dados do cliente',
                                    ),
                                    labelStyle: TextStyle(
                                      color: vm.useClientData.value
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                    selected: vm.useClientData.value,
                                    onSelected: (v) => vm.setUseClientData(v),
                                    avatar: Icon(
                                      Icons.verified_user,
                                      size: 18,
                                      color: vm.useClientData.value
                                          ? Colors.white
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        Expanded(
          child: Obx(() {
            final messageCount = vm.messages.length;
            final isThinking = vm.isThinking.value;
            final isProcessingDocument = vm.isProcessingDocument.value;

            // Auto-scroll apenas quando há mudanças nas mensagens
            if (messageCount > 0 || isThinking || isProcessingDocument) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients) {
                  scrollController.animateTo(
                    scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }

            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  messageCount + ((isThinking || isProcessingDocument) ? 1 : 0),
              itemBuilder: (context, index) {
                // Se está pensando ou processando documento e é o último item, mostra o indicador
                if ((isThinking || isProcessingDocument) &&
                    index == messageCount) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 720),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(14),
                        ),
                        border: Border.all(color: cs.outline.withOpacity(.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isProcessingDocument
                                ? 'Processando documento...'
                                : 'Pensando...',
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final m = vm.messages[index];
                final isUser = m.role == ChatRole.user;
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 720),
                    decoration: BoxDecoration(
                      color: isUser ? cs.primary.withOpacity(.12) : cs.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isUser ? 14 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 14),
                      ),
                      border: Border.all(color: cs.outline.withOpacity(.2)),
                    ),
                    child: SelectableText(
                      m.content,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        Obx(
          () => vm.error.value == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.error.withOpacity(.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: cs.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vm.error.value!,
                            style: TextStyle(color: cs.onErrorContainer),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: vm.clearError,
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => Shortcuts(
                      shortcuts: <LogicalKeySet, Intent>{
                        LogicalKeySet(LogicalKeyboardKey.enter):
                            const ActivateIntent(),
                        LogicalKeySet(LogicalKeyboardKey.numpadEnter):
                            const ActivateIntent(),
                      },
                      child: Actions(
                        actions: <Type, Action<Intent>>{
                          ActivateIntent: CallbackAction<ActivateIntent>(
                            onInvoke: (intent) {
                              vm.send();
                              return null;
                            },
                          ),
                        },
                        child: Focus(
                          autofocus: false,
                          child: TextField(
                            onChanged: (v) => vm.input.value = v,
                            controller:
                                TextEditingController(text: vm.input.value)
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(offset: vm.input.value.length),
                                  ),
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp('\\n')),
                            ],
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => vm.send(),
                            minLines: 1,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText:
                                  'Digite sua pergunta ou solicitação jurídica... ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão para anexar documento
                Obx(
                  () => IconButton.outlined(
                    onPressed:
                        (vm.isLoading.value || vm.isProcessingDocument.value)
                        ? null
                        : vm.attachDocumentAndAsk,
                    icon: vm.isProcessingDocument.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file),
                    tooltip: 'Anexar Documento (PDF, DOC, DOCX)',
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => IconButton.filledTonal(
                    onPressed:
                        (vm.isLoading.value || vm.isProcessingDocument.value)
                        ? null
                        : vm.send,
                    icon: vm.isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNewChatDialog(BuildContext context, AssistantViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Chat'),
        content: const Text(
          'Tem certeza que deseja iniciar um novo chat? O histórico atual será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              vm.clearChat();
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, AssistantViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Histórico de Conversas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (vm.chatHistory.isEmpty) {
                    return const Center(child: Text('Nenhum chat salvo ainda'));
                  }

                  return ListView.builder(
                    itemCount: vm.chatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = vm.chatHistory[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            chat.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _formatDate(chat.updatedAt),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteChatDialog(context, vm, chat.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            vm.loadChatFromHistory(chat);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectProcessDialog(BuildContext context, AssistantViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    final all = vm.availableProcesses;
    final searchCtrl = TextEditingController();
    List<Map<String, String>> filtered = all;

    void apply() {
      final q = searchCtrl.text.trim().toLowerCase();
      filtered = all.where((p) {
        return p['cnj']!.toLowerCase().contains(q) ||
            p['cliente']!.toLowerCase().contains(q) ||
            (p['status'] ?? '').toLowerCase().contains(q);
      }).toList();
    }

    apply();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 540),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selecionar Processo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por CNJ, cliente ou status...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(apply),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('Nenhum processo encontrado'),
                          )
                        : ListView.separated(
                            itemBuilder: (ctx, i) {
                              final p = filtered[i];
                              return ListTile(
                                leading: const Icon(Icons.folder),
                                title: Text(p['cnj'] ?? ''),
                                subtitle: Text(
                                  '${p['cliente']} • ${p['status']}',
                                ),
                                trailing: FilledButton.tonal(
                                  onPressed: () {
                                    vm.setSelectedProcess(p);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Vincular'),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                Divider(color: cs.outlineVariant),
                            itemCount: filtered.length,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSelectClientDialog(
    BuildContext context,
    AssistantViewModel vm,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final list = await vm.loadAllClients();
    final searchCtrl = TextEditingController();
    List filtered = list;

    void apply() {
      final q = searchCtrl.text.trim().toLowerCase();
      filtered = list.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.clientId.toLowerCase().contains(q) ||
            c.role.toLowerCase().contains(q);
      }).toList();
    }

    apply();

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 540),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selecionar Cliente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nome, ID ou papel...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(apply),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Nenhum cliente encontrado'))
                        : ListView.separated(
                            itemBuilder: (ctx, i) {
                              final c = filtered[i];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(c.name),
                                subtitle: Text('${c.clientId} • ${c.role}'),
                                trailing: FilledButton.tonal(
                                  onPressed: () async {
                                    final useData = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Usar dados do cliente?',
                                        ),
                                        content: Text(
                                          'Deseja enviar o nome e os dados básicos do cliente "${c.name}" para a API a fim de facilitar a integração (ex.: composição de documentos)?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text('Não usar'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Usar dados'),
                                          ),
                                        ],
                                      ),
                                    );
                                    vm.setSelectedClient(c);
                                    vm.setUseClientData(useData ?? false);
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Vincular'),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                Divider(color: cs.outlineVariant),
                            itemCount: filtered.length,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteChatDialog(
    BuildContext context,
    AssistantViewModel vm,
    String chatId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Chat'),
        content: const Text(
          'Tem certeza que deseja excluir esta conversa? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              vm.deleteChatFromHistory(chatId);
              Navigator.of(context).pop();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onClear;
  const _ContextChip({
    required this.icon,
    required this.text,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: cs.onSurface, fontSize: 12)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 14, color: cs.outline),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(label: Text(label), onPressed: onTap),
    );
  }
}
