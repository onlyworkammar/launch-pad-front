import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/component.dart';
import '../models/category.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'component_detail_screen.dart';
import 'components_list_screen.dart';

class ComponentFormScreen extends StatefulWidget {
  final int? componentId;

  const ComponentFormScreen({super.key, this.componentId});

  @override
  State<ComponentFormScreen> createState() => _ComponentFormScreenState();
}

class _ComponentFormScreenState extends State<ComponentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _partNumberController = TextEditingController();
  final _markingController = TextEditingController();
  final _notesController = TextEditingController();
  final _additionalCharsController = TextEditingController();
  
  int? _categoryId;
  String _status = 'ACTIVE';
  String? _technology;
  String? _polarity;
  final _channelController = TextEditingController();
  final _packageController = TextEditingController();
  final _vMaxController = TextEditingController();
  final _iMaxController = TextEditingController();
  final _powerMaxController = TextEditingController();
  final _gainMinController = TextEditingController();
  final _gainMaxController = TextEditingController();
  final _unitPriceController = TextEditingController();
  
  // MOSFET-specific controllers
  final _rdsOnController = TextEditingController();
  final _vgsMaxController = TextEditingController();
  final _vgsThController = TextEditingController();
  final _qgController = TextEditingController();
  final _cissController = TextEditingController();
  final _switchingTypeController = TextEditingController();
  
  // Diode-specific controllers
  final _vfController = TextEditingController();
  final _trrController = TextEditingController();
  final _cjController = TextEditingController();
  final _diodeTypeController = TextEditingController();
  final _internalConfigController = TextEditingController();
  
  // Voltage Regulator-specific controllers
  final _vInMaxController = TextEditingController();
  final _vOutController = TextEditingController();
  final _iOutMaxController = TextEditingController();
  final _accuracyController = TextEditingController();
  final _regTypeController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  Component? _existingComponent;
  String? _userName;
  List<Category> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.componentId != null;
    _loadCategories();
    if (_isEditMode) {
      _loadComponent();
    }
    _loadUserInfo();
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

  @override
  void dispose() {
    _partNumberController.dispose();
    _markingController.dispose();
    _notesController.dispose();
    _additionalCharsController.dispose();
    _channelController.dispose();
    _packageController.dispose();
    _vMaxController.dispose();
    _iMaxController.dispose();
    _powerMaxController.dispose();
    _gainMinController.dispose();
    _gainMaxController.dispose();
    _unitPriceController.dispose();
    // MOSFET controllers
    _rdsOnController.dispose();
    _vgsMaxController.dispose();
    _vgsThController.dispose();
    _qgController.dispose();
    _cissController.dispose();
    _switchingTypeController.dispose();
    // Diode controllers
    _vfController.dispose();
    _trrController.dispose();
    _cjController.dispose();
    _diodeTypeController.dispose();
    _internalConfigController.dispose();
    // Voltage Regulator controllers
    _vInMaxController.dispose();
    _vOutController.dispose();
    _iOutMaxController.dispose();
    _accuracyController.dispose();
    _regTypeController.dispose();
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

  Future<void> _loadComponent() async {
    if (widget.componentId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final component = await _apiService.getComponent(widget.componentId!);
      setState(() {
        _existingComponent = component;
        _partNumberController.text = component.partNumber;
        _markingController.text = component.marking ?? '';
        _categoryId = component.categoryId;
        _status = component.status;
        _technology = component.technology;
        _polarity = component.polarity;
        _channelController.text = component.channel ?? '';
        _packageController.text = component.package ?? '';
        _vMaxController.text = component.vMax?.toString() ?? '';
        _iMaxController.text = component.iMax?.toString() ?? '';
        _powerMaxController.text = component.powerMax?.toString() ?? '';
        _gainMinController.text = component.gainMin?.toString() ?? '';
        _gainMaxController.text = component.gainMax?.toString() ?? '';
        _unitPriceController.text = component.unitPrice.toString();
        _notesController.text = component.notes ?? '';
        // MOSFET fields
        _rdsOnController.text = component.rdsOn ?? '';
        _vgsMaxController.text = component.vgsMax ?? '';
        _vgsThController.text = component.vgsTh ?? '';
        _qgController.text = component.qg ?? '';
        _cissController.text = component.ciss ?? '';
        _switchingTypeController.text = component.switchingType ?? '';
        // Diode fields
        _vfController.text = component.vf ?? '';
        _trrController.text = component.trr ?? '';
        _cjController.text = component.cj ?? '';
        _diodeTypeController.text = component.diodeType ?? '';
        _internalConfigController.text = component.internalConfig ?? '';
        // Voltage Regulator fields
        _vInMaxController.text = component.vInMax ?? '';
        _vOutController.text = component.vOut ?? '';
        _iOutMaxController.text = component.iOutMax ?? '';
        _accuracyController.text = component.accuracy ?? '';
        _regTypeController.text = component.regType ?? '';
        if (component.additionalCharacteristics != null) {
          _additionalCharsController.text = const JsonEncoder.withIndent('  ').convert(component.additionalCharacteristics);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading component: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _saveComponent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> componentData = {
        'part_number': _partNumberController.text.trim(),
        'marking': _markingController.text.trim().isEmpty ? null : _markingController.text.trim(),
        'category_id': _categoryId!,
        'status': _status,
        'technology': _technology,
        'polarity': _polarity,
        'channel': _channelController.text.trim().isEmpty ? null : _channelController.text.trim(),
        'package': _packageController.text.trim().isEmpty ? null : _packageController.text.trim(),
        'v_max': _vMaxController.text.isEmpty ? null : _vMaxController.text,
        'i_max': _iMaxController.text.isEmpty ? null : _iMaxController.text,
        'power_max': _powerMaxController.text.isEmpty ? null : _powerMaxController.text,
        'gain_min': _gainMinController.text.isEmpty ? null : _gainMinController.text,
        'gain_max': _gainMaxController.text.isEmpty ? null : _gainMaxController.text,
        'unit_price': double.parse(_unitPriceController.text),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        // MOSFET fields
        'rds_on': _rdsOnController.text.trim().isEmpty ? null : _rdsOnController.text.trim(),
        'vgs_max': _vgsMaxController.text.trim().isEmpty ? null : _vgsMaxController.text.trim(),
        'vgs_th': _vgsThController.text.trim().isEmpty ? null : _vgsThController.text.trim(),
        'qg': _qgController.text.trim().isEmpty ? null : _qgController.text.trim(),
        'ciss': _cissController.text.trim().isEmpty ? null : _cissController.text.trim(),
        'switching_type': _switchingTypeController.text.trim().isEmpty ? null : _switchingTypeController.text.trim(),
        // Diode fields
        'vf': _vfController.text.trim().isEmpty ? null : _vfController.text.trim(),
        'trr': _trrController.text.trim().isEmpty ? null : _trrController.text.trim(),
        'cj': _cjController.text.trim().isEmpty ? null : _cjController.text.trim(),
        'diode_type': _diodeTypeController.text.trim().isEmpty ? null : _diodeTypeController.text.trim(),
        'internal_config': _internalConfigController.text.trim().isEmpty ? null : _internalConfigController.text.trim(),
        // Voltage Regulator fields
        'v_in_max': _vInMaxController.text.trim().isEmpty ? null : _vInMaxController.text.trim(),
        'v_out': _vOutController.text.trim().isEmpty ? null : _vOutController.text.trim(),
        'i_out_max': _iOutMaxController.text.trim().isEmpty ? null : _iOutMaxController.text.trim(),
        'accuracy': _accuracyController.text.trim().isEmpty ? null : _accuracyController.text.trim(),
        'reg_type': _regTypeController.text.trim().isEmpty ? null : _regTypeController.text.trim(),
      };

      // Parse additional characteristics JSON
      if (_additionalCharsController.text.trim().isNotEmpty) {
        try {
          componentData['additional_characteristics'] = json.decode(_additionalCharsController.text);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid JSON in Additional Characteristics')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      Component component;
      if (_isEditMode) {
        component = await _apiService.updateComponent(widget.componentId!, componentData);
      } else {
        component = await _apiService.createComponent(componentData);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ComponentDetailScreen(componentId: component.id),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Component ${_isEditMode ? 'updated' : 'created'} successfully')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigationBar(userName: _userName),
      body: _isLoading && _isEditMode
          ? const LoadingIndicator(message: 'Loading component...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            _isEditMode ? 'Edit Component: ${_existingComponent?.partNumber ?? ''}' : 'Create New Component',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Required Fields
                    _buildSectionCard(
                      'Required Fields',
                      [
                        TextFormField(
                          controller: _partNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Part Number *',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isEditMode,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Part number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _markingController,
                          decoration: const InputDecoration(
                            labelText: 'Marking',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _categoryId,
                          decoration: InputDecoration(
                            labelText: 'Category *',
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
                          items: _categories.isEmpty
                              ? [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Loading categories...'),
                                    enabled: false,
                                  ),
                                ]
                              : [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Select Category'),
                                    enabled: false,
                                  ),
                                  ..._categories.map((category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.name),
                                      )),
                                ],
                          onChanged: _isLoadingCategories
                              ? null
                              : (value) {
                                  setState(() {
                                    _categoryId = value;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Category is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _status,
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
                              _status = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    // Technical Specifications
                    _buildSectionCard(
                      'Technical Specifications',
                      [
                        DropdownButtonFormField<String>(
                          value: _technology,
                          decoration: const InputDecoration(
                            labelText: 'Technology',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'NPN', child: Text('NPN')),
                            DropdownMenuItem(value: 'PNP', child: Text('PNP')),
                            DropdownMenuItem(value: 'NMOS', child: Text('NMOS')),
                            DropdownMenuItem(value: 'PMOS', child: Text('PMOS')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _technology = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _polarity,
                          decoration: const InputDecoration(
                            labelText: 'Polarity',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'NPN', child: Text('NPN')),
                            DropdownMenuItem(value: 'PNP', child: Text('PNP')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _polarity = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _channelController,
                          decoration: const InputDecoration(
                            labelText: 'Channel',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _packageController,
                          decoration: const InputDecoration(
                            labelText: 'Package',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _vMaxController,
                          decoration: const InputDecoration(
                            labelText: 'V_max',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _iMaxController,
                          decoration: const InputDecoration(
                            labelText: 'I_max',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _powerMaxController,
                          decoration: const InputDecoration(
                            labelText: 'Power_max',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _gainMinController,
                          decoration: const InputDecoration(
                            labelText: 'Gain_min',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _gainMaxController,
                          decoration: const InputDecoration(
                            labelText: 'Gain_max',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),

                    // Pricing
                    _buildSectionCard(
                      'Pricing',
                      [
                        TextFormField(
                          controller: _unitPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Unit Price *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Unit price is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    // MOSFET-specific fields (only show when category_id === 6)
                    if (_categoryId == 6)
                      _buildSectionCard(
                        'MOSFET Specifications (Optional)',
                        [
                          TextFormField(
                            controller: _rdsOnController,
                            decoration: const InputDecoration(
                              labelText: 'RDS(on)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "5Ω @ 4.5V"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _vgsMaxController,
                            decoration: const InputDecoration(
                              labelText: 'VGS(max)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "±20V"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _vgsThController,
                            decoration: const InputDecoration(
                              labelText: 'VGS(th)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "2–4V"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _qgController,
                            decoration: const InputDecoration(
                              labelText: 'Gate Charge (Qg)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "2.5nC"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cissController,
                            decoration: const InputDecoration(
                              labelText: 'Input Capacitance (Ciss)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "150pF"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _switchingTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Switching Type',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "Power MOSFET"',
                            ),
                          ),
                        ],
                      ),

                    // Diode-specific fields (only show when category_id is 7, 8, or 9)
                    if (_categoryId != null && [7, 8, 9].contains(_categoryId))
                      _buildSectionCard(
                        'Diode Specifications (Optional)',
                        [
                          TextFormField(
                            controller: _vfController,
                            decoration: const InputDecoration(
                              labelText: 'Forward Voltage (Vf)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "1.0V @ 10mA"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _trrController,
                            decoration: const InputDecoration(
                              labelText: 'Reverse Recovery Time (trr)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "4ns"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cjController,
                            decoration: const InputDecoration(
                              labelText: 'Junction Capacitance (Cj)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "2pF"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _diodeTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Diode Type',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "Switching", "Schottky"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _internalConfigController,
                            decoration: const InputDecoration(
                              labelText: 'Internal Config',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "Series", "Common Cathode", "Single"',
                            ),
                          ),
                        ],
                      ),

                    // Voltage Regulator-specific fields (only show when category_id === 10)
                    if (_categoryId == 10)
                      _buildSectionCard(
                        'Voltage Regulator Specifications (Optional)',
                        [
                          TextFormField(
                            controller: _vInMaxController,
                            decoration: const InputDecoration(
                              labelText: 'V_in(max)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "36V"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _vOutController,
                            decoration: const InputDecoration(
                              labelText: 'V_out',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "3.3V", "5V", "2.5V adjustable"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _iOutMaxController,
                            decoration: const InputDecoration(
                              labelText: 'I_out(max)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "1A", "500mA"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _accuracyController,
                            decoration: const InputDecoration(
                              labelText: 'Accuracy',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "±2%"',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _regTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Regulator Type',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., "Linear", "Switching", "Voltage Reference"',
                            ),
                          ),
                        ],
                      ),

                    // Additional Characteristics
                    _buildSectionCard(
                      'Additional Characteristics (JSON)',
                      [
                        TextFormField(
                          controller: _additionalCharsController,
                          decoration: const InputDecoration(
                            labelText: 'JSON',
                            border: OutlineInputBorder(),
                            hintText: '{"key": "value"}',
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                if (_additionalCharsController.text.trim().isNotEmpty) {
                                  try {
                                    final decoded = json.decode(_additionalCharsController.text);
                                    _additionalCharsController.text = const JsonEncoder.withIndent('  ').convert(decoded);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('JSON formatted')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invalid JSON')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.format_align_left),
                              label: const Text('Format JSON'),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _additionalCharsController.clear();
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Notes
                    _buildSectionCard(
                      'Notes',
                      [
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveComponent,
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
                                : Text(_isEditMode ? 'Update Component' : 'Save Component'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
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
}

