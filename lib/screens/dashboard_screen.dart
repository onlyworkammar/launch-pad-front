import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/inventory.dart';
import '../models/component.dart';
import '../widgets/common_widgets.dart';
import '../widgets/top_navigation_bar.dart';
import 'chat_screen.dart';
import 'components_list_screen.dart';
import 'component_form_screen.dart';
import 'inventory_analysis_screen.dart';
import 'inventory_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  InventoryCostSummary? _inventorySummary;
  List<Component> _recentComponents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _apiService.getCurrentUser();
      setState(() {
        _userName = user.username;
      });
    } catch (e) {
      // Silently fail - user info is not critical for dashboard
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _apiService.getInventoryCost();
      final components = await _apiService.listComponents(statusFilter: 'ACTIVE');
      
      // Get recent components (last 5)
      final recentComponents = components.take(5).toList();

      setState(() {
        _inventorySummary = summary;
        _recentComponents = recentComponents;
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
      drawer: _buildDrawer(),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading dashboard...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadData,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Inventory Overview Card
                        if (_inventorySummary != null) _buildInventoryOverview(),
                        const SizedBox(height: 16),

                        // Low Stock and Quick Actions
                        Row(
                          children: [
                            Expanded(child: _buildLowStockCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildQuickActionsCard()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Recent Components
                        _buildRecentComponents(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF2563EB),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ALORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Component Intelligence',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat Agent'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Components'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComponentsListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Inventory Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InventoryListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Inventory Analysis'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InventoryAnalysisScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryOverview() {
    final summary = _inventorySummary!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Value', '\$${summary.totalValue.toStringAsFixed(2)}'),
                _buildStatItem('Components', summary.totalComponents.toString()),
                _buildStatItem('Quantity', summary.totalQuantity.toString()),
              ],
            ),
            if (summary.breakdownByCategory.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Breakdown by Category:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...summary.breakdownByCategory.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '• ${entry.key}: \$${entry.value.totalValue.toStringAsFixed(2)} (${entry.value.componentCount} components)',
                    ),
                  )),
            ],
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

  Widget _buildLowStockCard() {
    final lowStockItems = _inventorySummary?.lowStockItems ?? [];
    return Card(
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
            const SizedBox(height: 12),
            if (lowStockItems.isEmpty)
              const Text(
                'No low stock items',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              ...lowStockItems.take(3).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${item.partNumber}: ${item.quantity} units (Min: ${item.minQty})',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryAnalysisScreen(),
                    ),
                  );
                },
                child: const Text('View All →'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Agent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComponentFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Component'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryAnalysisScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Inventory'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentComponents() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Components',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_recentComponents.isEmpty)
              const Text(
                'No components found',
                style: TextStyle(color: Colors.grey),
              )
            else
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
                      TableCell(child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                      TableCell(child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                      TableCell(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  ..._recentComponents.map((component) => TableRow(
                        children: [
                          TableCell(child: Text(component.partNumber)),
                          TableCell(child: Text(component.categoryName ?? 'N/A')),
                          TableCell(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${component.quantity}'),
                                if (component.minQty != null && component.quantity < component.minQty!)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.warning, color: Colors.red, size: 16),
                                  ),
                              ],
                            ),
                          ),
                          TableCell(child: Text('\$${component.unitPrice.toStringAsFixed(2)}')),
                          TableCell(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ComponentsListScreen(),
                                  ),
                                );
                              },
                              child: const Text('View'),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ComponentsListScreen()),
                );
              },
              child: const Text('View All Components →'),
            ),
          ],
        ),
      ),
    );
  }
}

