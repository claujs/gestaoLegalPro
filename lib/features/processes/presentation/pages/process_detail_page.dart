import 'package:flutter/material.dart';

class ProcessDetailArgs {
  final Map<String, String> process;
  ProcessDetailArgs({required this.process});
}

class ProcessDetailPage extends StatefulWidget {
  final Map<String, String> process;
  const ProcessDetailPage({super.key, required this.process});
  static const route = '/processo';

  @override
  State<ProcessDetailPage> createState() => _ProcessDetailPageState();
}

class _ProcessDetailPageState extends State<ProcessDetailPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.process;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Processo ${p['cnj']}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Andamentos'),
            Tab(text: 'Documentos'),
            Tab(text: 'Prazos'),
            Tab(text: 'Agenda'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cs.primaryContainer),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _infoItem('Cliente', p['cliente'] ?? ''),
                _infoItem('Status', p['status'] ?? ''),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAndamentos(),
                _buildDocumentos(),
                _buildPrazos(),
                _buildAgenda(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildAndamentos() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (i != 7)
                Container(
                  width: 2,
                  height: 48,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Theme.of(context).colorScheme.primary.withOpacity(.4),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Data 0${i + 1}/08/2025'),
              subtitle: const Text(
                'Descrição detalhada do andamento com possíveis links.',
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentos() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3 / 2,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => Card(
        elevation: 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 42),
            Text('Documento ${i + 1}'),
            TextButton(onPressed: () {}, child: const Text('Download')),
          ],
        ),
      ),
    );
  }

  Widget _buildPrazos() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.timer),
        title: Text('Prazo ${i + 1}'),
        subtitle: const Text('Restam X dias'),
        trailing: const Chip(label: Text('Aberto')),
      ),
    );
  }

  Widget _buildAgenda() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.calendar_month, size: 64),
          SizedBox(height: 16),
          Text('Calendário a integrar'),
        ],
      ),
    );
  }
}
