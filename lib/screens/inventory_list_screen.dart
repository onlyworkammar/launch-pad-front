import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/inventory.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'inventory_detail_screen.dart';
import 'component_detail_screen.dart';
import '../models/component.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _apiService = ApiService();
  List<InventoryItem> _inventoryItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;
  int? _componentFilter;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadInventory();
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

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _apiService.listInventory(componentId: _componentFilter);
      setState(() {
        _inventoryItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigationBar(userName: _userName),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading inventory...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadInventory,
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
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Component ID (optional)',
                                border: OutlineInputBorder(),
                                hintText: 'Enter component ID',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _componentFilter = value.isEmpty ? null : int.tryParse(value);
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _loadInventory,
                                    child: const Text('Apply Filter'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _componentFilter = null;
                                      });
                                      _loadInventory();
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

                    // Inventory list
                    Expanded(
                      child: _inventoryItems.isEmpty
                          ? const Center(
                              child: Text('No inventory items found'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _inventoryItems.length,
                              itemBuilder: (context, index) {
                                final item = _inventoryItems[index];
                                final isLowStock = item.quantity < item.minQty;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: isLowStock ? Colors.red[50] : null,
                                  child: ListTile(
                                    title: Text(
                                      item.partNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Component: ${item.componentName}'),
                                        Text('Category: ${item.categoryName}'),
                                        Text('Location: ${item.location ?? 'N/A'}'),
                                        Text('Quantity: ${item.quantity} (Min: ${item.minQty})'),
                                        Text('Unit Price: \$${item.unitPrice.toStringAsFixed(2)}'),
                                        Text('Total Value: \$${item.totalValue.toStringAsFixed(2)}'),
                                        if (item.lastUpdated != null)
                                          Text('Last Updated: ${item.lastUpdated!.toString().substring(0, 16)}'),
                                        const SizedBox(height: 4),
                                        if (isLowStock)
                                          const LowStockBadge(quantity: 0, minQty: 0),
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
                                                builder: (context) => InventoryDetailScreen(
                                                  componentId: item.componentId,
                                                )),
                                            ).then((_) => _loadInventory());
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.inventory_2),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ComponentDetailScreen(
                                                  componentId: item.componentId,
                                                ),
                                              ),
                                            );
                                          },
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
        onPressed: _showAddInventoryDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Inventory',
      ),
    );
  }

  void _showAddInventoryDialog() {
    final componentIdController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Inventory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the Component ID to add inventory for:'),
            const SizedBox(height: 16),
            TextField(
              controller: componentIdController,
              decoration: const InputDecoration(
                labelText: 'Component ID',
                border: OutlineInputBorder(),
                hintText: 'Enter component ID',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                // Navigate to components list to select
                if (!mounted) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComponentSelectionScreen(),
                  ),
                );
                if (mounted && result != null && result is int) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventoryDetailScreen(componentId: result),
                    ),
                  ).then((_) {
                    if (mounted) _loadInventory();
                  });
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('Browse Components'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final componentId = int.tryParse(componentIdController.text);
              if (componentId != null) {
                Navigator.pop(dialogContext);
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryDetailScreen(componentId: componentId),
                  ),
                ).then((_) {
                  if (mounted) _loadInventory();
                });
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid component ID')),
                );
              }
            },
            child: const Text('Add Inventory'),
          ),
        ],
      ),
    );
  }
}

// Simple component selection screen
class ComponentSelectionScreen extends StatefulWidget {
  const ComponentSelectionScreen({super.key});

  @override
  State<ComponentSelectionScreen> createState() => _ComponentSelectionScreenState();
}

class _ComponentSelectionScreenState extends State<ComponentSelectionScreen> {
  final _apiService = ApiService();
  List<Component> _components = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComponents();
  }

  Future<void> _loadComponents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final components = await _apiService.listComponents(statusFilter: 'ACTIVE');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Component'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading components...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadComponents,
                )
              : _components.isEmpty
                  ? const Center(child: Text('No components found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
                            subtitle: Text(
                              '${component.categoryName ?? 'N/A'} - ${component.technology ?? 'N/A'}',
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.pop(context, component.id);
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

