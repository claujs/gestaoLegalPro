import 'dart:async';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../../core/controllers/base_view_model.dart';
import '../../domain/models/chat_models.dart';
import '../../domain/services/assistant_service.dart';
import '../../domain/services/chat_history_service.dart';
import '../../domain/services/document_service.dart';
import '../../../../core/di/locator.dart';
import '../../../processes/presentation/viewmodels/process_list_view_model.dart';
import '../../../processes/domain/models/process_models.dart';
import '../../../clients/data/process_client_link_adapter.dart';
import '../../../clients/data/mock_clientes.dart';

class AssistantViewModel extends BaseViewModel {
  final AssistantService _service = locator.get<AssistantService>();
  final ChatHistoryService _historyService = locator.get<ChatHistoryService>();
  final DocumentService _documentService = locator.get<DocumentService>();

  final messages = <ChatMessage>[].obs;
  final input = ''.obs;
  final chatHistory = <ChatSession>[].obs;
  final isThinking = false.obs;
  final isProcessingDocument = false.obs;
  final selectedProcess = Rxn<Map<String, String>>();
  final selectedClient = Rxn<ProcessClientLink>();
  final useClientData =
      false.obs; // quando true, envia dados do cliente no prompt
  final pendingDocumentText = RxnString();
  final pendingDocumentName = RxnString();

  String? _currentChatId;
  String _currentChatTitle = '';
  Completer<void>? _currentRequest;

  @override
  void onInit() {
    super.onInit();
    _loadChatHistory();
    // Mensagem de boas-vindas com instruções
    messages.add(
      ChatMessage.assistant(
        'Olá! Sou seu assistente jurídico. Posso redigir petições, auxiliar na criação de processos e tirar dúvidas sobre leis.\n'
        'Exemplos: "Gerar petição inicial de cobrança", "Dúvida sobre prescrição no CDC", "Checklist para abertura de processo trabalhista".',
      ),
    );
  }

  Future<void> send() async {
    final text = input.value.trim();
    if (text.isEmpty) return;

    // Cancela qualquer requisição anterior
    _cancelCurrentRequest();

    // Se é a primeira mensagem de usuário, gera ID e título do chat
    if (_currentChatId == null) {
      _startNewChat(text);
    }

    final fullText = _withContext(text);
    messages.add(ChatMessage.user(text));
    input.value = '';
    setLoading(true);
    isThinking.value = true;
    clearError(); // Limpa erro anterior

    // Cria um novo completer para esta requisição
    _currentRequest = Completer<void>();

    try {
      final res = await _service.sendMessage(ChatRequest(fullText));

      // Verifica se a requisição foi cancelada
      if (_currentRequest?.isCompleted == true) {
        return; // Requisição foi cancelada
      }

      isThinking.value = false;
      messages.add(ChatMessage.assistant(res.response));
      // Limpa documento pendente após envio bem-sucedido
      if (pendingDocumentText.value != null) {
        pendingDocumentText.value = null;
        pendingDocumentName.value = null;
      }
      // Salva o histórico de forma assíncrona sem bloquear a UI
      _saveCurrentChatAsync();
    } catch (e) {
      // Verifica se a requisição foi cancelada
      if (_currentRequest?.isCompleted == true) {
        return; // Requisição foi cancelada
      }

      isThinking.value = false;
      // Mensagem mais amigável para timeout
      if (e.toString().contains('Timeout')) {
        setError(
          'O assistente está demorando para responder. Tente novamente em alguns minutos.',
        );
      } else {
        setError('Falha ao enviar mensagem: ${e.toString()}');
      }
    } finally {
      setLoading(false);
      _currentRequest = null;
    }
  }

  Future<void> ask(String text) async {
    if (text.trim().isEmpty) return;

    // Cancela qualquer requisição anterior
    _cancelCurrentRequest();

    // Se é a primeira mensagem de usuário, gera ID e título do chat
    if (_currentChatId == null) {
      _startNewChat(text);
    }

    final fullText = _withContext(text.trim());
    messages.add(ChatMessage.user(text.trim()));
    setLoading(true);
    isThinking.value = true;
    clearError(); // Limpa erro anterior

    // Cria um novo completer para esta requisição
    _currentRequest = Completer<void>();

    try {
      final res = await _service.sendMessage(ChatRequest(fullText));

      // Verifica se a requisição foi cancelada
      if (_currentRequest?.isCompleted == true) {
        return; // Requisição foi cancelada
      }

      isThinking.value = false;
      messages.add(ChatMessage.assistant(res.response));
      // Limpa documento pendente após envio bem-sucedido
      if (pendingDocumentText.value != null) {
        pendingDocumentText.value = null;
        pendingDocumentName.value = null;
      }
      // Salva o histórico de forma assíncrona sem bloquear a UI
      _saveCurrentChatAsync();
    } catch (e) {
      // Verifica se a requisição foi cancelada
      if (_currentRequest?.isCompleted == true) {
        return; // Requisição foi cancelada
      }

      isThinking.value = false;
      // Mensagem mais amigável para timeout
      if (e.toString().contains('Timeout')) {
        setError(
          'O assistente está demorando para responder. Tente novamente em alguns minutos.',
        );
      } else {
        setError('Falha ao enviar mensagem: ${e.toString()}');
      }
    } finally {
      setLoading(false);
      _currentRequest = null;
    }
  }

  void clearChat() {
    // Cancela qualquer requisição em andamento
    _cancelCurrentRequest();

    messages.clear();
    clearError();
    _currentChatId = null;
    _currentChatTitle = '';
    isThinking.value = false;
    isProcessingDocument.value = false;
    setLoading(false);
    selectedProcess.value = null;
    selectedClient.value = null;
    useClientData.value = false;
    pendingDocumentText.value = null;
    pendingDocumentName.value = null;

    // Adiciona novamente a mensagem de boas-vindas
    messages.add(
      ChatMessage.assistant(
        'Olá! Sou seu assistente jurídico. Posso redigir petições, auxiliar na criação de processos e tirar dúvidas sobre leis.\n'
        'Exemplos: "Gerar petição inicial de cobrança", "Dúvida sobre prescrição no CDC", "Checklist para abertura de processo trabalhista".',
      ),
    );
  }

  void _cancelCurrentRequest() {
    if (_currentRequest != null && !_currentRequest!.isCompleted) {
      _currentRequest!.complete();
      _currentRequest = null;
    }
    // Cancela também no nível do serviço HTTP
    _service.cancelCurrentRequest();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _historyService.getSavedChats();
      chatHistory.assignAll(history.take(10)); // Últimos 10 chats
    } catch (e) {
      print('Erro ao carregar histórico: $e');
    }
  }

  void _startNewChat(String firstMessage) {
    _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentChatTitle = _generateChatTitle(firstMessage);
  }

  String _generateChatTitle(String firstMessage) {
    // Gera um título baseado na primeira mensagem (máximo 50 caracteres)
    String title = firstMessage.trim();
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }
    return title;
  }

  void _saveCurrentChatAsync() {
    if (_currentChatId == null) return;

    // Executa o salvamento em background sem bloquear a UI
    Future.microtask(() async {
      try {
        final session = ChatSession(
          id: _currentChatId!,
          title: _currentChatTitle,
          messages: List.from(messages),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _historyService.saveChat(session);
        await _loadChatHistory(); // Recarrega o histórico
      } catch (e) {
        print('Erro ao salvar chat: $e');
      }
    });
  }

  Future<void> loadChatFromHistory(ChatSession session) async {
    // Cancela qualquer requisição em andamento
    _cancelCurrentRequest();

    messages.clear();
    messages.addAll(session.messages);
    _currentChatId = session.id;
    _currentChatTitle = session.title;
    isThinking.value = false;
    setLoading(false);
    clearError();
  }

  @override
  void onClose() {
    // Cancela qualquer requisição em andamento ao fechar o ViewModel
    _cancelCurrentRequest();
    super.onClose();
  }

  Future<void> deleteChatFromHistory(String chatId) async {
    try {
      await _historyService.deleteChat(chatId);
      await _loadChatHistory();
    } catch (e) {
      print('Erro ao deletar chat: $e');
    }
  }

  Future<void> attachDocumentAndAsk() async {
    if (isProcessingDocument.value || isThinking.value || isLoading.value) {
      return; // Evita múltiplas operações simultâneas
    }

    isProcessingDocument.value = true;
    clearError();

    try {
      // Seleciona o arquivo (PDF, DOC, DOCX)
      final doc = await _documentService.pickDocumentFile();
      if (doc == null) {
        isProcessingDocument.value = false;
        return; // Usuário cancelou a seleção
      }

      // Extrai o texto do documento
      final extractedText = await _documentService.extractTextFromDocument(doc);

      // Armazena documento como pendente para o próximo envio do usuário
      final fileName = doc.name;
      pendingDocumentText.value = extractedText;
      pendingDocumentName.value = fileName;

      // Mensagem de feedback ao usuário
      messages.add(
        ChatMessage.user(
          '📎 Documento anexado: $fileName\nAgora descreva sua solicitação para que eu use o documento no contexto.',
        ),
      );

      // Se é a primeira mensagem de usuário, gera ID e título do chat
      if (_currentChatId == null) {
        _startNewChat('Documento: $fileName');
      }

      // Não envia imediatamente; aguarda a próxima mensagem do usuário
      isProcessingDocument.value = false;
      _saveCurrentChatAsync();
    } catch (e) {
      // Verifica se a requisição foi cancelada
      if (_currentRequest?.isCompleted == true) {
        return; // Requisição foi cancelada
      }

      isThinking.value = false;
      isProcessingDocument.value = false;

      if (e.toString().contains('Timeout')) {
        setError(
          'O assistente está demorando para responder. Tente novamente em alguns minutos.',
        );
      } else {
        setError('Erro ao processar documento: ${e.toString()}');
      }
    } finally {
      setLoading(false);
      isProcessingDocument.value = false;
      _currentRequest = null;
    }
  }

  // Seleção de contexto
  void setSelectedProcess(Map<String, String>? process) {
    selectedProcess.value = process;
  }

  void setSelectedClient(ProcessClientLink? client) {
    selectedClient.value = client;
  }

  void setUseClientData(bool value) {
    useClientData.value = value;
  }

  String _withContext(String userText) {
    final parts = <String>[];
    final p = selectedProcess.value;
    if (p != null) {
      parts.add(
        'Processo selecionado: CNJ ${p['cnj'] ?? ''} | Cliente ${p['cliente'] ?? ''} | Status ${p['status'] ?? ''}',
      );
    }
    final c = selectedClient.value;
    if (c != null) {
      parts.add('Cliente selecionado: ${c.name} (${c.role})');
      if (useClientData.value) {
        // Bloco JSON simples para facilitar integração do lado servidor/assistente
        final jsonBlock =
            '{"clientId":"${c.clientId}","name":"${c.name}","role":"${c.role}"}';
        parts.add('Dados do cliente (JSON): $jsonBlock');
      }
    }
    // Inclui documento pendente, se houver
    final docName = pendingDocumentName.value;
    final docText = pendingDocumentText.value;
    if (docText != null && docText.trim().isNotEmpty) {
      parts.add('Documento anexado: ${docName ?? 'Arquivo'}');
      parts.add('Documento (texto extraído):');
      parts.add(docText);
    }
    if (parts.isEmpty) return userText;
    return 'Contexto:\n${parts.join('\n')}\n\n${userText.trim()}';
  }

  Future<List<ProcessClientLink>> loadAllClients() async {
    try {
      Box<ProcessClientLinkHive> box;
      if (Hive.isBoxOpen('clientes')) {
        box = Hive.box<ProcessClientLinkHive>('clientes');
      } else {
        box = await Hive.openBox<ProcessClientLinkHive>('clientes');
      }
      final stored = box.values.map((e) => e.toModel());
      // Evita duplicidade por clientId (mock + hive)
      final Map<String, ProcessClientLink> map = {
        for (final m in stored) m.clientId: m,
        for (final m in mockClientes) m.clientId: m,
      };
      return map.values.toList();
    } catch (_) {
      return mockClientes;
    }
  }

  List<Map<String, String>> get availableProcesses {
    if (Get.isRegistered<ProcessListViewModel>()) {
      final vm = Get.find<ProcessListViewModel>();
      return vm.processes;
    }
    return <Map<String, String>>[];
  }
}
