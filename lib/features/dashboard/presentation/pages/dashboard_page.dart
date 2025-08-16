import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../processes/presentation/pages/process_list_page.dart';
import '../../../processes/presentation/widgets/stat_card.dart';
import '../../../clients/presentation/pages/client_list_page.dart';
import '../../../assistant/presentation/pages/assistant_page.dart';
import '../../../agenda/presentation/pages/schedule_audience_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  static const route = '/dashboard';

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _index = 0;
  final _auth = Get.find<AuthViewModel>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _backgroundLayer(context),
        AppShell(
          navIndex: _index,
          onNavChange: (i) => setState(() => _index = i),
          title: _titleForIndex(_index),
          showRail: true,
          pageKey: ValueKey('content-$_index'),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Conta',
              offset: const Offset(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Sair do app'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'logout') {
                  await _auth.logout();
                  if (context.mounted) context.go('/login');
                }
              },
              child: const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 18),
              ),
            ),
          ],
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _backgroundLayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0E1A27),
                  const Color(0xFF132B45),
                  const Color(0xFF0E2238),
                ]
              : [
                  const Color(0xFFF3F7FB),
                  const Color(0xFFE6EEF6),
                  const Color(0xFFD9E7F3),
                ],
        ),
      ),
    );
  }

  String _titleForIndex(int i) => switch (i) {
    0 => 'Dashboard',
    1 => 'Processos',
    2 => 'Documentos',
    3 => 'Agenda',
    4 => 'Clientes',
    5 => 'Assistente',
    _ => 'Seção',
  };

  Widget _buildContent() {
    switch (_index) {
      case 0:
        return _dashboardOverview();
      case 1:
        return const ProcessListPage();
      case 3:
        return const ScheduleAudiencePage();
      case 4:
        return const ClientListPage();
      case 5:
        return const AssistantPage();
      default:
        return const Center(child: Text('Em construção...'));
    }
  }

  Widget _dashboardOverview() {
    final stats = [
      ('Prazos', '12', Icons.schedule),
      ('Audiências', '4', Icons.gavel),
      ('Docs Recentes', '8', Icons.description_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
            ? 3
            : constraints.maxWidth > 560
            ? 2
            : 1;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroHeader(context),
              const SizedBox(height: 28),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 3.2,
                ),
                itemCount: stats.length,
                itemBuilder: (_, i) => _glassWrapper(
                  child: StatCard(
                    title: stats[i].$1,
                    value: stats[i].$2,
                    icon: stats[i].$3,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _glassWrapper(child: _andamentosList())),
                  const SizedBox(width: 24),
                  if (constraints.maxWidth > 900)
                    SizedBox(
                      width: 320,
                      child: _glassWrapper(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumo',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              _miniStat('Processos ativos', '34'),
                              _miniStat('Audiências hoje', '1'),
                              _miniStat('Prazos semana', '5'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _glassWrapper({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(.28), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.60),
                Colors.white.withOpacity(.35),
                Colors.white.withOpacity(.25),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _heroHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _glassWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo de volta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visão geral das atividades e métricas importantes.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurface.withOpacity(.7),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/dashboard/processos/novo'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Novo Processo'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/dashboard/clientes/novo'),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Novo Cliente'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Enviar Documento'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/dashboard/processos/agendar'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Agendar Audiência'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _andamentosList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimos Andamentos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (i) => _timelineItem(i)),
        ],
      ),
    );
  }

  Widget _timelineItem(int i) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (i != 4)
                Container(
                  width: 2,
                  height: 48,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: cs.primary.withOpacity(.4),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '01/08/2025',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Andamento ${i + 1} - Descrição resumida do evento processual com detalhes relevantes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver documento'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
