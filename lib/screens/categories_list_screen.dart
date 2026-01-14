import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'category_form_screen.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final _apiService = ApiService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _apiService.listCategories(statusFilter: _statusFilter);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"?\n\nThis will set the category status to INACTIVE. Components using this category will still reference it.'),
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
        await _apiService.deleteCategory(id);
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted successfully')),
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
          ? const LoadingIndicator(message: 'Loading categories...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadCategories,
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
                            DropdownButtonFormField<String>(
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
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _loadCategories,
                                    child: const Text('Apply Filter'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _statusFilter = null;
                                      });
                                      _loadCategories();
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

                    // Categories list
                    Expanded(
                      child: _categories.isEmpty
                          ? const Center(
                              child: Text('No categories found'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      category.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (category.description != null)
                                          Text(category.description!),
                                        const SizedBox(height: 4),
                                        StatusBadge(status: category.status),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CategoryFormScreen(categoryId: category.id),
                                              ),
                                            ).then((_) => _loadCategories());
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteCategory(category.id, category.name),
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
            MaterialPageRoute(builder: (context) => const CategoryFormScreen()),
          ).then((_) => _loadCategories());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


