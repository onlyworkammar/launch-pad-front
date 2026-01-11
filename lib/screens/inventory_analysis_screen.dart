import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/inventory.dart';
import '../models/category.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'component_detail_screen.dart';

class InventoryAnalysisScreen extends StatefulWidget {
  const InventoryAnalysisScreen({super.key});

  @override
  State<InventoryAnalysisScreen> createState() => _InventoryAnalysisScreenState();
}

class _InventoryAnalysisScreenState extends State<InventoryAnalysisScreen> {
  final _apiService = ApiService();
  InventoryCostSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;
  int? _categoryFilter;
  String? _statusFilter = 'ACTIVE';
  bool _includeLowStock = true;
  List<Category> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCategories();
    _loadInventoryCost();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await _apiService.listCategories(statusFilter: 'ACTIVE');
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      // Silently fail - categories will be empty
    }
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

  Future<void> _loadInventoryCost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _apiService.getInventoryCost(
        categoryId: _categoryFilter,
        statusFilter: _statusFilter,
        includeLowStock: _includeLowStock,
      );
      setState(() {
        _summary = summary;
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
          ? const LoadingIndicator(message: 'Loading inventory analysis...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadInventoryCost,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventory Cost Analysis',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filters
                      Card(
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
                                    child: DropdownButtonFormField<int>(
                                      value: _categoryFilter,
                                      decoration: InputDecoration(
                                        labelText: 'Category',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: _isLoadingCategories
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: Padding(
                                                  padding: EdgeInsets.all(12.0),
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              )
                                            : null,
                                      ),
                                      items: [
                                        const DropdownMenuItem(value: null, child: Text('All')),
                                        ..._categories.map((category) => DropdownMenuItem(
                                              value: category.id,
                                              child: Text(category.name),
                                            )),
                                      ],
                                      onChanged: _isLoadingCategories
                                          ? null
                                          : (value) {
                                              setState(() {
                                                _categoryFilter = value;
                                              });
                                            },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _statusFilter,
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                title: const Text('Include Low Stock Items'),
                                value: _includeLowStock,
                                onChanged: (value) {
                                  setState(() {
                                    _includeLowStock = value ?? true;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _loadInventoryCost,
                                      child: const Text('Apply Filters'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _categoryFilter = null;
                                          _statusFilter = 'ACTIVE';
                                          _includeLowStock = true;
                                        });
                                        _loadInventoryCost();
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
                      const SizedBox(height: 16),

                      // Summary
                      if (_summary != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem('Total Value', '\$${_summary!.totalValue.toStringAsFixed(2)}'),
                                    _buildStatItem('Components', _summary!.totalComponents.toString()),
                                    _buildStatItem('Quantity', _summary!.totalQuantity.toString()),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Currency: ${_summary!.currency}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Breakdown by Category
                        if (_summary!.breakdownByCategory.isNotEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Breakdown by Category',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(1),
                                      2: FlexColumnWidth(1),
                                      3: FlexColumnWidth(1),
                                    },
                                    children: [
                                      const TableRow(
                                        children: [
                                          TableCell(child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                          TableCell(child: Text('Components', style: TextStyle(fontWeight: FontWeight.bold))),
                                          TableCell(child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                                          TableCell(child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                      ..._summary!.breakdownByCategory.entries.map((entry) {
                                        final breakdown = entry.value;
                                        return TableRow(
                                          children: [
                                            TableCell(child: Text(entry.key)),
                                            TableCell(child: Text(breakdown.componentCount.toString())),
                                            TableCell(child: Text(breakdown.totalQuantity.toString())),
                                            TableCell(child: Text('\$${breakdown.totalValue.toStringAsFixed(2)}')),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Low Stock Items
                        if (_summary!.lowStockItems.isNotEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Low Stock Items',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(2),
                                      2: FlexColumnWidth(1),
                                      3: FlexColumnWidth(1),
                                      4: FlexColumnWidth(1),
                                    },
                                    children: [
                                      const TableRow(
                                        children: [
                                          TableCell(child: Text('Part #', style: TextStyle(fontWeight: FontWeight.bold))),
                                          TableCell(child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                          TableCell(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                                          TableCell(child: Text('Min', style: TextStyle(fontWeight: FontWeight.bold))),
                                          TableCell(child: Text('Shortage', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                      ..._summary!.lowStockItems.map((item) => TableRow(
                                            children: [
                                              TableCell(
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ComponentDetailScreen(componentId: item.componentId),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    item.partNumber,
                                                    style: const TextStyle(
                                                      color: Color(0xFF2563EB),
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TableCell(child: Text(item.categoryName)),
                                              TableCell(child: Text(item.quantity.toString())),
                                              TableCell(child: Text(item.minQty.toString())),
                                              TableCell(
                                                child: Text(
                                                  item.shortage.toString(),
                                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loadInventoryCost,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Export functionality would go here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Export functionality coming soon')),
                                );
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Export Report'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}


