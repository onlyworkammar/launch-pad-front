import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String type; // 'component' or 'confidence'

  const StatusBadge({
    super.key,
    required this.status,
    this.type = 'component',
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;

    if (type == 'confidence') {
      switch (status.toUpperCase()) {
        case 'HIGH':
          backgroundColor = Colors.green;
          break;
        case 'MEDIUM':
          backgroundColor = Colors.orange;
          break;
        case 'LOW':
          backgroundColor = Colors.red;
          break;
        default:
          backgroundColor = Colors.grey;
      }
    } else {
      switch (status.toUpperCase()) {
        case 'ACTIVE':
          backgroundColor = Colors.green;
          break;
        case 'INACTIVE':
          backgroundColor = Colors.grey;
          break;
        default:
          backgroundColor = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LowStockBadge extends StatelessWidget {
  final int quantity;
  final int minQty;

  const LowStockBadge({
    super.key,
    required this.quantity,
    required this.minQty,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = quantity < minQty;
    
    if (!isLowStock) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'LOW STOCK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

