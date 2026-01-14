import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/component.dart';
import '../models/inventory.dart';
import '../models/chat.dart';
import '../models/category.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static const String tokenKey = 'auth_token';

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Save token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Remove token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // Get headers with auth
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }

  // Register
  Future<String> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: await getHeaders(includeAuth: false),
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        await saveToken(token);
        return token;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login
  Future<String> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        await saveToken(token);
        return token;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Get current user
  Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else {
        throw Exception('Failed to get user info');
      }
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  // Chat with agent
  Future<ChatResponse> chat(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: await getHeaders(),
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ChatResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Chat request failed');
      }
    } catch (e) {
      throw Exception('Chat failed: $e');
    }
  }

  // Create component
  Future<Component> createComponent(Map<String, dynamic> componentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/components'),
        headers: await getHeaders(),
        body: json.encode(componentData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Component.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Failed to create component');
      }
    } catch (e) {
      throw Exception('Failed to create component: $e');
    }
  }

  // List components
  Future<List<Component>> listComponents({
    String? statusFilter,
    int? categoryId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (statusFilter != null) queryParams['status_filter'] = statusFilter;
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();

      final uri = Uri.parse('$baseUrl/components').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(
        uri,
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.map((item) => Component.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else {
        throw Exception('Failed to list components');
      }
    } catch (e) {
      throw Exception('Failed to list components: $e');
    }
  }

  // Get component by ID
  Future<Component> getComponent(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/components/$id'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Component.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Component not found');
      } else {
        throw Exception('Failed to get component');
      }
    } catch (e) {
      throw Exception('Failed to get component: $e');
    }
  }

  // Update component
  Future<Component> updateComponent(int id, Map<String, dynamic> updates) async {
    print(json.encode(updates));
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/components/$id'),
        headers: await getHeaders(),
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Component.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Component not found');
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Failed to update component');
      }
    } catch (e) {
      throw Exception('Failed to update component: $e');
    }
  }

  // Delete component (soft delete)
  Future<void> deleteComponent(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/components/$id'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Component not found');
      } else {
        throw Exception('Failed to delete component');
      }
    } catch (e) {
      throw Exception('Failed to delete component: $e');
    }
  }

  // Get inventory cost
  Future<InventoryCostSummary> getInventoryCost({
    int? categoryId,
    String? statusFilter,
    bool? includeLowStock,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (statusFilter != null) queryParams['status_filter'] = statusFilter;
      if (includeLowStock != null) queryParams['include_low_stock'] = includeLowStock.toString();

      final uri = Uri.parse('$baseUrl/inventory/cost').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(
        uri,
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return InventoryCostSummary.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else {
        throw Exception('Failed to get inventory cost');
      }
    } catch (e) {
      throw Exception('Failed to get inventory cost: $e');
    }
  }

  // Add/Update inventory
  Future<InventoryItem> addOrUpdateInventory({
    required int componentId,
    required int quantity,
    required int minQty,
    String? location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventory'),
        headers: await getHeaders(),
        body: json.encode({
          'component_id': componentId,
          'quantity': quantity,
          'min_qty': minQty,
          'location': location,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return InventoryItem.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Component not found');
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Failed to add/update inventory');
      }
    } catch (e) {
      throw Exception('Failed to add/update inventory: $e');
    }
  }

  // List all inventory
  Future<List<InventoryItem>> listInventory({int? componentId}) async {
    try {
      final queryParams = <String, String>{};
      if (componentId != null) queryParams['component_id'] = componentId.toString();

      final uri = Uri.parse('$baseUrl/inventory').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(
        uri,
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.map((item) => InventoryItem.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else {
        throw Exception('Failed to list inventory');
      }
    } catch (e) {
      throw Exception('Failed to list inventory: $e');
    }
  }

  // Get inventory by component ID
  Future<InventoryItem> getInventoryByComponentId(int componentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inventory/$componentId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return InventoryItem.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Inventory not found for this component');
      } else {
        throw Exception('Failed to get inventory');
      }
    } catch (e) {
      throw Exception('Failed to get inventory: $e');
    }
  }

  // Update inventory
  Future<InventoryItem> updateInventory(
    int componentId, {
    int? quantity,
    int? minQty,
    String? location,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (quantity != null) body['quantity'] = quantity;
      if (minQty != null) body['min_qty'] = minQty;
      if (location != null) body['location'] = location;

      final response = await http.put(
        Uri.parse('$baseUrl/inventory/$componentId'),
        headers: await getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return InventoryItem.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Inventory not found');
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Failed to update inventory');
      }
    } catch (e) {
      throw Exception('Failed to update inventory: $e');
    }
  }

  // Adjust inventory quantity
  Future<InventoryItem> adjustInventory(int componentId, int adjustment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/$componentId/adjust').replace(
          queryParameters: {'adjustment': adjustment.toString()},
        ),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return InventoryItem.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Inventory not found');
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Failed to adjust inventory');
      }
    } catch (e) {
      throw Exception('Failed to adjust inventory: $e');
    }
  }

  // List categories
  Future<List<Category>> listCategories({String? statusFilter}) async {
    try {
      final queryParams = <String, String>{};
      if (statusFilter != null) queryParams['status_filter'] = statusFilter;

      final uri = Uri.parse('$baseUrl/categories').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(
        uri,
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else {
        throw Exception('Failed to list categories');
      }
    } catch (e) {
      throw Exception('Failed to list categories: $e');
    }
  }

  // Create category
  Future<Category> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: await getHeaders(),
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Category.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Failed to create category');
      }
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Get category by ID
  Future<Category> getCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Category.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        throw Exception('Failed to get category');
      }
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  // Update category
  Future<Category> updateCategory(
    int categoryId, {
    String? name,
    String? description,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (status != null) body['status'] = status;

      final response = await http.put(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: await getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Category.fromJson(data);
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['detail'] as String? ?? 'Failed to update category');
      }
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category (soft delete)
  Future<void> deleteCategory(int categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        await removeToken();
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}

