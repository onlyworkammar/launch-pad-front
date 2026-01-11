import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/component.dart';
import '../models/inventory.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'component_form_screen.dart';
import 'components_list_screen.dart';
import 'inventory_detail_screen.dart';

class ComponentDetailScreen extends StatefulWidget {
  final int componentId;

  const ComponentDetailScreen({
    super.key,
    required this.componentId,
  });

  @override
  State<ComponentDetailScreen> createState() => _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends State<ComponentDetailScreen> {
  final _apiService = ApiService();
  Component? _component;
  InventoryItem? _inventoryItem;
  bool _isLoading = true;
  bool _isLoadingInventory = false;
  String? _errorMessage;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadComponent();
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

  Future<void> _loadComponent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final component = await _apiService.getComponent(widget.componentId);
      setState(() {
        _component = component;
        _isLoading = false;
      });
      _loadInventory();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoadingInventory = true;
    });

    try {
      final inventory = await _apiService.getInventoryByComponentId(widget.componentId);
      setState(() {
        _inventoryItem = inventory;
        _isLoadingInventory = false;
      });
    } catch (e) {
      // Inventory might not exist, which is okay
      setState(() {
        _inventoryItem = null;
        _isLoadingInventory = false;
      });
    }
  }

  Future<void> _deleteComponent() async {
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
        await _apiService.deleteComponent(widget.componentId);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ComponentsListScreen()),
          );
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
          ? const LoadingIndicator(message: 'Loading component...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadComponent,
                )
              : _component == null
                  ? const Center(child: Text('Component not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with actions
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Text(
                                  'Component Details: ${_component!.partNumber}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ComponentFormScreen(componentId: widget.componentId),
                                    ),
                                  ).then((_) => _loadComponent());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: _deleteComponent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Basic Information
                          _buildInfoCard(
                            'Basic Information',
                            [
                              _buildInfoRow('Part Number', _component!.partNumber),
                              _buildInfoRow('Marking', _component!.marking ?? 'N/A'),
                              _buildInfoRow('Category', _component!.categoryName ?? 'N/A'),
                              _buildInfoRow('Status', _component!.status, badge: StatusBadge(status: _component!.status)),
                              _buildInfoRow('Package', _component!.package ?? 'N/A'),
                            ],
                          ),

                          // Technical Specifications
                          _buildInfoCard(
                            'Technical Specifications',
                            [
                              _buildInfoRow('Technology', _component!.technology ?? 'N/A'),
                              _buildInfoRow('Polarity', _component!.polarity ?? 'N/A'),
                              _buildInfoRow('Channel', _component!.channel ?? 'N/A'),
                              _buildInfoRow('V_max', _component!.vMax?.toString() ?? 'N/A'),
                              _buildInfoRow('I_max', _component!.iMax?.toString() ?? 'N/A'),
                              _buildInfoRow('Power_max', _component!.powerMax?.toString() ?? 'N/A'),
                              _buildInfoRow('Gain_min', _component!.gainMin?.toString() ?? 'N/A'),
                              _buildInfoRow('Gain_max', _component!.gainMax?.toString() ?? 'N/A'),
                            ],
                          ),

                          // Pricing
                          _buildInfoCard(
                            'Pricing',
                            [
                              _buildInfoRow('Unit Price', '\$${_component!.unitPrice.toStringAsFixed(2)}'),
                            ],
                          ),

                          // Inventory Information
                          _buildInfoCard(
                            'Inventory Information',
                            [
                              if (_isLoadingInventory)
                                const Center(child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ))
                              else if (_inventoryItem != null) ...[
                                _buildInfoRow('Quantity', '${_inventoryItem!.quantity}'),
                                _buildInfoRow('Min Quantity', '${_inventoryItem!.minQty}'),
                                _buildInfoRow('Location', _inventoryItem!.location ?? 'N/A'),
                                _buildInfoRow('Unit Price', '\$${_inventoryItem!.unitPrice.toStringAsFixed(2)}'),
                                _buildInfoRow('Total Value', '\$${_inventoryItem!.totalValue.toStringAsFixed(2)}'),
                                if (_inventoryItem!.lastUpdated != null)
                                  _buildInfoRow('Last Updated', _inventoryItem!.lastUpdated!.toString().substring(0, 16)),
                                if (_inventoryItem!.quantity < _inventoryItem!.minQty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: LowStockBadge(
                                      quantity: _inventoryItem!.quantity,
                                      minQty: _inventoryItem!.minQty,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InventoryDetailScreen(componentId: widget.componentId),
                                        ),
                                      ).then((_) => _loadInventory());
                                    },
                                    icon: const Icon(Icons.inventory_2),
                                    label: const Text('Manage Inventory'),
                                  ),
                                ),
                              ] else ...[
                                const Text('No inventory record found for this component.'),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InventoryDetailScreen(componentId: widget.componentId),
                                        ),
                                      ).then((_) => _loadInventory());
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Inventory'),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Additional Characteristics
                          if (_component!.additionalCharacteristics != null)
                            _buildInfoCard(
                              'Additional Characteristics',
                              [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    const JsonEncoder.withIndent('  ').convert(_component!.additionalCharacteristics),
                                    style: const TextStyle(fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),

                          // Notes
                          if (_component!.notes != null)
                            _buildInfoCard(
                              'Notes',
                              [
                                Text(_component!.notes!),
                              ],
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: badge ?? Text(value),
          ),
        ],
      ),
    );
  }
}

