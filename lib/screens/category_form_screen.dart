import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'categories_list_screen.dart';

class CategoryFormScreen extends StatefulWidget {
  final int? categoryId;

  const CategoryFormScreen({super.key, this.categoryId});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _status = 'ACTIVE';
  bool _isLoading = false;
  bool _isEditMode = false;
  Category? _existingCategory;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.categoryId != null;
    if (_isEditMode) {
      _loadCategory();
    }
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

  Future<void> _loadCategory() async {
    if (widget.categoryId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final category = await _apiService.getCategory(widget.categoryId!);
      setState(() {
        _existingCategory = category;
        _nameController.text = category.name;
        _descriptionController.text = category.description ?? '';
        _status = category.status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading category: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Category category;
      if (_isEditMode) {
        category = await _apiService.updateCategory(
          widget.categoryId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          status: _status,
        );
      } else {
        category = await _apiService.createCategory(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(category);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category ${_isEditMode ? 'updated' : 'created'} successfully')),
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
          ? const LoadingIndicator(message: 'Loading category...')
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
                            _isEditMode ? 'Edit Category: ${_existingCategory?.name ?? ''}' : 'Create New Category',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name *',
                                border: OutlineInputBorder(),
                                hintText: 'Enter category name',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Category name is required';
                                }
                                if (value.length < 2) {
                                  return 'Category name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                hintText: 'Enter category description (optional)',
                              ),
                              maxLines: 3,
                            ),
                            if (_isEditMode) ...[
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
                          ],
                        ),
                      ),
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
                            onPressed: _isLoading ? null : _saveCategory,
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
                                : Text(_isEditMode ? 'Update Category' : 'Create Category'),
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
}


