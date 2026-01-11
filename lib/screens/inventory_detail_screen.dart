import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/inventory.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'component_detail_screen.dart';

class InventoryDetailScreen extends StatefulWidget {
  final int componentId;

  const InventoryDetailScreen({
    super.key,
    required this.componentId,
  });

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _minQtyController = TextEditingController();
  final _locationController = TextEditingController();
  
  InventoryItem? _inventoryItem;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _errorMessage;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadInventory();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _minQtyController.dispose();
    _locationController.dispose();
    super.dispose();
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
      final item = await _apiService.getInventoryByComponentId(widget.componentId);
      setState(() {
        _inventoryItem = item;
        _quantityController.text = item.quantity.toString();
        _minQtyController.text = item.minQty.toString();
        _locationController.text = item.location ?? '';
        _isLoading = false;
      });
    } catch (e) {
      // Inventory might not exist - that's okay, we can create it
      setState(() {
        _inventoryItem = null;
        _isLoading = false;
        _isEditing = true; // Enable editing mode for new inventory
      });
    }
  }

  Future<void> _saveInventory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final wasNew = _inventoryItem == null;
      InventoryItem item;
      if (wasNew) {
        // Create new inventory
        item = await _apiService.addOrUpdateInventory(
          componentId: widget.componentId,
          quantity: int.parse(_quantityController.text),
          minQty: int.parse(_minQtyController.text),
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        );
      } else {
        // Update existing inventory
        item = await _apiService.updateInventory(
          widget.componentId,
          quantity: int.parse(_quantityController.text),
          minQty: int.parse(_minQtyController.text),
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        );
      }

      setState(() {
        _inventoryItem = item;
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasNew ? 'Inventory created successfully' : 'Inventory updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _adjustInventory(int adjustment) async {
    try {
      final item = await _apiService.adjustInventory(widget.componentId, adjustment);
      setState(() {
        _inventoryItem = item;
        _quantityController.text = item.quantity.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inventory ${adjustment >= 0 ? 'increased' : 'decreased'} by ${adjustment.abs()}'),
          ),
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

  void _showAdjustDialog() {
    final adjustmentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Inventory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current quantity: ${_inventoryItem?.quantity ?? 0}'),
            const SizedBox(height: 16),
            TextField(
              controller: adjustmentController,
              decoration: const InputDecoration(
                labelText: 'Adjustment',
                hintText: 'Enter positive to add, negative to subtract',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              'Example: +10 to add, -5 to subtract',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final adjustment = int.tryParse(adjustmentController.text);
              if (adjustment != null) {
                Navigator.pop(context);
                _adjustInventory(adjustment);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number')),
                );
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigationBar(userName: _userName),
      body: _isLoading && _inventoryItem == null
          ? const LoadingIndicator(message: 'Loading inventory...')
          : _errorMessage != null && _inventoryItem == null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadInventory,
                )
              : _inventoryItem == null
                  ? const Center(child: Text('Inventory not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: Text(
                                    'Inventory: ${_inventoryItem!.partNumber}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!_isEditing)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.inventory_2),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ComponentDetailScreen(
                                          componentId: widget.componentId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Component Info Card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Component Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Part Number', _inventoryItem!.partNumber),
                                    _buildInfoRow('Component Name', _inventoryItem!.componentName),
                                    _buildInfoRow('Category', _inventoryItem!.categoryName),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Inventory Details Card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Inventory Details',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (!_isEditing)
                                          ElevatedButton.icon(
                                            onPressed: _showAdjustDialog,
                                            icon: const Icon(Icons.add_circle_outline),
                                            label: const Text('Adjust'),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_isEditing) ...[
                                      TextFormField(
                                        controller: _quantityController,
                                        decoration: const InputDecoration(
                                          labelText: 'Quantity *',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Quantity is required';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Please enter a valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _minQtyController,
                                        decoration: const InputDecoration(
                                          labelText: 'Minimum Quantity *',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Minimum quantity is required';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Please enter a valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _locationController,
                                        decoration: const InputDecoration(
                                          labelText: 'Location',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ] else ...[
                                      _buildInfoRow('Quantity', '${_inventoryItem!.quantity}'),
                                      _buildInfoRow('Minimum Quantity', '${_inventoryItem!.minQty}'),
                                      _buildInfoRow('Location', _inventoryItem!.location ?? 'N/A'),
                                      if (_inventoryItem!.quantity < _inventoryItem!.minQty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: LowStockBadge(
                                            quantity: _inventoryItem!.quantity,
                                            minQty: _inventoryItem!.minQty,
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Pricing Card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pricing',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Unit Price', '\$${_inventoryItem!.unitPrice.toStringAsFixed(2)}'),
                                    _buildInfoRow('Total Value', '\$${_inventoryItem!.totalValue.toStringAsFixed(2)}'),
                                    if (_inventoryItem!.lastUpdated != null)
                                      _buildInfoRow(
                                        'Last Updated',
                                        _inventoryItem!.lastUpdated!.toString().substring(0, 16),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            if (_isEditing) ...[
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                          _quantityController.text = _inventoryItem!.quantity.toString();
                                          _minQtyController.text = _inventoryItem!.minQty.toString();
                                          _locationController.text = _inventoryItem!.location ?? '';
                                        });
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _saveInventory,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text('Save Changes'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

