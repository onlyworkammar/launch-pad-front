import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/component.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'component_detail_screen.dart';
import 'component_form_screen.dart';

class ComponentsListScreen extends StatefulWidget {
  const ComponentsListScreen({super.key});

  @override
  State<ComponentsListScreen> createState() => _ComponentsListScreenState();
}

class _ComponentsListScreenState extends State<ComponentsListScreen> {
  final _apiService = ApiService();
  List<Component> _components = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;
  String? _statusFilter;
  int? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadComponents();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _apiService.getCurrentUser();
      setState(() {
        _userName = user.username;
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadComponents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final components = await _apiService.listComponents(
        statusFilter: _statusFilter,
        categoryId: _categoryFilter,
      );
      setState(() {
        _components = components;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteComponent(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Component'),
        content: const Text('Are you sure you want to delete this component?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteComponent(id);
        _loadComponents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Component deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigationBar(userName: _userName),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading components...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadComponents,
                )
              : Column(
                  children: [
                    // Filters
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _statusFilter,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text('All')),
                                      DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                                      DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _statusFilter = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _categoryFilter,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text('All')),
                                      // Add more categories as needed
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _categoryFilter = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _loadComponents,
                                    child: const Text('Apply Filters'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _statusFilter = null;
                                        _categoryFilter = null;
                                      });
                                      _loadComponents();
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Components list
                    Expanded(
                      child: _components.isEmpty
                          ? const Center(
                              child: Text('No components found'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _components.length,
                              itemBuilder: (context, index) {
                                final component = _components[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      component.partNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Category: ${component.categoryName ?? 'N/A'}'),
                                        Text('Technology: ${component.technology ?? 'N/A'}'),
                                        Text('Package: ${component.package ?? 'N/A'}'),
                                        Text('Stock: ${component.quantity}${component.minQty != null ? ' (Min: ${component.minQty})' : ''}'),
                                        if (component.location != null) Text('Location: ${component.location}'),
                                        Text('Price: \$${component.unitPrice.toStringAsFixed(2)}'),
                                        if (component.totalValue > 0) Text('Total Value: \$${component.totalValue.toStringAsFixed(2)}'),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            StatusBadge(status: component.status),
                                            if (component.minQty != null && component.quantity < component.minQty!)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: LowStockBadge(
                                                  quantity: component.quantity,
                                                  minQty: component.minQty!,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ComponentDetailScreen(componentId: component.id),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ComponentFormScreen(componentId: component.id),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteComponent(component.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComponentFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


