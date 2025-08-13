import 'package:flutter/material.dart';
import '../../processes/domain/models/process_models.dart';
import '../data/mock_clientes.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({Key? key}) : super(key: key);

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _pageSize = 5;
  String _searchTerm = '';

  List<ProcessClientLink> get _filteredClientes {
    if (_searchTerm.isEmpty) return mockClientes;
    return mockClientes
        .where(
          (c) =>
              c.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
              c.role.toLowerCase().contains(_searchTerm.toLowerCase()),
        )
        .toList();
  }

  List<ProcessClientLink> get _paginatedClientes {
    final filtered = _filteredClientes;
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    return filtered.sublist(
      start,
      end > filtered.length ? filtered.length : end,
    );
  }

  int get _totalPages => (_filteredClientes.length / _pageSize).ceil();

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text;
      _currentPage = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar clientes',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _paginatedClientes.length,
              itemBuilder: (context, index) {
                final cliente = _paginatedClientes[index];
                return ListTile(
                  title: Text(cliente.name),
                  subtitle: Text('Função: ${cliente.role}'),
                  trailing: cliente.isPrimary
                      ? const Icon(Icons.star, color: Colors.amber)
                      : null,
                );
              },
            ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text('Página ${_currentPage + 1} de $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
