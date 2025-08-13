import 'package:get/get.dart';
import '../../domain/models/process_models.dart';

class ProcessCreateController extends GetxController {
  final draft = ProcessDraft().obs;
  final currentStep = 0.obs;
  final isSaving = false.obs;
  final autoSavedAt = Rxn<DateTime>();

  // Simulação de base de clientes para autocomplete
  final allClients = List.generate(
    30,
    (i) => ProcessClientLink(
      clientId: 'c${i + 1}',
      name: 'Cliente ${i + 1}',
      role: 'Autor',
    ),
  );

  // Lista pré-cadastrada de Foros / Varas (poderia vir de cache / API)
  final foros = <String>[
    'Foro Central Cível - SP',
    '2ª Vara Cível - São Paulo',
    'Foro Regional de Pinheiros',
    'Vara do Trabalho de São Paulo 1ª',
  ].obs;

  void addForo(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (!foros.contains(trimmed)) {
      foros.add(trimmed);
    }
    draft.update((d) => d!.foro = trimmed);
    autoSave();
  }

  void setStep(int step) {
    if (step < 0) return;
    if (step > 4) return; // total 5 passos
    currentStep.value = step;
  }

  void nextStep() => setStep(currentStep.value + 1);
  void prevStep() => setStep(currentStep.value - 1);

  Future<void> autoSave() async {
    // Aqui integrar persistência local (SharedPrefs / Isar etc.)
    autoSavedAt.value = DateTime.now();
  }

  String? validateStep(int step) {
    final d = draft.value;
    switch (step) {
      case 0:
        if (d.cnj.isEmpty) return 'Informe o número CNJ';
        if (d.status.isEmpty) return 'Selecione o status';
        if (d.distributionDate == null) return 'Informe a data de distribuição';
        return null;
      case 1:
        if (d.clients.isEmpty) return 'Adicione pelo menos um cliente';
        if (!d.clients.any((c) => c.isPrimary))
          return 'Marque um cliente principal';
        return null;
      default:
        return null;
    }
  }

  bool get canGoNext => validateStep(currentStep.value) == null;

  Future<void> saveFinal() async {
    isSaving.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    // Simulação: você chamaria um usecase/repositório aqui
    isSaving.value = false;
  }
}
