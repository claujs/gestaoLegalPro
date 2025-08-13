import 'package:get/get.dart';
import '../../../../core/controllers/base_view_model.dart';

class ProcessListViewModel extends BaseViewModel {
  final processes = <Map<String, String>>[].obs;
  final filterCnj = ''.obs;
  final filterCliente = ''.obs;
  final filterStatus = RxnString();
  final page = 0.obs;
  final pageSize = 20.obs;
  final selected = <String>{}.obs; // cnjs selecionados

  List<Map<String, String>> get filtered {
    final cnj = filterCnj.value.trim();
    final cli = filterCliente.value.trim().toLowerCase();
    final status = filterStatus.value;
    return processes.where((p) {
      final matchCnj = cnj.isEmpty || p['cnj']!.contains(cnj);
      final matchCli = cli.isEmpty || p['cliente']!.toLowerCase().contains(cli);
      final matchStatus = status == null || p['status'] == status;
      return matchCnj && matchCli && matchStatus;
    }).toList();
  }

  List<Map<String, String>> get paginated {
    final list = filtered;
    final start = page.value * pageSize.value;
    if (start >= list.length) return [];
    final end = start + pageSize.value;
    return list.sublist(start, end > list.length ? list.length : end);
  }

  int get totalPages => (filtered.length / pageSize.value).ceil();
  bool get allVisibleSelected =>
      paginated.isNotEmpty &&
      paginated.every((p) => selected.contains(p['cnj']));

  Future<void> load() async {
    setLoading(true);
    await Future.delayed(const Duration(milliseconds: 600));
    final data = List.generate(
      500,
      (i) => {
        'cnj': '500${i + 1}-89.2024.8.26.0100',
        'cliente': 'Cliente ${i + 1}',
        'andamento': 'Movimentação recente ${i + 1}',
        'status': i % 3 == 0
            ? 'Ativo'
            : i % 3 == 1
            ? 'Arquivado'
            : 'Suspenso',
      },
    );
    processes.assignAll(data);
    setLoading(false);
  }

  void setPage(int newPage) {
    if (newPage < 0) return;
    if (newPage >= totalPages) return;
    page.value = newPage;
  }

  void nextPage() => setPage(page.value + 1);
  void prevPage() => setPage(page.value - 1);

  void applyFilters({String? cnj, String? cliente, String? status}) {
    if (cnj != null) filterCnj.value = cnj;
    if (cliente != null) filterCliente.value = cliente;
    if (status != null) filterStatus.value = status.isEmpty ? null : status;
    page.value = 0;
  }

  void clearFilters() {
    filterCnj.value = '';
    filterCliente.value = '';
    filterStatus.value = null;
    page.value = 0;
  }

  void toggleSelectAll(bool value) {
    if (value) {
      selected.addAll(paginated.map((p) => p['cnj']!));
    } else {
      selected.removeWhere((cnj) => paginated.any((p) => p['cnj'] == cnj));
    }
  }

  void toggleSelection(String cnj, bool value) {
    if (value) {
      selected.add(cnj);
    } else {
      selected.remove(cnj);
    }
  }
}
